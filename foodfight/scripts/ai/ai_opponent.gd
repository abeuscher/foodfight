extends Node

class_name AIOpponent

# Signals
signal thinking_started
signal thinking_completed
signal action_taken(action_type)

# Difficulty levels
enum Difficulty {EASY, MEDIUM, HARD}

# AI states
enum AIState {IDLE, THINKING, ACTING}

# References to game components
var game_board
var weapon_types
var weapon_placement
var player_manager
var targeting_manager

# AI properties
var difficulty = Difficulty.MEDIUM
var current_state = AIState.IDLE
var player_id = 1 # AI is typically player 2
var thinking_time_min = 1.0 # Increased minimum time to make it more visible
var thinking_time_max = 2.5 # Increased maximum time to make it more visible
var thinking_indicator_visible = false

# Initialize the AI with game references
func initialize(p_game_board, p_weapon_types, p_weapon_placement, p_player_manager, p_targeting_manager):
	print("Initializing AI opponent...")
	game_board = p_game_board
	weapon_types = p_weapon_types
	weapon_placement = p_weapon_placement
	player_manager = p_player_manager
	targeting_manager = p_targeting_manager
	
	# Connect signals directly instead of calling connect_ai_signals
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		if game_manager.base_ui_manager:
			# Connect thinking signals directly
			if !is_connected("thinking_started", Callable(game_manager.base_ui_manager, "show_ai_thinking")):
				connect("thinking_started", Callable(game_manager.base_ui_manager, "show_ai_thinking"))
			if !is_connected("thinking_completed", Callable(game_manager.base_ui_manager, "hide_ai_thinking")):
				connect("thinking_completed", Callable(game_manager.base_ui_manager, "hide_ai_thinking"))
	
	return true

# Set AI difficulty
func set_difficulty(new_difficulty):
	difficulty = new_difficulty
	print("AI difficulty set to: " + str(Difficulty.keys()[difficulty]))

# Perform base placement - updated to use events
func perform_base_placement():
	print("AI perform_base_placement function called")
	
	# Emit thinking started event and also keep the signal for backward compatibility
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.AI_THINKING_STARTED)
	emit_signal("thinking_started")
	
	current_state = AIState.THINKING
	
	# Place base immediately - no delay
	var base_placement_position = _determine_base_position()
	print("AI decided to place base at: ", base_placement_position)
	
	if base_placement_position:
		_place_base(base_placement_position)
		print("AI base placement executed successfully")
	else:
		print("AI could not find valid base position! Emergency fallback needed")
	
	# Complete the process
	current_state = AIState.IDLE
	print("AI base placement complete")
	
	# Emit thinking completed event and also keep the signal for backward compatibility
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.AI_THINKING_COMPLETED)
	emit_signal("thinking_completed")
	
	emit_signal("action_taken", "base_placement")
	
	return true

# Perform weapon placement - updated to use callbacks instead of await
func perform_weapon_placement():
	print("AI performing weapon placement...")
	
	# Emit thinking started event
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.AI_THINKING_STARTED)
	emit_signal("thinking_started")
	
	current_state = AIState.THINKING
	
	# Use a timer callback instead of await
	var thinking_timer = get_tree().create_timer(1.5)
	thinking_timer.timeout.connect(_place_weapons_after_thinking)
	
	return true # Return immediately, signal will be emitted later

# Method to run after thinking timer completes
func _place_weapons_after_thinking():
	# Place weapons immediately
	var resources_remaining = weapon_placement.get_player_resources(player_id)
	print("AI has " + str(resources_remaining) + " resources for weapons")
	
	var weapons_placed = 0
	while resources_remaining > 0:
		var weapon_choice = _select_weapon_to_place(resources_remaining)
		if weapon_choice == null:
			print("AI: No affordable weapons left")
			break # No affordable weapons left
			
		var position = _determine_weapon_position(weapon_choice)
		if position == null:
			print("AI: No valid positions left for " + weapon_choice.name)
			break # No valid positions left
			
		print("AI placing weapon " + weapon_choice.name + " at position " + str(position))
		_place_weapon(weapon_choice, position)
		weapons_placed += 1
		
		# Update remaining resources
		resources_remaining = weapon_placement.get_player_resources(player_id)
		print("AI resources remaining: " + str(resources_remaining))
		
		# Safety check to prevent infinite loops
		if weapons_placed >= 5: # Reasonable upper limit
			print("AI reached maximum weapon placement limit")
			break
	
	print("AI placed " + str(weapons_placed) + " weapons total")
	
	# Complete the process
	current_state = AIState.IDLE
	print("AI weapon placement complete")
	
	# Emit thinking completed event
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.AI_THINKING_COMPLETED)
	emit_signal("thinking_completed")
	
	# Emit action taken event
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.AI_MOVE_EXECUTED, {"action_type": "weapon_placement"})
	emit_signal("action_taken", "weapon_placement")

