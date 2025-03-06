extends Node2D

# Game states
enum GameState {SETUP, PLACEMENT, TARGETING, ATTACK, RESOLUTION}

# Current game state
var current_state = GameState.SETUP

# References to game components
var game_board
var weapon_types
var weapon_placement
var targeting_state
var attack_state
var ui_manager
var player_manager

# Default player values (in case player_manager isn't ready)
var current_player_index = 0

# Initialization flag
var is_initialized = false

func _ready():
	# We'll wait for explicit initialization from Main
	print("GameStateMachine ready - waiting for initialization")

# Initialize the state machine with references to all required components
func initialize(p_game_board, p_weapon_types, p_weapon_placement, p_targeting_state, p_attack_state, p_ui_manager, p_player_manager):
	print("Initializing GameStateMachine...")
	
	# Store references to components
	game_board = p_game_board
	weapon_types = p_weapon_types
	weapon_placement = p_weapon_placement
	targeting_state = p_targeting_state
	attack_state = p_attack_state
	ui_manager = p_ui_manager
	player_manager = p_player_manager
	
	# Check that all required components are available
	if !game_board:
		push_error("GameStateMachine: game_board reference is null")
		return false
	
	if !weapon_types:
		push_error("GameStateMachine: weapon_types reference is null")
		return false
		
	if !weapon_placement:
		push_error("GameStateMachine: weapon_placement reference is null")
		return false
	
	# Player manager is optional, we have fallback code
	if player_manager:
		current_player_index = player_manager.current_player_index
	
	# Set initialization flag
	is_initialized = true
	print("GameStateMachine initialized successfully")
	return true

# Start the game state machine
func start_game():
	if !is_initialized:
		push_error("Cannot start game - GameStateMachine not initialized")
		return
	
	print("Starting game from GameStateMachine")
	# Start in SETUP state
	change_state(GameState.SETUP)

func _process(_delta):
	if !is_initialized:
		return
		
	# Game state machine
	match current_state:
		GameState.SETUP:
			# Setup phase logic
			# This phase is for initializing the game components
			pass
			
		GameState.PLACEMENT:
			# Placement phase logic is handled by signals
			pass
			
		GameState.TARGETING:
			# Targeting phase logic
			# Players choose targets for their weapons
			pass
			
		GameState.ATTACK:
			# Attack phase logic
			# Execute the attacks automatically
			pass
			
		GameState.RESOLUTION:
			# Resolution phase logic
			# Resolve attacks and check for game end conditions
			pass

# Change the game state
func change_state(new_state):
	if !is_initialized:
		push_error("Cannot change state - GameStateMachine not initialized")
		return
		
	current_state = new_state
	print("Game state changed to: ", GameState.keys()[current_state])
	
	# Perform actions when entering a new state
	match new_state:
		GameState.SETUP:
			print("Setting up the game...")
			# After setup is complete, move to placement phase
			await get_tree().create_timer(0.5).timeout
			change_state(GameState.PLACEMENT)
			
		GameState.PLACEMENT:
			print("Starting placement phase for " + get_current_player_name())
			# Start placement phase for current player
			if weapon_placement:
				weapon_placement.start_placement_phase(current_player_index)
			
		GameState.TARGETING:
			print("Starting targeting phase...")
			# Start the targeting phase
			if targeting_state:
				targeting_state.start_targeting_phase()
			
		GameState.ATTACK:
			print("Starting attack phase...")
			# Execute attacks automatically
			execute_attacks()
			
		GameState.RESOLUTION:
			print("Resolving attacks...")
			# Resolution phase logic will go here
			await get_tree().create_timer(2.0).timeout
			# For now, just cycle back to placement phase
			reset_current_player()
			change_state(GameState.PLACEMENT)
	
	# Update UI for the new state
	update_ui()

# Get current player name (fallback if player_manager not available)
func get_current_player_name():
	if player_manager and player_manager.has_method("get_current_player_name"):
		return player_manager.get_current_player_name()
	else:
		return "Player " + str(current_player_index + 1)

# Switch to next player (fallback if player_manager not available)
func next_player():
	if player_manager and player_manager.has_method("next_player"):
		player_manager.next_player()
		current_player_index = player_manager.current_player_index
	else:
		current_player_index = 1 if current_player_index == 0 else 0
	
	print("Current player: " + get_current_player_name())

# Reset to player 1 (fallback if player_manager not available)
func reset_current_player():
	if player_manager and player_manager.has_method("reset_current_player"):
		player_manager.reset_current_player()
		current_player_index = player_manager.current_player_index
	else:
		current_player_index = 0

# Update UI (with safety checks)
func update_ui():
	if ui_manager and ui_manager.has_method("update_ui"):
		ui_manager.update_ui(current_state, current_player_index)

# Handle weapon placement event
func _on_weapon_placed(player_id, weapon_data, _position):
	if !is_initialized:
		return
		
	# Add visual feedback or sound effect here
	print(weapon_data.name + " placed by Player " + str(player_id + 1))
	
	# Check if player can continue placing weapons
	if weapon_placement and weapon_placement.has_method("get_player_resources"):
		if weapon_placement.get_player_resources(player_id) <= 0:
			print("Player " + str(player_id + 1) + " has no resources left")
			_on_placement_phase_complete(player_id)

# Handle resource update
func _on_resource_updated(player_id, amount):
	if !is_initialized:
		return
		
	# Update resource display via UI manager
	if ui_manager and ui_manager.has_method("update_resource_display"):
		ui_manager.update_resource_display(player_id, amount)

# Handle completion of placement phase for a player
func _on_placement_phase_complete(player_id):
	if !is_initialized:
		return
		
	# If player 1 (index 0) just finished, switch to player 2
	if player_id == 0:
		next_player()
		if weapon_placement:
			weapon_placement.start_placement_phase(current_player_index)
		update_ui()
	# If player 2 (index 1) just finished, move to targeting phase
	else:
		change_state(GameState.TARGETING)

# Complete the placement phase
func placement_completed():
	if !is_initialized:
		return
		
	if current_state == GameState.PLACEMENT and weapon_placement:
		weapon_placement.end_placement_phase()
		_on_placement_phase_complete(current_player_index)

# Handle completion of targeting phase
func _on_targeting_completed():
	if !is_initialized:
		return
		
	print("Targeting phase completed")
	change_state(GameState.ATTACK)

# Execute attacks for both players
func execute_attacks():
	if !is_initialized:
		return
		
	print("Executing attacks...")
	
	if not attack_state:
		print("Error: AttackState not found")
		change_state(GameState.RESOLUTION)
		return
	
	if not targeting_state:
		print("Error: TargetingState not found")
		change_state(GameState.RESOLUTION)
		return
	
	# Get the queued attacks from targeting phase
	var queued_attacks = targeting_state.get_queued_attacks()
	
	# Pass the queued attacks to the attack state for execution
	if attack_state.has_method("execute_queued_attacks"):
		attack_state.execute_queued_attacks(queued_attacks)
	else:
		print("Error: AttackState missing execute_queued_attacks method")
		change_state(GameState.RESOLUTION)

# Handle attack phase completion
func _on_attack_completed():
	if !is_initialized:
		return
		
	print("Attack phase completed")
	change_state(GameState.RESOLUTION)
