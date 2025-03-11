extends Node

# References
var game_board
var visual_manager

# Weapon tracking
var player_weapons = [[], []]  # Stores active weapons for each player
var default_health = 10  # Default health for weapons

func initialize(p_game_board):
	game_board = p_game_board
	
	if game_board.has_node("VisualManager"):
		visual_manager = game_board.get_node("VisualManager")
	
	print("Weapon manager initialized")

# Collect all weapons placed on the board
func collect_weapons():
	player_weapons = [[], []]
	
	# Scan the grid to find all placed weapons
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			if cell.occupied_by and "weapon_data" in cell.occupied_by:
				var weapon_entry = cell.occupied_by
				# Only add the root cell of a weapon (to avoid duplicates)
				if weapon_entry.root_position == cell.position:
					if "player_id" in weapon_entry:
						# Set health based on weapon type
						var health = default_health
						
						# Check if the weapon is a base by examining the id
						var is_base = false
						if weapon_entry.weapon_data is Object:
							# Try to check for a type property or method
							if weapon_entry.weapon_data.has_method("get_type"):
								is_base = weapon_entry.weapon_data.get_type() == "base"
							elif weapon_entry.weapon_data.has_method("get_id"):
								var id = str(weapon_entry.weapon_data.get_id()).to_lower()
								is_base = id.contains("base")
							# Fall back to checking the id property
							elif "id" in weapon_entry.weapon_data:
								var id = str(weapon_entry.weapon_data.id).to_lower()
								is_base = id.contains("base")
						elif "type" in weapon_entry.weapon_data:
							is_base = weapon_entry.weapon_data.type == "base"
						
						# Bases have much higher health
						if is_base:
							health = default_health * 10  # Increased from 2x to 10x
						
						player_weapons[weapon_entry.player_id].append({
							"data": weapon_entry.weapon_data,
							"position": cell.position,
							"current_cooldown": 0,
							"health": health,
							"max_health": health,
							"player_id": weapon_entry.player_id  # Save player ID for reference
						})
	
	print("Weapons collected - Player 1: ", player_weapons[0].size(), ", Player 2: ", player_weapons[1].size())
	return player_weapons

# Reset all weapon cooldowns to 0
func reset_weapon_cooldowns():
	for player_idx in range(2):
		for weapon in player_weapons[player_idx]:
			weapon.current_cooldown = 0

# Get weapons for a specific player
func get_player_weapons(player_id):
	return player_weapons[player_id]

# Get all weapons
func get_all_weapons():
	return player_weapons[0] + player_weapons[1]

# Get weapon at specific position
func get_weapon_at_position(position, player_id = -1):
	if player_id >= 0:
		# Look only in specific player's weapons
		for weapon in player_weapons[player_id]:
			if weapon.position == position:
				return weapon
	else:
		# Look in all players' weapons
		for p_id in range(player_weapons.size()):
			for weapon in player_weapons[p_id]:
				if weapon.position == position:
					return weapon
	return null

# Remove a weapon from the board
func remove_weapon_from_board(weapon):
	print("Removing weapon from board: ", weapon.data.name, " at position ", weapon.position)
	
	# Find the weapon in the grid and remove it
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			if cell.occupied_by and "root_position" in cell.occupied_by and cell.occupied_by.root_position == weapon.position:
				# Create instance ID to find the health bar
				var weapon_id
				
				# Handle different ways to get the weapon ID
				if weapon.data is Object:
					if weapon.data.has_method("get_id"):
						weapon_id = weapon.data.get_id()
					elif "id" in weapon.data:
						weapon_id = weapon.data.id
				else:
					# Fallback
					weapon_id = "unknown"
					
				var instance_id = str(weapon.player_id) + "_" + str(weapon_id) + "_" + str(weapon.position.x) + "_" + str(weapon.position.y)
				
				# Remove health bar first if visual manager is available
				if visual_manager:
					visual_manager.remove_health_bar(instance_id)
				
				# Clear cell
				cell.occupied_by = null
	
	# Remove from player_weapons array
	for player_idx in range(2):
		var idx = 0
		while idx < player_weapons[player_idx].size():
			if player_weapons[player_idx][idx].position == weapon.position:
				player_weapons[player_idx].remove_at(idx)
			else:
				idx += 1
	
	# Update visuals
	if visual_manager:
		visual_manager.update_weapon_sprites()

# Update health display for a weapon
func update_weapon_health_display(weapon):
	if !visual_manager:
		return
	
	# Create instance ID to find the health bar
	var weapon_id
	
	# Handle different ways to get the weapon ID
	if weapon.data is Object:
		if weapon.data.has_method("get_id"):
			weapon_id = weapon.data.get_id()
		elif "id" in weapon.data:
			weapon_id = weapon.data.id
	else:
		# Fallback
		weapon_id = "unknown"
		
	var instance_id = str(weapon.player_id) + "_" + str(weapon_id) + "_" + str(weapon.position.x) + "_" + str(weapon.position.y)
	
	# Update health bar
	visual_manager.update_health_bar(instance_id, weapon.health)