# Perform targeting - updated to use events
func perform_targeting():
	print("AI performing targeting...")
	
	# Emit thinking started event and also keep the signal for backward compatibility
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.AI_THINKING_STARTED)
	emit_signal("thinking_started")
	
	current_state = AIState.THINKING
	
	# Find all player weapons that can attack
	var attackable_weapons = _find_attackable_weapons()
	
	# Select targets for each weapon
	var selected_weapons = []
	var targets = []
	
	for weapon in attackable_weapons:
		var target = _determine_target_for_weapon(weapon)
		if target != null:
			selected_weapons.append(weapon)
			targets.append(target)
	
	# Complete the process
	current_state = AIState.IDLE
	
	# Emit thinking completed event and also keep the signal for backward compatibility
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.AI_THINKING_COMPLETED)
	emit_signal("thinking_completed")
	
	# Emit AI move executed event
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.AI_MOVE_EXECUTED, {"action_type": "targeting"})
	emit_signal("action_taken", "targeting")
	
	# Return the targeting choices
	return {
		"selected_weapons": selected_weapons,
		"targets": targets
	}

# Determines where the AI should place its base
func _determine_base_position():
	print("AI determining base position...")
	
	# Get base weapon type to know its size
	var base_type = _get_base_weapon_type()
	if !base_type:
		print("ERROR: Could not find base weapon type")
		return null
		
	# Get game board dimensions
	var grid_size = game_board.grid_size
	
	# For player 2 (AI), use the right half of the board
	var island_margin = game_board.island_margin
	var island_size = game_board.island_size
	
	# Calculate AI's territory
	var x_start = grid_size.x - island_size.x - island_margin.x
	var x_end = grid_size.x - island_margin.x
	var y_start = island_margin.y
	var y_end = island_margin.y + island_size.y
	
	# Calculate center position, but ensure it's safely inside AI territory
	# and with enough space for the base
	var center_x = x_start + (island_size.x / 2) - (base_type.size.x / 2)
	var center_y = y_start + (island_size.y / 2) - (base_type.size.y / 2)
	
	# Round to ensure we get whole integers
	center_x = floor(center_x)
	center_y = floor(center_y)
	
	# Ensure we don't exceed boundaries
	center_x = max(x_start, min(center_x, x_end - base_type.size.x))
	center_y = max(y_start, min(center_y, y_end - base_type.size.y))
	
	print("AI looking for position near center of territory: (" + str(center_x) + ", " + str(center_y) + ")")
	
	# Check if center position is unoccupied
	var can_place_at_center = true
	for x in range(base_type.size.x):
		for y in range(base_type.size.y):
			var check_x = center_x + x
			var check_y = center_y + y
			
			# Ensure we're in bounds
			if check_x < 0 or check_x >= grid_size.x or check_y < 0 or check_y >= grid_size.y:
				can_place_at_center = false
				break
				
			var cell = game_board.grid[check_x][check_y]
			if cell.occupied_by != null:
				can_place_at_center = false
				break
	
	if can_place_at_center:
		print("AI will place base at center: (" + str(center_x) + ", " + str(center_y) + ")")
		return Vector2(center_x, center_y)
	
	# If center position is not available, search for any valid position
	print("Center position unavailable, searching for any valid position...")
	
	# Try to find an unoccupied spot starting from the back of AI territory
	for y in range(y_start, y_end - base_type.size.y + 1):
		for x in range(x_start, x_end - base_type.size.x + 1):
			var can_place_here = true
			
			# Check if all cells needed for the base are unoccupied
			for bx in range(base_type.size.x):
				for by in range(base_type.size.y):
					var check_x = x + bx
					var check_y = y + by
					
					# Skip if out of bounds
					if check_x < 0 or check_x >= grid_size.x or check_y < 0 or check_y >= grid_size.y:
						can_place_here = false
						break
						
					var cell = game_board.grid[check_x][check_y]
					if cell.occupied_by != null:
						can_place_here = false
						break
				
				if not can_place_here:
					break
			
			if can_place_here:
				print("AI found valid base position at: (" + str(x) + ", " + str(y) + ")")
				return Vector2(x, y)
	
	print("ERROR: Could not find any valid position for AI base!")
	return null

