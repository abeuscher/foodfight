extends Node

# References
var game_board
var visual_manager

# Weapon tracking
var player_weapons = [[], []]  # Stores active weapons for each player

# Initialization flag
var is_initialized = false

func initialize(p_game_board):
	if !p_game_board:
		print("Error: No game board provided to WeaponManager")
		return
		
	game_board = p_game_board
	
	if game_board.has_node("VisualManager"):
		visual_manager = game_board.get_node("VisualManager")
	
	is_initialized = true
	print("Weapon manager initialized")

# Collect all weapons placed on the board
func collect_weapons():
	if !is_initialized:
		print("Error: Cannot collect weapons - not initialized")
		return []
		
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
						player_weapons[weapon_entry.player_id].append({
							"data": weapon_entry.weapon_data,
							"position": cell.position,
							"current_cooldown": 0,
							"health": 10,  # Assuming default health
							"player_id": weapon_entry.player_id  # Save player ID for reference
						})
	
	print("Weapons collected - Player 1: ", player_weapons[0].size(), ", Player 2: ", player_weapons[1].size())
	return player_weapons

# Reset all weapon cooldowns to 0
func reset_weapon_cooldowns():
	if !is_initialized:
		return
		
	for player_idx in range(2):
		for weapon in player_weapons[player_idx]:
			weapon.current_cooldown = 0

# Get weapons for a specific player
func get_player_weapons(player_id):
	if !is_initialized or player_id < 0 or player_id >= player_weapons.size():
		return []
	return player_weapons[player_id]

# Get all weapons
func get_all_weapons():
	if !is_initialized:
		return []
	return player_weapons[0] + player_weapons[1]

# Get weapon at specific position
func get_weapon_at_position(position, player_id = -1):
	if !is_initialized:
		return null
		
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
	if !is_initialized or !weapon:
		return
		
	# Find the weapon in the grid and remove it
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			if cell.occupied_by and "root_position" in cell.occupied_by and cell.occupied_by.root_position == weapon.position:
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