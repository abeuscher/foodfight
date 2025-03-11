extends Node

signal weapon_placed(player_id, weapon_data, position)
signal resource_updated(player_id, amount)

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

# Initialization flag
var is_initialized = false

func _ready():
	# Get reference to the weapon visualization system
	if has_node("WeaponVisualization"):
		weapon_visualization = get_node("WeaponVisualization")

func initialize(p_game_board, p_weapon_types):
	print("Initializing WeaponPlacement...")
	
	if !p_game_board or !p_weapon_types:
		push_error("WeaponPlacement: Missing required components")
		return false
	
	game_board = p_game_board
	weapon_types = p_weapon_types
	
	# Initialize weapon visualization
	if weapon_visualization:
		if game_board.has_node("VisualManager"):
			var visual_manager = game_board.get_node("VisualManager")
			weapon_visualization.initialize(game_board, visual_manager)
		else:
			print("Warning: VisualManager not found in game_board")
	
	is_initialized = true
	print("Weapon placement initialized")
	return true

# Start the base placement phase for a player
func start_base_placement_phase(player_id):
	if !is_initialized:
		return
	
	print("Starting base placement phase for Player ", player_id + 1)
	current_player_id = player_id
	is_base_placement_phase = true
	placement_active = true
	
	# Reset base placement for new game if needed
	if player_id == 0:
		base_placement_complete = [false, false]
	
	# Don't consume resources for base placement
	emit_signal("resource_updated", player_id, player_resources[player_id])

# Start the placement phase for a player
func start_placement_phase(player_id):
	if !is_initialized:
		return
	
	print("Starting placement phase for Player ", player_id + 1)
	current_player_id = player_id
	is_base_placement_phase = false
	placement_active = true
	
	# Reset resources only at the start of a new game
	if player_id == 0 and player_resources[0] <= 0 and player_resources[1] <= 0:
		player_resources[0] = 30
		player_resources[1] = 30
	
	# Signal resource amount to update UI
	emit_signal("resource_updated", player_id, player_resources[player_id])

# End the placement phase for the current player
func end_placement_phase():
	if !is_initialized or !placement_active:
		return
	
	print("Ending placement phase for Player ", current_player_id + 1)
	placement_active = false
	selected_weapon = null

# Handle input for weapon placement
func handle_input(event):
	if !is_initialized or !placement_active:
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
	if !is_initialized or !weapon_visualization:
		return
	
	if selected_weapon:
		# Already have a weapon selected, show placement preview
		var cell = game_board.get_cell_at_position(global_pos)
		if cell:
			# Check if placement is valid
			var is_valid = can_place_at_position(selected_weapon, cell.position, current_player_id)
			
			# Update the visual preview
			weapon_visualization.update_preview_size(selected_weapon)
			weapon_visualization.update_preview_position(cell.position, is_valid)
	else:
		# Clear any existing preview
		weapon_visualization.hide_preview()

# Try to place a weapon at the given position
func attempt_weapon_placement(global_pos):
	if !is_initialized or !selected_weapon:
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
			emit_signal("resource_updated", current_player_id, player_resources[current_player_id])
		else:
			print("Not enough resources to place this weapon")
	else:
		print("Cannot place weapon at this position")

# Try to place a base at the given position
func attempt_base_placement(global_pos):
	if !is_initialized or base_placement_complete[current_player_id]:
		return
	
	# Get base weapon data
	var base_weapon = weapon_types.get_base_weapon()
	if !base_weapon:
		print("Error: No base weapon type defined")
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
		
		# Signal GameStateMachine that this player's base placement is complete
		print("Base placement completed for Player ", current_player_id + 1)
		
		# Clear selected weapon
		selected_weapon = null
		
		# Update end placement button to "End Base Placement"
		if Engine.has_singleton("GameManager"):
			var GameManager = Engine.get_singleton("GameManager")
			if GameManager.game_ui_manager:
				if GameManager.game_ui_manager.end_placement_button:
					GameManager.game_ui_manager.end_placement_button.text = "End Base Placement"
		
		# Trigger callback to GameStateMachine
		if Engine.has_singleton("GameManager"):
			var GameManager = Engine.get_singleton("GameManager")
			if GameManager.game_state_machine:
				GameManager.game_state_machine._on_base_placement_complete(current_player_id)
	else:
		print("Cannot place base at this position")

# Check if a weapon can be placed at the given position
func can_place_at_position(weapon, position, player_id):
	if !is_initialized or !game_board:
		return false
	
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
	if !is_initialized or !game_board:
		return false
	
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
	if !is_initialized or !game_board:
		return
	
	# Mark cells as occupied by this weapon
	for x in range(weapon.size.x):
		for y in range(weapon.size.y):
			var cell_pos = Vector2(position.x + x, position.y + y)
			var cell = game_board.grid[int(cell_pos.x)][int(cell_pos.y)]
			
			cell.occupied_by = {
				"weapon_data": weapon,
				"player_id": player_id,
				"root_position": position,  # Store the root cell position for reference
				"relative_position": Vector2(x, y)  # Store position relative to root cell
			}
	
	print("Placed ", weapon.name, " at ", position, " for Player ", player_id + 1)
	
	# Add visual representation
	if game_board.visual_manager:
		game_board.visual_manager.create_weapon_sprite(weapon.id, position, player_id)
	
	# Signal that a weapon has been placed
	emit_signal("weapon_placed", player_id, weapon, position)
	
	# Clear the selected weapon if this was during regular placement
	if !is_base_placement_phase:
		selected_weapon = null

# Select a weapon for placement
func select_weapon_for_placement(weapon_id):
	if !is_initialized or !weapon_types or !placement_active:
		return
	
	if is_base_placement_phase:
		# During base placement phase, only allow selecting the base weapon
		var base_weapon = weapon_types.get_base_weapon()
		if base_weapon and base_weapon.id == weapon_id:
			selected_weapon = base_weapon
			print("Selected base for placement")
		else:
			print("Only base can be placed during base placement phase")
	else:
		# Regular weapon selection
		var weapon = weapon_types.get_weapon_by_id(weapon_id)
		if weapon:
			selected_weapon = weapon
			print("Selected weapon for placement: ", weapon.name)

# Get current player resources
func get_player_resources(player_id):
	if player_id < 0 or player_id >= player_resources.size():
		return 0
	return player_resources[player_id]