# Place a base at the specified position
func _place_base(position):
	print("AI placing base at: " + str(position))
	var base_type = _get_base_weapon_type()
	if base_type and position:
		print("AI using base type: " + str(base_type.name) + " with id: " + str(base_type.id))
		# Call place_weapon with correct parameters
		if weapon_placement.has_method("place_weapon"):
			weapon_placement.place_weapon(base_type.id, position, player_id)
		else:
			print("ERROR: weapon_placement doesn't have place_weapon method")
	else:
		print("ERROR: AI couldn't place base - base_type: " + str(base_type) + ", position: " + str(position))

# Get the base weapon type
func _get_base_weapon_type():
	for weapon in weapon_types.get_weapons_for_player(player_id):
		if weapon.type == "base":
			return weapon
	return null

# Select which weapon to place based on resources and strategy
func _select_weapon_to_place(available_resources):
	var affordable_weapons = []
	
	# Filter affordable weapons
	print("AI selecting weapon to place with " + str(available_resources) + " resources")
	for weapon in weapon_types.get_weapons_for_player(player_id):
		if weapon.cost <= available_resources and weapon.type != "base":
			affordable_weapons.append(weapon)
			print("AI considering weapon: " + weapon.name + " (cost: " + str(weapon.cost) + ")")
	
	if affordable_weapons.size() == 0:
		print("AI: No affordable weapons available")
		return null
	
	# Simple strategy: prioritize offensive weapons
	var offensive_weapons = affordable_weapons.filter(func(w): return w.type == "offensive")
	var defensive_weapons = affordable_weapons.filter(func(w): return w.type == "defensive")
	
	match difficulty:
		Difficulty.EASY:
			# Easy AI chooses randomly
			return affordable_weapons[randi() % affordable_weapons.size()]
			
		Difficulty.MEDIUM:
			# Medium AI prefers a mix of offensive (60%) and defensive (40%) if possible
			if randf() < 0.6 and offensive_weapons.size() > 0:
				return offensive_weapons[randi() % offensive_weapons.size()]
			elif defensive_weapons.size() > 0:
				return defensive_weapons[randi() % defensive_weapons.size()]
			else:
				return affordable_weapons[randi() % affordable_weapons.size()]
				
		Difficulty.HARD:
			# Hard AI makes more strategic choices based on game state
			# (This would be expanded in future implementations)
			if offensive_weapons.size() > 0:
				# Sort by damage potential
				offensive_weapons.sort_custom(func(a, b): return a.damage > b.damage)
				return offensive_weapons[0] # Choose highest damage weapon
			elif defensive_weapons.size() > 0:
				return defensive_weapons[randi() % defensive_weapons.size()]
			else:
				return affordable_weapons[randi() % affordable_weapons.size()]
	
	# Fallback
	return affordable_weapons[randi() % affordable_weapons.size()]

# Determine where to place a weapon
func _determine_weapon_position(weapon_data):
	var grid_size = game_board.grid_size
	
	# Get player's half of the board
	var y_start = 0
	var y_end = grid_size.y / 2
	
	# For player 2 (AI), use the bottom half
	if player_id == 1:
		y_start = grid_size.y / 2
		y_end = grid_size.y
	
	# Create a list of candidate positions
	var candidate_positions = []
	
	for y in range(y_start, y_end):
		for x in range(grid_size.x):
			var position = Vector2(x, y)
			
			# Check if position is valid for placement
			if weapon_placement.can_place_at_position(weapon_data, position, player_id):
				# Score this position
				var score = _score_position_for_weapon(weapon_data, position)
				candidate_positions.append({"position": position, "score": score})
	
	# If no valid positions, return null
	if candidate_positions.size() == 0:
		return null
	
	# Sort by score (higher is better)
	candidate_positions.sort_custom(func(a, b): return a.score > b.score)
	
	# Choose position based on difficulty
	match difficulty:
		Difficulty.EASY:
			# Easy AI makes random choice from top 50%
			var index = randi() % int(candidate_positions.size() * 0.5 + 1)
			return candidate_positions[min(index, candidate_positions.size() - 1)].position
			
		Difficulty.MEDIUM:
			# Medium AI makes random choice from top 3 positions
			var index = randi() % min(3, candidate_positions.size())
			return candidate_positions[index].position
			
		Difficulty.HARD:
			# Hard AI always chooses the best position
			return candidate_positions[0].position
	
	# Fallback
	return candidate_positions[0].position

