extends Node

# References
var game_board
var visual_manager
var preview_rect = null

# Initialization flag
var is_initialized = false
var default_cell_size = Vector2(32, 32) # Fallback cell size if game_board is null

# Preview state tracking
var current_grid_position = null
var current_valid_state = false
var preview_creation_count = 0 # Track how many times we're creating previews for debugging

# Add this property
var show_placement_preview = true
var current_preview = null

func _ready():
	# Set up a timer to check periodically if we need to create the preview
	# This helps with ensuring preview is created even if initialization was incomplete
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = false
	timer.timeout.connect(_check_preview_needed)
	add_child(timer)
	timer.start()

func _process(delta):
	# Update preview position on mouse move
	if show_placement_preview and is_placement_active():
		update_placement_preview()

func initialize(p_game_board, p_visual_manager):
	print("Initializing weapon visualization with game_board:", p_game_board)
	game_board = p_game_board
	visual_manager = p_visual_manager
	is_initialized = true
	print("Weapon visualization successfully initialized")
	return self

# Check if we need to create the preview
func _check_preview_needed():
	var weapon_placement = get_parent()
	if weapon_placement and weapon_placement.selected_weapon and !preview_rect:
		print("Auto-creating preview for selected weapon")
		update_preview_size(weapon_placement.selected_weapon)

# Try to find the game board if missing
func _ensure_game_board():
	if game_board:
		return true
		
	print("Trying to find game_board...")
	
	# Try getting from parent
	var parent = get_parent()
	if parent and "game_board" in parent:
		game_board = parent.game_board
		print("Found game_board in parent")
		return true
	
	# Try getting from GameManager
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if "game_board" in GameManager:
			game_board = GameManager.game_board
			print("Found game_board in GameManager")
			return true
	
	# Try searching in scene tree
	var root = get_tree().get_root()
	var main_scene = root.get_node_or_null("Main")
	if main_scene:
		var potential_board = main_scene.get_node_or_null("GameBoard")
		if potential_board:
			game_board = potential_board
			print("Found game_board in Main scene")
			return true
	
	print("ERROR: Failed to find game_board reference")
	return false

# Get cell size safely
func _get_cell_size():
	if game_board and "cell_size" in game_board:
		return game_board.cell_size
	return default_cell_size # Fallback

# Update the size of the preview based on weapon data
func update_preview_size(weapon_data):
	# Skip excessive recreation if nothing changed
	if preview_rect and is_instance_valid(preview_rect):
		var cell_size = _get_cell_size()
		var expected_size = Vector2(
			weapon_data.size.x * cell_size.x,
			weapon_data.size.y * cell_size.y
		)
		if preview_rect.size == expected_size:
			return
	
	# Track creation count for debugging
	preview_creation_count += 1
	
	# Extra debug info
	print("Creating preview for weapon, size:", weapon_data.size)
	
	# Make sure we have a game board reference
	if !is_initialized:
		print("ERROR: Weapon visualization not initialized")
		_ensure_game_board()
	
	# Remove existing preview if any
	if preview_rect and is_instance_valid(preview_rect):
		preview_rect.queue_free()
		preview_rect = null
	
	# Get cell size safely
	var cell_size = _get_cell_size()
	
	# Create new preview rectangle
	preview_rect = ColorRect.new()
	preview_rect.size = Vector2(
		weapon_data.size.x * cell_size.x,
		weapon_data.size.y * cell_size.y
	)
	preview_rect.modulate.a = 0.5 # 50% transparency
	preview_rect.color = Color(0, 1, 0, 0.3) # Default to green
	
	# Add to scene tree (try game_board first, then fallback to parent)
	var added_to_scene = false
	if game_board:
		game_board.add_child(preview_rect)
		added_to_scene = true
		print("Added preview rect to game_board")
	elif get_parent():
		get_parent().add_child(preview_rect)
		added_to_scene = true
		print("Added preview rect to parent node")
	
	if added_to_scene:
		# Make it visible by default
		preview_rect.z_index = 100 # Make sure it's on top of everything
		preview_rect.visible = true
		print("Preview created and is visible")
	else:
		print("ERROR: Could not add preview to scene tree")

