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
	ui_manager.update_game_phase("Base Placement Phase")
	ui_manager.update_current_turn(player_manager.get_current_player_name())
	ui_manager.update_ui(current_state, player_manager.current_player_index)
	
	# Process initial AI turn if needed
	_process_ai_turn_if_needed()

# Process AI turn if needed
func _process_ai_turn_if_needed():
	if player_manager.is_current_player_ai() and ai_controller:
		print("Processing AI turn for state: " + str(GameState.keys()[current_state]))
		ai_controller.process_ai_turn_if_needed()
		return true
	return false

# Handle base placement completion
func _on_base_placement_complete(player_index):
	print("Base placement complete for player: " + str(player_index + 1))
	
	# First player completed base placement
	if player_index == 0:
		# Switch to player 2
		player_manager.next_player()
		ui_manager.update_current_turn(player_manager.get_current_player_name())
		
		# Update UI for player 2 (AI) - works with both original and refactored UI
		ui_manager.update_ui(current_state, player_manager.current_player_index)
		
		# Process AI turn if needed
		if _process_ai_turn_if_needed():
			return
	else:
		# Both players have completed base placement, move to weapon placement
		current_state = GameState.WEAPON_PLACEMENT
		print("Transitioning to WEAPON_PLACEMENT state")
		
		# Start the weapon placement phase
		weapon_placement.start_placement_phase(0)  # Start with Player 1
		
		ui_manager.update_game_phase("Weapon Placement Phase")
		
		# Reset turn to player 1
		player_manager.reset_current_player()
		ui_manager.update_current_turn(player_manager.get_current_player_name())
		
		# IMPORTANT: Add explicit full UI update for the new state
		ui_manager.update_ui(current_state, player_manager.current_player_index)
		print("UI updated for WEAPON_PLACEMENT state with player", player_manager.current_player_index + 1)
		
		# Process AI turn if needed (shouldn't be needed here as we reset to player 1)
		_process_ai_turn_if_needed()

# Complete the placement phase
func placement_completed():
	if current_state != GameState.WEAPON_PLACEMENT:
		return
	
	print("Weapon placement completed for player: " + str(player_manager.current_player))
	
	# First player completed weapon placement
	if player_manager.current_player == 0:
		# Switch to player 2 (AI)
		player_manager.next_player()
		ui_manager.update_current_turn(player_manager.get_current_player_name())
		
		# IMPORTANT: Add explicit UI update for AI player
		ui_manager.update_ui(current_state, player_manager.current_player_index)
		
		# Process AI turn if needed
		if _process_ai_turn_if_needed():
			return
	else:
		# Both players have placed weapons, move to targeting phase
		current_state = GameState.TARGETING
		ui_manager.update_game_phase("Targeting Phase")
		
		# Reset turn to player 1
		player_manager.reset_current_player()
		ui_manager.update_current_turn(player_manager.get_current_player_name())
		
		# IMPORTANT: Add explicit UI update for the new state
		ui_manager.update_ui(current_state, player_manager.current_player_index)
		
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
		ui_manager.update_current_turn(player_manager.get_current_player_name())
		
		# IMPORTANT: Add explicit UI update for AI player
		ui_manager.update_ui(current_state, player_manager.current_player_index)
		
		# Process AI turn if needed
		if _process_ai_turn_if_needed():
			return
	else:
		# Both players have finished targeting, move to attack resolution
		current_state = GameState.ATTACK_RESOLUTION
		ui_manager.update_game_phase("Attack Resolution Phase")
		
		# IMPORTANT: Add explicit UI update for the new state
		ui_manager.update_ui(current_state, player_manager.current_player_index)
		
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
		ui_manager.update_game_phase("Game Over")
		ui_manager.show_game_over(winning_player)
		
		# IMPORTANT: Add explicit UI update for game over state
		ui_manager.update_ui(current_state, winning_player)
	else:
		# Start a new round with weapon placement
		current_state = GameState.WEAPON_PLACEMENT
		ui_manager.update_game_phase("Weapon Placement Phase")
		
		# Reset to player 1
		player_manager.reset_current_player()
		ui_manager.update_current_turn(player_manager.get_current_player_name())
		
		# IMPORTANT: Add explicit UI update for the new round
		ui_manager.update_ui(current_state, player_manager.current_player_index)
		
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