# Score a position for a particular weapon (higher is better)
func _score_position_for_weapon(weapon_data, position):
	var score = 0
	
	# Base scoring logic
	if weapon_data.type == "offensive":
		# Offensive weapons score higher when placed near front
		var distance_from_front = abs(position.y - (game_board.grid_size.y / 2))
		score += 10 - min(10, distance_from_front * 2)
	elif weapon_data.type == "defensive":
		# Defensive weapons score higher when placed near base
		var base_positions = _find_own_base_positions()
		if base_positions.size() > 0:
			var closest_distance = 999
			for base_pos in base_positions:
				var distance = position.distance_to(base_pos)
				closest_distance = min(closest_distance, distance)
			score += 10 - min(10, closest_distance)
	
	# Prefer positions away from other weapons (avoid clustering)
	var occupied_neighbor_count = 0
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			
			var nx = position.x + dx
			var ny = position.y + dy
			
			if nx >= 0 and nx < game_board.grid_size.x and ny >= 0 and ny < game_board.grid_size.y:
				if game_board.grid[nx][ny].occupied_by:
					occupied_neighbor_count += 1
	
	score -= occupied_neighbor_count * 2
	
	return score

# Find positions of the AI's own bases
func _find_own_base_positions():
	var base_positions = []
	
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			if cell.occupied_by and cell.occupied_by.player_id == player_id:
				if "weapon_data" in cell.occupied_by and cell.occupied_by.weapon_data.type == "base":
					base_positions.append(Vector2(x, y))
	
	return base_positions

# Place a weapon at the specified position
func _place_weapon(weapon_data, position):
	if position:
		# FIX: Correct parameter order (weapon, position, player_id)
		weapon_placement.place_weapon(weapon_data, position, player_id)

# Find all weapons that can attack
func _find_attackable_weapons():
	var attackable_weapons = []
	
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			if cell.occupied_by and cell.occupied_by.player_id == player_id:
				var weapon = cell.occupied_by
				if "weapon_data" in weapon and weapon.weapon_data.type == "offensive":
					attackable_weapons.append({"x": x, "y": y, "weapon_data": weapon.weapon_data})
	
	return attackable_weapons

# Determine target for a weapon
func _determine_target_for_weapon(weapon):
	var grid_size = game_board.grid_size
	var weapon_position = Vector2(weapon.x, weapon.y)
	var enemy_player_id = 1 - player_id # Other player
	
	# Get all possible targets for this weapon
	var possible_targets = []
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var target_position = Vector2(x, y)
			
			# Check if target is in range
			var is_in_range = targeting_manager.is_in_range(weapon_position, target_position, weapon.weapon_data)
			
			if is_in_range:
				var cell = game_board.grid[x][y]
				var target_value = 0
				
				# Check if target position has an enemy
				if cell.occupied_by and cell.occupied_by.player_id == enemy_player_id:
					if cell.occupied_by.weapon_data.type == "base":
						target_value = 100 # High priority for enemy bases
					elif cell.occupied_by.weapon_data.type == "offensive":
						target_value = 50 # Medium priority for offensive weapons
					else:
						target_value = 25 # Low priority for other structures
				else:
					target_value = 0 # No value for empty cells
				
				if target_value > 0:
					possible_targets.append({
						"position": target_position,
						"value": target_value
					})
	
	# If no valid targets, return null
	if possible_targets.size() == 0:
		return null
	
	# Sort targets by value (higher is better)
	possible_targets.sort_custom(func(a, b): return a.value > b.value)
	
	# Choose target based on difficulty
	match difficulty:
		Difficulty.EASY:
			# Easy AI chooses randomly from top 50% targets
			var index = randi() % int(possible_targets.size() * 0.5 + 1)
			return possible_targets[min(index, possible_targets.size() - 1)].position
			
		Difficulty.MEDIUM:
			# Medium AI chooses randomly from top 3 targets
			var index = randi() % min(3, possible_targets.size())
			return possible_targets[index].position
			
		Difficulty.HARD:
			# Hard AI always chooses the best target
			return possible_targets[0].position
	
	# Fallback
	return possible_targets[0].position
