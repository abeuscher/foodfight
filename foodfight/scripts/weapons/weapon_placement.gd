extends Node

signal weapon_placed(player_id, weapon_data, position)
signal ingredients_updated(player_id, amount)

# References
var game_board
var weapon_types
var weapon_visualization

# Player resources
var player_resources = [30, 30]  # Starting resources for each player
var base_placement_complete = [false, false]  # Track if each player has placed their base

# Placement state
var current_player_id = 0
var selected_weapon = null
var placement_active = false
var is_base_placement_phase = false

func _ready():
	# Create weapon visualization if it doesn't exist
	weapon_visualization = get_node_or_null("WeaponVisualization")
	if weapon_visualization == null:
		print("Creating new WeaponVisualization node")
		weapon_visualization = Node.new()
		weapon_visualization.name = "WeaponVisualization"
		weapon_visualization.set_script(load("res://scripts/weapons/weapon_visualization.gd"))
		add_child(weapon_visualization)
	
	# Enable processing to update visualization
	set_process(true)

func _process(_delta):
	# Update visualization if mouse is moving during placement
	if placement_active and selected_weapon:
		var mouse_pos = get_viewport().get_mouse_position()
		update_placement_preview(mouse_pos)

func initialize(p_game_board, p_weapon_types):
	game_board = p_game_board
	weapon_types = p_weapon_types
	
	print("Weapon placement initialized with game_board:", game_board)
	
	# Initialize weapon visualization
	if weapon_visualization:
		if game_board and game_board.has_node("VisualManager"):
			var visual_manager = game_board.get_node("VisualManager")
			weapon_visualization.initialize(game_board, visual_manager)
			print("Weapon visualization initialized with game_board:", game_board)
		else:
			push_error("Missing VisualManager in game_board")
	else:
		push_error("Weapon visualization system missing")
	
	return true

# Start the base placement phase for a player
func start_base_placement_phase(player_id):
	print("Starting base placement phase for player", player_id + 1)
	current_player_id = player_id
	is_base_placement_phase = true
	placement_active = true
	
	# Reset base placement for new game if needed
	if player_id == 0:
		base_placement_complete = [false, false]
	
	# Don't consume resources for base placement
	emit_signal("ingredients_updated", player_id, player_resources[player_id])
	
	# Make sure weapon_types is initialized
	if weapon_types == null:
		print("ERROR: weapon_types is null, trying to retrieve from GameManager")
		if Engine.has_singleton("GameManager"):
			weapon_types = Engine.get_singleton("GameManager").weapon_types
			print("Retrieved weapon_types from GameManager:", "success" if weapon_types else "failed")
		else:
			print("ERROR: GameManager singleton not available")
			return
	
	# For base placement, automatically select the base weapon
	if weapon_types:
		var base_weapon = weapon_types.get_base_weapon()
		if base_weapon:
			print("Automatically selecting base weapon for player", player_id + 1)
			selected_weapon = base_weapon
			
			# Initialize preview
			if weapon_visualization:
				weapon_visualization.update_preview_size(base_weapon)
				print("Base preview initialized")
	else:
		print("ERROR: weapon_types still null, cannot get base weapon")

# Start the placement phase for a player
func start_placement_phase(player_id):
	current_player_id = player_id
	is_base_placement_phase = false
	placement_active = true
	
	# Reset resources only at the start of a new game
	if player_id == 0 and player_resources[0] <= 0 and player_resources[1] <= 0:
		player_resources[0] = 30
		player_resources[1] = 30
	
	# Signal resource amount to update UI
	emit_signal("ingredients_updated", player_id, player_resources[player_id])

# End the placement phase for the current player
func end_placement_phase():
	placement_active = false
	selected_weapon = null

# Handle input for weapon placement
func handle_input(event):
	if !placement_active:
		return
	
	if event is InputEventMouseMotion:
		update_placement_preview(event.global_position)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_base_placement_phase:
			attempt_base_placement(event.global_position)
		else:
			attempt_weapon_placement(event.global_position)

# Update the placement preview based on mouse position
func update_placement_preview(global_pos):
	if !placement_active or !selected_weapon:
		return
		
	# Ensure weapon visualization is initialized
	if !weapon_visualization:
		print("WARNING: No weapon visualization available for preview")
		# Try to create it
		_ready()
		return
	
	var cell = game_board.get_cell_at_position(global_pos)
	if cell:
		# Check if placement is valid
		var is_valid = can_place_at_position(selected_weapon, cell.position, current_player_id)
		
		# Debug info
		if is_base_placement_phase:
			print("Updating BASE preview at", cell.position, "valid:", is_valid)
		
		# Update the visual preview
		weapon_visualization.update_preview_size(selected_weapon)
		weapon_visualization.update_preview_position(cell.position, is_valid)
		weapon_visualization.show_preview(true)

