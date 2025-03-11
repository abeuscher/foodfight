extends Node2D

# Game states
enum GameState {SETUP, BASE_PLACEMENT, WEAPON_PLACEMENT, TARGETING, ATTACK, RESOLUTION, GAME_OVER}

# Signals
signal state_changed(new_state)
signal game_over(winning_player)

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

# Default player values
var current_player_index = 0

# Track if base placement has been completed
var base_placement_done = false

# Initialization flag
var is_initialized = false

func _ready():
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
	
	# Check critical components
	if !game_board or !weapon_types or !weapon_placement:
		push_error("GameStateMachine: Missing critical components")
		return false
	
	# Connect attack state signals
	if attack_state:
		attack_state.connect("attack_completed", Callable(self, "_on_attack_completed"))
		attack_state.connect("points_awarded", Callable(self, "_on_points_awarded"))
	
	# Get player index if player manager is available
	if player_manager:
		current_player_index = player_manager.current_player_index
	
	# Reset base placement flag
	base_placement_done = false
	
	is_initialized = true
	print("GameStateMachine initialized successfully")
	return true

# Start the game state machine
func start_game():
	if !is_initialized:
		push_error("Cannot start game - GameStateMachine not initialized")
		return
	
	print("Starting game from GameStateMachine")
	change_state(GameState.SETUP)

# Change the game state
func change_state(new_state):
	if !is_initialized:
		return
		
	current_state = new_state
	print("Game state changed to: ", GameState.keys()[current_state])
	
	# Emit signal for state change
	emit_signal("state_changed", new_state)
	
	# Perform actions when entering a new state
	match new_state:
		GameState.SETUP:
			print("Setting up the game...")
			await get_tree().create_timer(0.5).timeout
			
			# Go to base placement only if not done yet
			if !base_placement_done:
				change_state(GameState.BASE_PLACEMENT)
			else:
				change_state(GameState.WEAPON_PLACEMENT)
			
		GameState.BASE_PLACEMENT:
			print("Starting base placement phase for " + get_current_player_name())
			if weapon_placement:
				# Start placement phase with special base placement flag
				weapon_placement.start_base_placement_phase(current_player_index)
			
		GameState.WEAPON_PLACEMENT:
			print("Starting weapon placement phase for " + get_current_player_name())
			if weapon_placement:
				weapon_placement.start_placement_phase(current_player_index)
				
			# Force refresh of the placement state
			if GameManager.placement_state:
				GameManager.placement_state._create_weapon_buttons()
			
		GameState.TARGETING:
			print("Starting targeting phase...")
			# Reset to player 1 for targeting phase
			reset_current_player()

			if GameManager.weapon_manager:
				GameManager.weapon_manager.collect_weapons()
				
			print("Reset to " + get_current_player_name() + " for targeting phase")
			if targeting_state:
				# Pass the current player index to start_targeting_phase
				targeting_state.start_targeting_phase(current_player_index)
			
		GameState.ATTACK:
			print("Starting attack phase...")
			execute_attacks()
			
		GameState.RESOLUTION:
			print("Resolving attacks...")
			# Check for game over condition
			check_game_over()
			
		GameState.GAME_OVER:
			print("Game over!")
			# Display game over screen or message
			if player_manager:
				var winner_name = "Player " + str(player_manager.winning_player + 1)
				emit_signal("game_over", player_manager.winning_player)
				print(winner_name + " has won the game!")
	
	# Update UI for the new state
	update_ui()

# Get current player name
func get_current_player_name():
	if player_manager:
		return player_manager.get_current_player_name()
	return "Player " + str(current_player_index + 1)

# Switch to next player
func next_player():
	if player_manager:
		player_manager.next_player()
		current_player_index = player_manager.current_player_index
	else:
		current_player_index = 1 if current_player_index == 0 else 0
	
	print("Current player: " + get_current_player_name())

# Reset to player 1
func reset_current_player():
	if player_manager:
		player_manager.reset_current_player()
		current_player_index = player_manager.current_player_index
	else:
		current_player_index = 0

