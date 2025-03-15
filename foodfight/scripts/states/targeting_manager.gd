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
var hover_cell = null

func _ready():
	print("TargetingManager: Ready")
	
	# Get weapon manager reference
	weapon_manager = get_parent().get_node("WeaponManager")
	print("TargetingManager: Found WeaponManager reference")

func initialize(p_game_board):
	print("Initializing TargetingManager...")
	
	game_board = p_game_board
	print("TargetingManager: Game board set")
	
	print("Targeting manager initialized")
	return true

# Handle input for targeting
func handle_input(event):
	if !targeting_active or !selected_weapon:
		return
	
	# Handle mouse movement for hover effect
	if event is InputEventMouseMotion:
		update_hover_position(event.global_position)
	
	# Handle clicking on the game board to select a target
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("TargetingManager: Mouse click detected at ", event.global_position)
		var clicked_cell = game_board.get_cell_at_position(event.global_position)
		if clicked_cell:
			print("TargetingManager: Cell found at ", clicked_cell.position)
			if is_valid_target(clicked_cell):
				print("TargetingManager: Valid target cell selected")
				target_position = clicked_cell.position
				
				# Highlight the selected cell
				game_board.set_cell_visual_state(clicked_cell.position, game_board.VISUAL_STATE.SELECTED)
				
				confirm_target()
			else:
				print("TargetingManager: Cell is not a valid target")

# Update hover effect based on mouse position
func update_hover_position(global_pos):
	if !targeting_active:
		return
		
	var cell = game_board.get_cell_at_position(global_pos)
	if cell:
		# Only update if we're hovering over a different cell
		if hover_cell != cell:
			hover_cell = cell
			
			# Reset previous hover effects
			game_board.reset_hover_effects()
			
			# Set hover effect based on whether it's a valid target
			if is_valid_target(cell):
				game_board.set_cell_visual_state(cell.position, game_board.VISUAL_STATE.HOVER_VALID)
			else:
				game_board.set_cell_visual_state(cell.position, game_board.VISUAL_STATE.HOVER_INVALID)
	else:
		# If mouse is not over any cell, clear the hover effect
		if hover_cell:
			hover_cell = null
			game_board.reset_hover_effects()

# Activate targeting mode
func activate_targeting():
	targeting_active = true
	hover_cell = null
	print("TargetingManager: Targeting mode activated")

# Deactivate targeting mode
func deactivate_targeting():
	targeting_active = false
	clear_targeting_visuals()
	print("TargetingManager: Targeting mode deactivated")

# Select a weapon to attack with
func select_weapon(weapon, player_id):
	print("TargetingManager: Weapon selected: ", weapon.data.name, " for Player ", player_id + 1)
	selected_weapon = weapon
	
	# Clear any previous targeting visuals
	clear_targeting_visuals()
	
	# Get valid targets for this weapon
	valid_targets = get_valid_targets(weapon, player_id)
	print("TargetingManager: Found ", valid_targets.size(), " valid targets")
	
	# Don't highlight valid targets by default, only on hover
	# Let the hover effect handle showing what's valid or not

# Get target for weapon (for automated attacks)
func get_target_for_weapon(weapon, player_id):
	var enemy_player_id = 1 - player_id
	var potential_targets = []
	
	for target_weapon in weapon_manager.get_player_weapons(enemy_player_id):
		var distance = calculate_distance(weapon.position, target_weapon.position)
		if distance <= weapon.data.attack_range:
			potential_targets.append(target_weapon)
	
	# Return first valid target or null if none
	return potential_targets[0] if potential_targets.size() > 0 else null

# Calculate distance between two grid positions
func calculate_distance(pos1, pos2):
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