# Try to place a weapon at the given position
func attempt_weapon_placement(global_pos):
	if !selected_weapon:
		return
	
	var cell = game_board.get_cell_at_position(global_pos)
	if !cell:
		return
	
	# Check if placement is valid
	if can_place_at_position(selected_weapon, cell.position, current_player_id):
		# Calculate weapon cost
		var cost = selected_weapon.cost
		
		# Check if player has enough resources
		if player_resources[current_player_id] >= cost:
			# Place the weapon
			place_weapon(selected_weapon, cell.position, current_player_id)
			
			# Deduct resources
			player_resources[current_player_id] -= cost
			emit_signal("ingredients_updated", current_player_id, player_resources[current_player_id])

# Try to place a base at the given position
func attempt_base_placement(global_pos):
	if base_placement_complete[current_player_id]:
		return
	
	# Make sure weapon_types is initialized
	if weapon_types == null:
		print("ERROR: weapon_types is null in attempt_base_placement")
		if Engine.has_singleton("GameManager"):
			weapon_types = Engine.get_singleton("GameManager").weapon_types
		if weapon_types == null:
			print("ERROR: Could not get weapon_types from GameManager")
			return
	
	# Get base weapon data
	var base_weapon = weapon_types.get_base_weapon()
	if base_weapon == null:
		print("ERROR: Could not get base weapon from weapon_types")
		return
	
	var cell = game_board.get_cell_at_position(global_pos)
	if !cell:
		return
	
	# Check if placement is valid
	if can_place_at_position(base_weapon, cell.position, current_player_id):
		# Place the base
		place_weapon(base_weapon, cell.position, current_player_id)
		
		# Mark base placement as complete for this player
		base_placement_complete[current_player_id] = true
		
		# Clear selected weapon
		selected_weapon = null
		
		# Update end placement button - use the correct approach with refactored UI
		var GameManager = Engine.get_singleton("GameManager")
		if GameManager:
			# Call through the state machine to handle UI updates properly
			GameManager.game_state_machine._on_base_placement_complete(current_player_id)
		else:
			push_error("GameManager singleton not available")

# Check if a weapon can be placed at the given position
func can_place_at_position(weapon, position, player_id):
	# Check for out of bounds
	if position.x < 0 or position.y < 0 or \
	   position.x + weapon.size.x > game_board.grid_size.x or \
	   position.y + weapon.size.y > game_board.grid_size.y:
		return false
	
	# Verify the weapon is being placed on the correct player's territory
	if !is_on_player_territory(position, weapon.size, player_id):
		return false
	
	# Check if all cells are unoccupied
	for x in range(weapon.size.x):
		for y in range(weapon.size.y):
			var check_pos = Vector2(position.x + x, position.y + y)
			
			# Check if cell exists
			if check_pos.x >= game_board.grid_size.x or check_pos.y >= game_board.grid_size.y:
				return false
			
			# Check if cell is land and unoccupied
			var check_cell = game_board.grid[int(check_pos.x)][int(check_pos.y)]
			if check_cell.terrain != game_board.TERRAIN.LAND or check_cell.occupied_by != null:
				return false
	
	return true

# Check if a position and size is on a player's territory
func is_on_player_territory(position, size, player_id):
	var island_margin = game_board.island_margin
	var island_size = game_board.island_size
	
	# Check if the entire weapon is on the player's territory
	for x in range(size.x):
		for y in range(size.y):
			var check_x = position.x + x
			var check_y = position.y + y
			
			# Player 1 (left island)
			if player_id == 0:
				if check_x < island_margin.x or \
				   check_x >= island_margin.x + island_size.x or \
				   check_y < island_margin.y or \
				   check_y >= island_margin.y + island_size.y:
					return false
			
			# Player 2 (right island)
			else:
				if check_x < game_board.grid_size.x - island_size.x - island_margin.x or \
				   check_x >= game_board.grid_size.x - island_margin.x or \
				   check_y < island_margin.y or \
				   check_y >= island_margin.y + island_size.y:
					return false
	
	return true

