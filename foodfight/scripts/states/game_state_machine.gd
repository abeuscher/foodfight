extends Node2D

# Game states
enum GameState { 
	UNINITIALIZED,
	START_SCREEN,
	BASE_PLACEMENT,
	WEAPON_PLACEMENT,
	TARGETING,
	ATTACK_RESOLUTION,
	GAME_OVER
}

# Component references
var game_board
var weapon_types
var weapon_placement
var targeting_state
var attack_state
var ui_manager
var player_manager

# State management
var current_state = GameState.UNINITIALIZED
var is_initialized = false

# Turn management
var turn_manager
var ai_controller
var single_player_mode = true  # Always true in this version

func _ready():
	# Will be properly initialized from GameManager
	pass

# Initialize the game state machine with dependencies
func initialize(p_game_board, p_weapon_types, p_weapon_placement, 
				p_targeting_state, p_attack_state, p_ui_manager, p_player_manager):
	
	# Store component references
	game_board = p_game_board
	weapon_types = p_weapon_types
	weapon_placement = p_weapon_placement
	targeting_state = p_targeting_state
	attack_state = p_attack_state
	ui_manager = p_ui_manager
	player_manager = p_player_manager
	
	# Initialize turn management
	turn_manager = Node.new()
	turn_manager.name = "TurnManager"
	add_child(turn_manager)
	
	# Initialize AI controller
	ai_controller = Node.new()
	ai_controller.name = "AIController"
	ai_controller.set_script(load("res://scripts/ai/ai_controller.gd"))
	add_child(ai_controller)
	
	# Initialize AI controller
	var ai_opponent = get_node("/root/GameManager").ai_opponent if Engine.has_singleton("GameManager") else null
	if ai_opponent:
		ai_controller.initialize(ai_opponent, ui_manager, self, player_manager)
	
	# Set initialized flag
	is_initialized = true
	
	# Return self for method chaining
	return self

# Safe UI method call - call a method on ui_manager safely
func _safe_ui_call(method_name: String, args = []):
	if ui_manager == null:
		print("WARNING: ui_manager is null when trying to call " + method_name)
		return
		
	if ui_manager.has_method(method_name):
		match args.size():
			0: ui_manager.call(method_name)
			1: ui_manager.call(method_name, args[0])
			2: ui_manager.call(method_name, args[0], args[1])
			_: print("WARNING: Unsupported number of arguments for " + method_name)
	else:
		print("WARNING: ui_manager does not have method " + method_name)

# Set single player mode (always true in this version)
func set_single_player_mode(enabled):
	single_player_mode = true  # Always true

# Start the game
func start_game():
	if !is_initialized:
		push_error("Game state machine not initialized")
		return
	
	print("Game started, transitioning to base placement")
	current_state = GameState.BASE_PLACEMENT
	
	# IMPORTANT: Initialize weapon placement for base placement
	weapon_placement.start_base_placement_phase(player_manager.current_player_index)
	
	# Update UI for base placement - works with both original and refactored UI
	_safe_ui_call("update_game_phase", ["Base Placement Phase"])
	_safe_ui_call("update_current_turn", [player_manager.get_current_player_name()])
	_safe_ui_call("update_ui", [current_state, player_manager.current_player_index])
	
	# Process initial AI turn if needed
	_process_ai_turn_if_needed()

# Process AI turn if needed
func _process_ai_turn_if_needed():
	if player_manager.is_current_player_ai() and ai_controller:
		print("Processing AI turn for state: " + str(GameState.keys()[current_state]))
		
		# Add additional debugging to confirm AI controller state
		print("Current player index: " + str(player_manager.current_player_index))
		print("Is current player AI: " + str(player_manager.is_current_player_ai()))
		
		# Call the AI controller with more verbose logging
		var ai_processed = ai_controller.process_ai_turn_if_needed()
		print("AI controller processed turn: " + str(ai_processed))
		return ai_processed
	return false

