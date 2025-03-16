extends Node

# References
var game_board
var visual_manager

# Weapon tracking
var player_weapons = [[], []]  # Stores active weapons for each player
var default_health = 10  # Default health for weapons

func initialize(p_game_board):
	game_board = p_game_board
	visual_manager = game_board.get_node("VisualManager")

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
						# Get weapon health from weapon data if available
						var health = default_health
						
						if "health" in weapon_entry.weapon_data:
							health = weapon_entry.weapon_data.health
						else:
							# Check if the weapon is a base - bases have higher health
							var is_base = weapon_entry.weapon_data.type == "base"
							if is_base:
								health = 100
						
						player_weapons[weapon_entry.player_id].append({
							"data": weapon_entry.weapon_data,
							"position": cell.position,
							"current_cooldown": 0,
							"health": health,
							"max_health": health,
							"player_id": weapon_entry.player_id  # Save player ID for reference
						})
	
	return player_weapons

# Reset all weapon cooldowns to 0
func reset_weapon_cooldowns():
	for player_idx in range(2):
		for weapon in player_weapons[player_idx]:
			weapon.current_cooldown = 0

# Get weapons for a specific player
func get_player_weapons(player_id, filter_type=null):
	if filter_type == null:
		return player_weapons[player_id]
	
	var filtered_weapons = []
	for weapon in player_weapons[player_id]:
		var weapon_type = weapon.data.type
		
		# Add weapon if it matches the filter
		if filter_type == "offensive":
			if weapon_type == "offensive" or (weapon_type != "base" and weapon.data.attack_range > 0):
				filtered_weapons.append(weapon)
		elif filter_type == "!base":
			if weapon_type != "base":
				filtered_weapons.append(weapon)
		elif filter_type == weapon_type:
			filtered_weapons.append(weapon)
	
	return filtered_weapons

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
	# Find the weapon in the grid and remove it
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			if cell.occupied_by and "root_position" in cell.occupied_by and cell.occupied_by.root_position == weapon.position:
				# Create instance ID to find the health bar
				var weapon_id = weapon.data.id
				var instance_id = str(weapon.player_id) + "_" + str(weapon_id) + "_" + str(weapon.position.x) + "_" + str(weapon.position.y)
				
				# Remove health bar
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
	visual_manager.update_weapon_sprites()

# Update health display for a weapon
func update_weapon_health_display(weapon):
	# Create instance ID to find the health bar
	var weapon_id = weapon.data.id
	var instance_id = str(weapon.player_id) + "_" + str(weapon_id) + "_" + str(weapon.position.x) + "_" + str(weapon.position.y)
	
	# Update health bar
	visual_manager.update_health_bar(instance_id, weapon.health)

# Get defensive bonus for a position
func get_defensive_bonus(position, player_id):
	var bonus = 0
	var defense_radius = 2  # How far defensive structures protect
	
	for weapon in get_player_weapons(player_id):
		# Skip weapons that aren't defensive
		if weapon.data.type != "defensive":
			continue
		
		# Calculate distance to the defensive structure
		var distance = abs(weapon.position.x - position.x) + abs(weapon.position.y - position.y)
		if distance <= defense_radius:
			# Get defense bonus from the defensive structure
			var defense_value = 1  # Default defense value
			if "defense_bonus" in weapon.data:
				defense_value = weapon.data.defense_bonus
			
			# More bonus for closer structures
			bonus += defense_value * (defense_radius - distance + 1) / defense_radius
	
	return bonus