# Update UI
func update_ui():
	if ui_manager:
		ui_manager.update_ui(current_state, current_player_index)

# Handle weapon placement event
func _on_weapon_placed(player_id, weapon_data, _position):
	if !is_initialized:
		return
		
	print(weapon_data.name + " placed by Player " + str(player_id + 1))
	
	# Check if player can continue placing weapons
	if weapon_placement and weapon_placement.get_player_resources(player_id) <= 0:
		print("Player " + str(player_id + 1) + " has no resources left")
		_on_placement_phase_complete(player_id)

# Handle resource update
func _on_resource_updated(player_id, amount):
	if !is_initialized:
		return
		
	if ui_manager:
		ui_manager.update_resource_display(player_id, amount)

# Handle completion of base placement phase for a player
func _on_base_placement_complete(player_id):
	if !is_initialized:
		return
		
	print("Base placement completed for Player ", player_id + 1)
	
	# If player 1 (index 0) just finished, switch to player 2
	if player_id == 0:
		next_player()
		if weapon_placement:
			weapon_placement.start_base_placement_phase(current_player_index)
		update_ui()
	# If player 2 (index 1) just finished, move to regular placement phase
	else:
		# Mark base placement as completed
		base_placement_done = true
		# Start with player 1 for the regular placement phase
		reset_current_player()
		change_state(GameState.WEAPON_PLACEMENT)

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
		
	if current_state == GameState.WEAPON_PLACEMENT and weapon_placement:
		weapon_placement.end_placement_phase()
		_on_placement_phase_complete(current_player_index)
	elif current_state == GameState.BASE_PLACEMENT and weapon_placement:
		weapon_placement.end_placement_phase()
		_on_base_placement_complete(current_player_index)

# Handle completion of targeting phase
func _on_targeting_completed(player_id, selected_weapons, targets):
	if !is_initialized:
		return
	
	print("Targeting phase completed for Player ", player_id + 1)
	
	# Store the targeting data for later use in attack phase
	if attack_state:
		attack_state.queue_attacks(player_id, selected_weapons, targets)
	
	# Check if all players have completed targeting
	if player_id == 0:
		# Switch to player 2
		next_player()
		if targeting_state:
			targeting_state.start_targeting_phase(current_player_index)
		update_ui()
	else:
		# Both players have completed targeting, move to attack phase
		change_state(GameState.ATTACK)

# Execute attacks for both players
func execute_attacks():
	if !is_initialized or !attack_state:
		print("Error: Missing required components for attack execution")
		change_state(GameState.RESOLUTION)
		return
	
	print("Executing attacks...")
	
	# Execute the queued attacks
	attack_state.execute_attacks()

# Handle attack phase completion
func _on_attack_completed():
	if !is_initialized:
		return
		
	print("Attack phase completed")
	change_state(GameState.RESOLUTION)

# Handle points awarded to a player
func _on_points_awarded(player_id, points):
	if !is_initialized or !player_manager:
		return
		
	# Award points to the player
	player_manager.add_points(player_id, points)
	
	# Update UI with new scores
	if ui_manager:
		ui_manager.update_ui(current_state, current_player_index)

# Check for game over condition
func check_game_over():
	if !is_initialized or !attack_state:
		await get_tree().create_timer(1.0).timeout
		change_state(GameState.WEAPON_PLACEMENT)
		return
	
	# Check if either player has won
	var winner = attack_state.check_game_over()
	
	if winner >= 0:
		# We have a winner!
		if player_manager:
			# Check if set_winner exists before calling it
			if player_manager.has_method("set_winner"):
				player_manager.set_winner(winner)
			else:
				# Fallback if set_winner doesn't exist
				print("Player ", winner + 1, " has won the game!")
				
		change_state(GameState.GAME_OVER)
	else:
		# Continue to next round - explicitly go to WEAPON_PLACEMENT (not BASE_PLACEMENT)
		await get_tree().create_timer(1.0).timeout
		reset_current_player()
		change_state(GameState.WEAPON_PLACEMENT)