# Handle base placement completion
func _on_base_placement_complete(player_index):
	print("Base placement complete for player: " + str(player_index + 1))
	
	# First player completed base placement
	if player_index == 0:
		# Switch to player 2
		player_manager.next_player()
		_safe_ui_call("update_current_turn", [player_manager.get_current_player_name()])
		
		# Update UI for player 2 (AI) - works with both original and refactored UI
		_safe_ui_call("update_ui", [current_state, player_manager.current_player_index])
		print("Player switched to AI for base placement")
		
		 # Extra debug info for AI turn
		print("Current player after switch:", player_manager.current_player_index)
		print("Is current player AI:", player_manager.is_current_player_ai())
		
		# Force a short delay to ensure UI updates before AI starts
		await get_tree().create_timer(0.5).timeout
		
		# Process AI turn if needed
		var ai_processed = _process_ai_turn_if_needed()
		print("AI base placement turn processed: " + str(ai_processed))
		
		# If AI turn wasn't processed properly, use fallback after a short delay
		if !ai_processed:
			print("WARNING: AI base placement not processed, using fallback")
			# Force AI base placement as fallback to avoid freezing
			await get_tree().create_timer(0.5).timeout
			_force_ai_base_placement()
			return
	else:
		# Both players have completed base placement, move to weapon placement
		print("Both players completed base placement, transitioning to WEAPON_PLACEMENT")
		current_state = GameState.WEAPON_PLACEMENT
		
		# Start the weapon placement phase
		weapon_placement.start_placement_phase(0)  # Start with Player 1
		
		_safe_ui_call("update_game_phase", ["Weapon Placement Phase"])
		
		# Reset turn to player 1
		player_manager.reset_current_player()
		_safe_ui_call("update_current_turn", [player_manager.get_current_player_name()])
		
		# IMPORTANT: Add explicit full UI update for the new state
		_safe_ui_call("update_ui", [current_state, player_manager.current_player_index])
		print("UI updated for WEAPON_PLACEMENT state with player", player_manager.current_player_index + 1)

# Fallback function to force AI base placement if needed
func _force_ai_base_placement():
	# This is a backup method to ensure the game doesn't freeze
	print("Forcing AI base placement as fallback")
	
	# Get the AI opponent
	var ai_opponent = null
	if Engine.has_singleton("GameManager"):
		ai_opponent = Engine.get_singleton("GameManager").ai_opponent
	
	if ai_opponent:
		# Perform AI base placement directly
		var result = ai_opponent.perform_base_placement()
		print("Forced AI base placement result:", result)
		
		# Force completion after a short delay
		await get_tree().create_timer(1.0).timeout
		print("Forcing completion of AI base placement phase")
		_on_base_placement_complete(1)  # Move to Player 2's base placement completion
	else:
		print("CRITICAL ERROR: Cannot find AI opponent for fallback base placement")
		# As last resort, just move to next phase
		await get_tree().create_timer(1.0).timeout
		_on_base_placement_complete(1)

# Check if a fallback is needed for AI actions
func check_ai_fallback_needed():
	# If it's AI's turn and no action is in progress, check if we need to recover
	if player_manager.is_current_player_ai() and ai_controller and !ai_controller.ai_turn_in_progress:
		match current_state:
			GameState.BASE_PLACEMENT:
				# If AI is stuck in base placement, force it
				if !player_manager.get_player_has_base(1):
					print("AI appears stuck in base placement, using fallback")
					_force_ai_base_placement()
					return true
					
			GameState.WEAPON_PLACEMENT:
				# If AI is stuck in weapon placement, force completion
				print("AI appears stuck in weapon placement, using fallback")
				_force_ai_placement_completion()
				return true
				
			GameState.TARGETING:
				# If AI is stuck in targeting, force completion
				print("AI appears stuck in targeting, using fallback")
				targeting_completed()
				return true
	
	return false

# Force AI placement completion - fallback mechanism if the AI controller fails
func _force_ai_placement_completion():
	print("Forcing AI placement completion as fallback")
	if player_manager.current_player == 1:  # If it's still AI's turn
		# Simulate that AI has completed weapon placement
		placement_completed()

