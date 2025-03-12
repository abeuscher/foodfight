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

# Pending state change for handling transitions
var pending_state = null

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
	
	# Connect attack state signals
	attack_state.connect("attack_completed", Callable(self, "_on_attack_completed"))
	attack_state.connect("points_awarded", Callable(self, "_on_points_awarded"))
	
	# Connect UI manager signals for title screen
	ui_manager.connect("title_screen_completed", Callable(self, "_on_title_screen_completed"))
	
	# Get player index if player manager is available
	current_player_index = player_manager.current_player_index
	
	# Reset base placement flag
	base_placement_done = false
	
	is_initialized = true
	print("GameStateMachine initialized successfully")
	return true

# Start the game state machine
func start_game():
	print("Starting game from GameStateMachine")
	change_state(GameState.SETUP)

# Change the game state with interstitial screen
func change_state(new_state):
	print("Requesting state change to: ", GameState.keys()[new_state])
	
	# Skip title screen for the initial SETUP state and transitioning to itself
	if current_state == new_state or current_state == GameState.SETUP:
		_apply_state_change(new_state)
		return
	
	# Store the pending state
	pending_state = new_state
	
	# Show the title screen for the upcoming phase
	var phase_name = GameState.keys()[new_state]
	if phase_name != "RESOLUTION":
		ui_manager.show_phase_title(phase_name)
	else:
		# Skip title screen for RESOLUTION phase
		_apply_state_change(new_state)

# Handle title screen animation completion
func _on_title_screen_completed():
	if pending_state != null:
		_apply_state_change(pending_state)
		pending_state = null

# Actually apply the state change once title screen is complete
func _apply_state_change(new_state):
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
			weapon_placement.start_base_placement_phase(current_player_index)
			
		GameState.WEAPON_PLACEMENT:
			print("Starting weapon placement phase for " + get_current_player_name())
			weapon_placement.start_placement_phase(current_player_index)
				
			# Force refresh of the placement state
			if Engine.has_singleton("GameManager"):
				var game_manager = Engine.get_singleton("GameManager")
				if game_manager and game_manager.placement_state:
					game_manager.placement_state._create_weapon_buttons()
					print("Successfully called placement_state._create_weapon_buttons()")
				else:
					print("GameManager found but placement_state not available")
			else:
				print("GameManager singleton not found - manual refresh required")
				# Direct refresh if possible
				if weapon_placement and weapon_placement.get_parent() and weapon_placement.get_parent().has_node("PlacementState"):
					var placement_state = weapon_placement.get_parent().get_node("PlacementState")
					if placement_state and placement_state.has_method("_create_weapon_buttons"):
						placement_state._create_weapon_buttons()
						print("Used alternative method to refresh weapon buttons")
			
		GameState.TARGETING:
			print("Starting targeting phase...")
			# Reset to player 1 for targeting phase
			reset_current_player()

			GameManager.weapon_manager.collect_weapons()
				
			print("Reset to " + get_current_player_name() + " for targeting phase")
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
			var winner_name = "Player " + str(player_manager.winning_player + 1)
			emit_signal("game_over", player_manager.winning_player)
			print(winner_name + " has won the game!")
	
	# Update UI for the new state
	update_ui()

# Get current player name
func get_current_player_name():
	return player_manager.get_current_player_name()

# Switch to next player
func next_player():
	player_manager.next_player()
	current_player_index = player_manager.current_player_index
	
	print("Current player: " + get_current_player_name())

# Reset to player 1
func reset_current_player():
	player_manager.reset_current_player()
	current_player_index = player_manager.current_player_index

# Update UI
func update_ui():
	ui_manager.update_ui(current_state, current_player_index)

# Handle weapon placement event
func _on_weapon_placed(player_id, weapon_data, _position):
	print(weapon_data.name + " placed by Player " + str(player_id + 1))
	
	# Check if player can continue placing weapons
	if weapon_placement.get_player_resources(player_id) <= 0:
		print("Player " + str(player_id + 1) + " has no resources left")
		_on_placement_phase_complete(player_id)

# Handle resource update
func _on_resource_updated(player_id, amount):
	ui_manager.update_resource_display(player_id, amount)

# Handle completion of base placement phase for a player
func _on_base_placement_complete(player_id):
	print("Base placement completed for Player ", player_id + 1)
	
	# Check if base placement was actually done through placement
	# or just by clicking the end button
	var base_placed = false
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			if cell.occupied_by and "weapon_data" in cell.occupied_by:
				var weapon = cell.occupied_by.weapon_data
				if "type" in weapon and weapon.type == "base" and cell.occupied_by.player_id == player_id:
					base_placed = true
					break
	
	# If player didn't actually place a base, don't proceed
	if not base_placed:
		print("Player " + str(player_id + 1) + " didn't place a base yet!")
		# Restart this player's base placement phase
		weapon_placement.start_base_placement_phase(player_id)
		update_ui()
		return
	
	# If player 1 (index 0) just finished, switch to player 2
	if player_id == 0:
		next_player()
		print("Switching to Player 2's base placement turn")
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
	# If player 1 (index 0) just finished, switch to player 2
	if player_id == 0:
		next_player()
		weapon_placement.start_placement_phase(current_player_index)
		update_ui()
	# If player 2 (index 1) just finished, move to targeting phase
	else:
		change_state(GameState.TARGETING)

# Complete the placement phase
func placement_completed():
	if current_state == GameState.WEAPON_PLACEMENT:
		weapon_placement.end_placement_phase()
		_on_placement_phase_complete(current_player_index)
	elif current_state == GameState.BASE_PLACEMENT:
		# For base placement, first check if they actually placed a base
		var base_placed = false
		for x in range(game_board.grid_size.x):
			for y in range(game_board.grid_size.y):
				var cell = game_board.grid[x][y]
				if cell.occupied_by and "weapon_data" in cell.occupied_by:
					var weapon = cell.occupied_by.weapon_data
					if "type" in weapon and weapon.type == "base" and cell.occupied_by.player_id == current_player_index:
						base_placed = true
						break
		
		if base_placed:
			weapon_placement.end_placement_phase()
			_on_base_placement_complete(current_player_index)
		else:
			print("Player " + str(current_player_index + 1) + " must place a base before ending the phase!")
			# Force restart of base placement UI
			if ui_manager:
				ui_manager.create_base_placement_ui(current_player_index)

# Handle completion of targeting phase
func _on_targeting_completed(player_id, selected_weapons, targets):
	print("Targeting phase completed for Player ", player_id + 1)
	
	# Store the targeting data for later use in attack phase
	attack_state.queue_attacks(player_id, selected_weapons, targets)
	
	# Check if all players have completed targeting
	if player_id == 0:
		# Switch to player 2
		next_player()
		targeting_state.start_targeting_phase(current_player_index)
		update_ui()
	else:
		# Both players have completed targeting, move to attack phase
		change_state(GameState.ATTACK)

# Execute attacks for both players
func execute_attacks():
	print("Executing attacks...")
	
	# Execute the queued attacks
	attack_state.execute_attacks()

# Handle attack phase completion
func _on_attack_completed():
	print("Attack phase completed")
	change_state(GameState.RESOLUTION)

# Handle points awarded to a player
func _on_points_awarded(player_id, points):
	# Award points to the player
	player_manager.add_points(player_id, points)
	
	# Update UI with new scores
	ui_manager.update_ui(current_state, current_player_index)

# Check for game over condition
func check_game_over():
	# Check if either player has won
	var winner = attack_state.check_game_over()
	
	if winner >= 0:
		# We have a winner!
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