# Update the position and color of the preview based on validity
func update_preview_position(grid_position, is_valid):
	# Skip update if position and validity haven't changed
	if current_grid_position == grid_position and current_valid_state == is_valid and preview_rect and is_instance_valid(preview_rect) and preview_rect.visible:
		return
	
	# Update state tracking
	current_grid_position = grid_position
	current_valid_state = is_valid
	
	if !preview_rect:
		print("Warning: Trying to update position but no preview exists, creating...")
		var weapon_placement = get_parent()
		if weapon_placement and weapon_placement.selected_weapon:
			update_preview_size(weapon_placement.selected_weapon)
		else:
			return
	
	# Make sure we have a game board reference
	if !game_board and !_ensure_game_board():
		print("ERROR: No game_board to calculate position")
		return
	
	# Get cell size safely
	var cell_size = _get_cell_size()
	
	# Convert grid position to world position
	var world_pos = Vector2(
		grid_position.x * cell_size.x,
		grid_position.y * cell_size.y
	)
	
	# Update position
	preview_rect.position = world_pos
	preview_rect.visible = true # Ensure visibility
	
	# Update color based on validity
	if is_valid:
		preview_rect.color = Color(0, 1, 0, 0.3) # Green for valid
	else:
		preview_rect.color = Color(1, 0, 0, 0.3) # Red for invalid

# Show or hide the preview
func show_preview(visible):
	if preview_rect:
		preview_rect.visible = visible
	else:
		# Try to create it if we have a selected weapon
		var weapon_placement = get_parent()
		if weapon_placement and weapon_placement.selected_weapon:
			update_preview_size(weapon_placement.selected_weapon)
			if preview_rect:
				preview_rect.visible = visible

# Clean up when placement is done
func clear_preview():
	if preview_rect and is_instance_valid(preview_rect):
		preview_rect.queue_free()
		preview_rect = null
		print("Preview cleared")
	
	# Reset position tracking
	current_grid_position = null
	current_valid_state = false

# Create a weapon sprite on the board
func place_weapon_visual(weapon_data, grid_position, player_id):
	if visual_manager:
		return visual_manager.create_weapon_sprite(weapon_data.id, grid_position, player_id)
	else:
		print("ERROR: No visual_manager to create weapon sprite")
		return null
	
# A single, simple update_placement_preview function
func update_placement_preview(params = null):
	var parent = get_parent()
	if !parent:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	if params is Vector2:
		mouse_pos = params
	
	# Get grid position from mouse
	var grid_pos = null
	var cell = parent.game_board.get_cell_at_position(mouse_pos)
	if cell:
		grid_pos = cell.position
	else:
		return
	
	# Get weapon data
	var weapon_data = null
	if parent.is_base_placement_phase:
		weapon_data = parent.weapon_types.get_weapon_by_type("base")
	else:
		weapon_data = parent.selected_weapon
		
	if !weapon_data:
		return
		
	# Check placement validity
	var is_valid = parent.can_place_at_position(weapon_data, grid_pos, parent.current_player_id)
	
	# Update preview
	update_preview_size(weapon_data)
	update_preview_position(grid_pos, is_valid)

# Clear the placement preview
func clear_placement_preview():
	clear_preview()

# Helper to check if placement is active
func is_placement_active():
	return get_parent().placement_active

# Helper to get current weapon data
func get_current_weapon_data():
	var parent = get_parent()
	
	if parent.is_base_placement_phase:
		# In base placement, get base weapon data
		return parent.weapon_types.get_weapon_by_type("base")
	elif parent.selected_weapon_id:
		# In weapon placement, get selected weapon
		return parent.weapon_types.get_weapon_by_id(parent.selected_weapon_id)
	
	return null