# Complete the placement phase
func placement_completed():
	if current_state != GameState.WEAPON_PLACEMENT:
		return
	
	print("Weapon placement completed for player: " + str(player_manager.current_player))
	
	# First player completed weapon placement
	if player_manager.current_player == 0:
		# Switch to player 2 (AI)
		player_manager.next_player()
		_safe_ui_call("update_current_turn", [player_manager.get_current_player_name()])
		print("Switched to AI player for weapon placement")
		
		# IMPORTANT: Add explicit UI update for AI player
		_safe_ui_call("update_ui", [current_state, player_manager.current_player_index])
		
		# Process AI turn if needed
		var ai_processed = _process_ai_turn_if_needed()
		print("AI turn processed: " + str(ai_processed))
		
		# IMPORTANT: If AI turn wasn't processed, the game might freeze here
		if not ai_processed:
			print("WARNING: AI turn not processed properly!")
			# As a fallback, force transition to AI weapon placement completion
			# This is a safety measure in case the AI controller fails
			call_deferred("_force_ai_placement_completion")
		
		return
	else:
		# Both players have placed weapons, move to targeting phase
		current_state = GameState.TARGETING
		_safe_ui_call("update_game_phase", ["Targeting Phase"])
		
		# Reset turn to player 1
		player_manager.reset_current_player()
		_safe_ui_call("update_current_turn", [player_manager.get_current_player_name()])
		
		# IMPORTANT: Add explicit UI update for the new state
		_safe_ui_call("update_ui", [current_state, player_manager.current_player_index])
		
		# Process AI turn if needed (shouldn't be needed here as we reset to player 1)
		_process_ai_turn_if_needed()

# Complete the targeting phase
func targeting_completed():
	if current_state != GameState.TARGETING:
		return
		
	print("Targeting completed for player: " + str(player_manager.current_player))
	
	# First player completed targeting
	if player_manager.current_player == 0:
		# Switch to player 2 (AI)
		player_manager.next_player()
		_safe_ui_call("update_current_turn", [player_manager.get_current_player_name()])
		
		# IMPORTANT: Add explicit UI update for AI player
		_safe_ui_call("update_ui", [current_state, player_manager.current_player_index])
		
		# Process AI turn if needed
		if _process_ai_turn_if_needed():
			return
	else:
		# Both players have finished targeting, move to attack resolution
		current_state = GameState.ATTACK_RESOLUTION
		_safe_ui_call("update_game_phase", ["Attack Resolution Phase"])
		
		# IMPORTANT: Add explicit UI update for the new state
		_safe_ui_call("update_ui", [current_state, player_manager.current_player_index])
		
		# Start attack resolution
		attack_state.resolve_attacks()

# Complete attack resolution
func attack_resolution_completed():
	print("Attack resolution completed")
	
	# Check for game over
	var winning_player = _check_for_game_over()
	
	if winning_player >= 0:
		# Game over
		current_state = GameState.GAME_OVER
		_safe_ui_call("update_game_phase", ["Game Over"])
		_safe_ui_call("show_game_over", [winning_player])
		
		# IMPORTANT: Add explicit UI update for game over state
		_safe_ui_call("update_ui", [current_state, winning_player])
	else:
		# Start a new round with weapon placement
		current_state = GameState.WEAPON_PLACEMENT
		_safe_ui_call("update_game_phase", ["Weapon Placement Phase"])
		
		# Reset to player 1
		player_manager.reset_current_player()
		_safe_ui_call("update_current_turn", [player_manager.get_current_player_name()])
		
		# IMPORTANT: Add explicit UI update for the new round
		_safe_ui_call("update_ui", [current_state, player_manager.current_player_index])
		
		# Process AI turn if needed (shouldn't be needed here as we reset to player 1)
		_process_ai_turn_if_needed()

# Check for game over condition
func _check_for_game_over():
	# Count bases for each player
	var player1_bases = 0
	var player2_bases = 0
	
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			if cell.occupied_by and "weapon_data" in cell.occupied_by:
				if cell.occupied_by.weapon_data.type == "base":
					if cell.occupied_by.player_id == 0:
						player1_bases += 1
					else:
						player2_bases += 1
	
	# Check for winner
	if player1_bases == 0:
		player_manager.set_winner(1)
		return 1  # Player 2 (AI) wins
	elif player2_bases == 0:
		player_manager.set_winner(0)
		return 0  # Player 1 wins
	
	return -1  # No winner yet
