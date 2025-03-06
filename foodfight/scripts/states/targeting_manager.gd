extends Node

signal target_selected(weapon, target_position)

# References
var game_board
var weapon_manager

# State variables
var selected_weapon = null
var targeting_active = false
var target_position = null
var valid_targets = []

# Visual indicator
var range_indicator

# Initialization flag
var is_initialized = false

func _ready():
	await get_tree().process_frame
	
	# Get dependency
	if get_parent() and get_parent().has_node("WeaponManager"):
		weapon_manager = get_parent().get_node("WeaponManager")
	else:
		print("Error: WeaponManager not found")
	
	# Create range indicator
	range_indicator = RangeIndicatorNode.new()
	range_indicator.name = "RangeIndicator"
	add_child(range_indicator)
	range_indicator.visible = false

func initialize(p_game_board):
	if !p_game_board:
		print("Error: No game board provided to TargetingManager")
		return
	
	game_board = p_game_board
	
	if !weapon_manager:
		print("Error: WeaponManager not available")
		return
		
	is_initialized = true
	print("Targeting manager initialized")

# Handle input for targeting
func handle_input(event):
	if !is_initialized or not targeting_active:
		return
		
	# Handle clicking on the game board to select a target
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_cell = game_board.get_cell_at_position(event.global_position)
		if clicked_cell and is_valid_target(clicked_cell):
			target_position = clicked_cell.position
			# Confirm the target
			confirm_target()

# Activate targeting mode
func activate_targeting():
	if !is_initialized:
		return
		
	targeting_active = true

# Deactivate targeting mode
func deactivate_targeting():
	if !is_initialized:
		return
		
	targeting_active = false
	clear_targeting_visuals()

# Select a weapon to attack with
func select_weapon(weapon, player_id):
	if !is_initialized:
		return
		
	selected_weapon = weapon
	
	# Clear any previous targeting visuals
	clear_targeting_visuals()
	
	# Show attack range for selected weapon
	valid_targets = get_valid_targets(weapon, player_id)
	show_range_indicator(weapon, valid_targets)

# Get target for weapon (for automated attacks)
func get_target_for_weapon(weapon, player_id):
	if !is_initialized or !weapon_manager:
		return null
		
	var enemy_player_id = 1 - player_id
	var potential_targets = []
	
	for target_weapon in weapon_manager.get_player_weapons(enemy_player_id):
		var distance = calculate_distance(weapon.position, target_weapon.position)
		if distance <= weapon.data.attack_range:
			potential_targets.append(target_weapon)
	
	# If no targets in range, return null
	if potential_targets.size() == 0:
		return null
	
	# For now, just pick the first valid target
	# In the future, you could implement strategic target selection
	return potential_targets[0]

# Calculate distance between two grid positions
func calculate_distance(pos1, pos2):
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

# Get all valid targets for a weapon
func get_valid_targets(weapon, player_id):
	if !is_initialized:
		return []
		
	var targets = []
	var enemy_player_id = 1 - player_id
	
	# Scan grid for cells in range and on enemy territory
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			
			# Calculate if within range
			var distance = calculate_distance(weapon.position, cell.position)
			if distance <= weapon.data.attack_range:
				# Check if it's enemy territory or has an enemy weapon
				var is_enemy_territory = (
					enemy_player_id == 0 and x < game_board.grid_size.x / 2 or
					enemy_player_id == 1 and x >= game_board.grid_size.x / 2
				)
				
				if is_enemy_territory:
					targets.append(cell)
	
	return targets

# Check if a cell is a valid target
func is_valid_target(cell):
	if !is_initialized:
		return false
		
	for valid_cell in valid_targets:
		if valid_cell.position == cell.position:
			return true
	return false

# Show the range indicator for targeting
func show_range_indicator(weapon, valid_targets):
	if !is_initialized or !range_indicator:
		return
		
	range_indicator.set_data(weapon, valid_targets, game_board)
	range_indicator.visible = true

# Clear targeting visuals
func clear_targeting_visuals():
	if !is_initialized:
		return
		
	if range_indicator:
		range_indicator.visible = false
	target_position = null

# Confirm the selected target
func confirm_target():
	if !is_initialized or not selected_weapon or not target_position:
		return
	
	print("Target confirmed at ", target_position)
	
	# Emit signal that target has been selected
	emit_signal("target_selected", selected_weapon, target_position)
	
	# Reset targeting state
	clear_targeting_visuals()
	targeting_active = false
	selected_weapon = null

# Custom Node2D subclass for range indicator
class RangeIndicatorNode extends Node2D:
	var weapon = null
	var valid_targets = []
	var board = null
	
	func set_data(p_weapon, p_valid_targets, p_board):
		weapon = p_weapon
		valid_targets = p_valid_targets
		board = p_board
		queue_redraw()
	
	func _draw():
		if not weapon or not board:
			return
			
		for target in valid_targets:
			var world_pos = board.grid_to_world(target.position)
			var rect = Rect2(world_pos, board.cell_size)
			
			# Draw green highlight for valid targets
			draw_rect(rect, Color(0, 1, 0, 0.3))
			draw_rect(rect, Color(0, 1, 0, 0.8), false)