# Place a weapon on the game board
func place_weapon(weapon, position, player_id):
	# Handle case where weapon is an integer instead of a weapon object
	if typeof(weapon) == TYPE_INT:
		print("WARNING: Received integer weapon instead of weapon object. Converting...")
		# If we're in base placement phase, get the base weapon
		if is_base_placement_phase:
			weapon = weapon_types.get_base_weapon()
			print("Using base weapon for placement instead of integer value")
		# Otherwise try to get weapon by index
		elif weapon >= 0 and weapon < weapon_types.available_weapons.size():
			weapon = weapon_types.available_weapons[weapon]
		else:
			print("ERROR: Invalid weapon index: ", weapon)
			return
	
	# Handle case where position is a Dictionary instead of Vector2
	var pos_vector = position
	if typeof(position) == TYPE_DICTIONARY:
		print("WARNING: Received Dictionary position instead of Vector2. Converting...")
		if "x" in position and "y" in position:
			pos_vector = Vector2(position.x, position.y)
			print("Converted position dictionary to Vector2:", pos_vector)
		else:
			print("ERROR: Position dictionary missing x/y coordinates:", position)
			return
	
	# Check if placement position is within bounds
	if pos_vector.x < 0 or pos_vector.y < 0 or \
	   pos_vector.x + weapon.size.x > game_board.grid_size.x or \
	   pos_vector.y + weapon.size.y > game_board.grid_size.y:
		print("ERROR: Cannot place weapon at position " + str(pos_vector) + 
			  " with size " + str(weapon.size) + " - would be out of bounds")
		return
	
	# Mark cells as occupied by this weapon
	print("WEAPON:", weapon)
	for x in range(weapon.size.x):
		for y in range(weapon.size.y):
			var cell_pos = Vector2(pos_vector.x + x, pos_vector.y + y)
			
			# Double-check that we're within bounds before accessing the grid
			if cell_pos.x >= 0 and cell_pos.x < game_board.grid_size.x and \
			   cell_pos.y >= 0 and cell_pos.y < game_board.grid_size.y:
				var cell = game_board.grid[int(cell_pos.x)][int(cell_pos.y)]
				
				cell.occupied_by = {
					"weapon_data": weapon,
					"player_id": player_id,
					"root_position": pos_vector,  # Store the root cell position for reference
					"relative_position": Vector2(x, y)  # Store position relative to root cell
				}
			else:
				print("WARNING: Cell position out of bounds:", cell_pos)
	
	# Add visual representation
	game_board.visual_manager.create_weapon_sprite(weapon.id, pos_vector, player_id)
	
	# Signal that a weapon has been placed
	emit_signal("weapon_placed", player_id, weapon, pos_vector)
	
	# Clear the selected weapon if this was during regular placement
	if !is_base_placement_phase:
		selected_weapon = null

# Select a weapon for placement
func select_weapon_for_placement(weapon_id):
	if !placement_active:
		print("Weapon placement not active, ignoring selection")
		return
	
	print("Selecting weapon for placement: " + str(weapon_id) + " in phase: " + 
		  (("BASE" if is_base_placement_phase else "WEAPON")))
	
	# Make sure weapon_types is properly initialized
	if !weapon_types:
		print("ERROR: weapon_types not initialized in weapon_placement")
		if Engine.has_singleton("GameManager"):
			weapon_types = Engine.get_singleton("GameManager").weapon_types
		if !weapon_types:
			print("ERROR: Could not get weapon_types from GameManager")
			return
	
	# Handle integer weapon_id differently - it's likely a direct weapon reference, not an index
	if typeof(weapon_id) == TYPE_INT:
		print("WARNING: Received integer weapon_id, attempting direct weapon access")
		# First try to get base weapon during base placement phase
		if is_base_placement_phase:
			selected_weapon = weapon_types.get_base_weapon()
			if selected_weapon:
				print("Selected base weapon directly with size: ", selected_weapon.size)
				
				# Ensure preview is shown for the selected base weapon
				if weapon_visualization:
					weapon_visualization.update_preview_size(selected_weapon)
					weapon_visualization.show_preview(true)
					print("Base preview created and shown")
				else:
					print("ERROR: No weapon_visualization available")
				
				return
		
		# If not base placement or base not found, try to get by index
		if weapon_id >= 0 and weapon_id < weapon_types.available_weapons.size():
			selected_weapon = weapon_types.available_weapons[weapon_id]
			print("Selected weapon by direct index: ", selected_weapon.id)
		else:
			print("ERROR: Invalid weapon index: ", weapon_id)
		return
	
	# Normal string ID based lookup
	if is_base_placement_phase:
		# During base placement phase, only allow selecting the base weapon
		var base_weapon = weapon_types.get_base_weapon()
		if base_weapon and base_weapon.id == weapon_id:
			selected_weapon = base_weapon
			print("Base weapon selected for placement with size: ", base_weapon.size)
	else:
		# Regular weapon selection
		var weapon = weapon_types.get_weapon_by_id(weapon_id)
		if weapon:
			print("Selected weapon: ", weapon.id, " with size: ", weapon.size)
			selected_weapon = weapon
		else:
			print("Error: Could not find weapon with id: ", weapon_id)

# Get player ingredients
func get_player_resources(player_id):
	# Use player manager's ingredients
	var GameManager = Engine.get_singleton("GameManager")
	if GameManager and GameManager.player_manager:
		return GameManager.player_manager.get_player_ingredients(player_id)
	
	# Fallback to previous implementation
	if player_id < 0 or player_id >= player_resources.size():
		return 0
	return player_resources[player_id]

# Deduct ingredients when placing a weapon
func deduct_resources(player_id, cost):
	var GameManager = Engine.get_singleton("GameManager")
	if GameManager and GameManager.player_manager:
		# Directly modify ingredients in player_manager
		var current_ingredients = GameManager.player_manager.get_player_ingredients(player_id)
		var new_ingredients = current_ingredients - cost
		
		# Update player_manager ingredients
		if player_id == 0:
			GameManager.player_manager.player1_ingredients = new_ingredients
		else:
			GameManager.player_manager.player2_ingredients = new_ingredients
		
		# Emit signal for UI update
		if GameManager.game_state_machine:
			GameManager.game_state_machine._on_resource_updated(player_id, new_ingredients)
		
		return new_ingredients
	
	# Fallback to previous implementation
	var new_resources = player_resources[player_id] - cost
	player_resources[player_id] = new_resources
	return new_resources