# Get all valid targets for a weapon
func get_valid_targets(weapon, player_id):
	var targets = []
	var enemy_player_id = 1 - player_id
	print("TargetingManager: Calculating valid targets for Player ", player_id + 1, " against Player ", enemy_player_id + 1)
	
	# Get island dimensions
	var island_size = game_board.island_size
	var island_margin = game_board.island_margin
	
	# Scan grid for cells in range and on enemy territory
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			
			# Check if it's enemy territory and land
			var is_enemy_territory = false
			var is_land = false
			
			# Always use cell_manager if available for accurate targeting
			if game_board.cell_manager:
				is_enemy_territory = game_board.cell_manager.is_player_territory(cell.position, enemy_player_id)
				is_land = game_board.cell_manager.is_land_cell(cell.position)
			else:
				# Fallback with direct grid checks if cell_manager isn't available
				
				# Check for left island (player 0's territory)
				if enemy_player_id == 0:
					is_enemy_territory = (
						x >= island_margin.x and 
						x < island_margin.x + island_size.x and
						y >= island_margin.y and 
						y < island_margin.y + island_size.y
					)
				
				# Check for right island (player 1's territory)
				else:
					is_enemy_territory = (
						x >= game_board.grid_size.x - island_size.x - island_margin.x and
						x < game_board.grid_size.x - island_margin.x and
						y >= island_margin.y and
						y < island_margin.y + island_size.y
					)
				
				is_land = cell.terrain == game_board.TERRAIN.LAND
			
			# Only add if it's enemy territory and land
			if is_enemy_territory and is_land:
				targets.append(cell.position)
	
	print("TargetingManager: Found ", targets.size(), " valid target cells")
	return targets

# Check if a cell is a valid target
func is_valid_target(cell):
	if !cell:
		return false
	
	for valid_pos in valid_targets:
		if valid_pos == cell.position:
			return true
	return false

# Check if a target is in range of a weapon at a specific position
func is_in_range(weapon_position, target_position, weapon_data):
	# Calculate distance between weapon and target
	var distance = calculate_distance(weapon_position, target_position)
	
	# Check if target is within weapon's attack range
	if "attack_range" in weapon_data and distance <= weapon_data.attack_range:
		# For valid targeting in AI, also check if the target is on enemy territory
		var cell = game_board.grid[target_position.x][target_position.y] if target_position.x < game_board.grid_size.x and target_position.y < game_board.grid_size.y else null
		
		if cell:
			# Get the enemy player ID (whoever owns the weapon)
			var weapon_player_id = -1
			if "player_id" in weapon_data:
				weapon_player_id = weapon_data.player_id
			
			# If we don't know the player ID, calculate it based on position
			if weapon_player_id == -1:
				# Assume player 0 is on the left side, player 1 on the right
				weapon_player_id = 0 if weapon_position.x < game_board.grid_size.x / 2 else 1
			
			# Target is valid if it's on the enemy's side
			var enemy_player_id = 1 - weapon_player_id
			
			# Use cell_manager if available
			if game_board.cell_manager:
				return game_board.cell_manager.is_player_territory(target_position, enemy_player_id) and distance <= weapon_data.attack_range
			
			# Fallback to simple territory check
			var is_enemy_territory = false
			
			# Quick check based on board position
			if enemy_player_id == 0:
				# Left side
				is_enemy_territory = target_position.x < game_board.grid_size.x / 2
			else:
				# Right side
				is_enemy_territory = target_position.x >= game_board.grid_size.x / 2
				
			return is_enemy_territory and distance <= weapon_data.attack_range
	
	return false

# Clear targeting visuals
func clear_targeting_visuals():
	hover_cell = null
	
	# Reset visual states on the game board
	game_board.reset_all_visual_states()

# Confirm the selected target
func confirm_target():
	if !selected_weapon or !target_position:
		return
	
	print("TargetingManager: Target confirmed at ", target_position)
	
	# Emit signal that target has been selected
	emit_signal("target_selected", selected_weapon, target_position)
	
	# Reset targeting state
	clear_targeting_visuals()
	targeting_active = false