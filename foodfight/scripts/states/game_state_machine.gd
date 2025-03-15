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
var ai_opponent

# New component references
var turn_manager
var ai_controller

# Track if base placement has been completed
var base_placement_done = false

# Initialization flag
var is_initialized = false

# Pending state change for handling transitions
var pending_state = null

func _ready():
	# Create new components
	turn_manager = load("res://scripts/states/turn_manager.gd").new()
	ai_controller = load("res://scripts/ai/ai_controller.gd").new()
	add_child(turn_manager)
	add_child(ai_controller)

func initialize(p_game_board, p_weapon_types, p_weapon_placement, p_targeting_state, p_attack_state, p_ui_manager, p_player_manager):
	# Store references to components
	game_board = p_game_board
	weapon_types = p_weapon_types
	weapon_placement = p_weapon_placement
	targeting_state = p_targeting_state
	attack_state = p_attack_state
	ui_manager = p_ui_manager
	player_manager = p_player_manager
	
	# Get AI opponent reference from GameManager
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		ai_opponent = game_manager.ai_opponent
	
	# Initialize new components
	turn_manager.initialize(player_manager)
	
	# Connect component signals
	turn_manager.connect("player_changed", Callable(self, "_on_player_changed"))
	
	# Initialize AI controller if AI opponent exists
	if ai_opponent:
		ai_controller.initialize(ai_opponent, ui_manager, self)
		ai_controller.connect("ai_action_completed", Callable(self, "_on_ai_action_completed"))
	
	# Connect attack state signals
	attack_state.connect("attack_completed", Callable(self, "_on_attack_completed"))
	attack_state.connect("ingredients_awarded", Callable(self, "_on_ingredients_awarded"))
	
	# Connect UI manager signals for title screen
	ui_manager.connect("title_screen_completed", Callable(self, "_on_title_screen_completed"))
	
	# Reset base placement flag
	base_placement_done = false
	
	is_initialized = true
	return true

# Start the game state machine
func start_game():
	change_state(GameState.SETUP)

# Change the game state with interstitial screen
func change_state(new_state):
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
	
	# Emit signal for state change
	emit_signal("state_changed", new_state)
	
	# Perform actions when entering a new state
	match new_state:
		GameState.SETUP:
			# Go to base placement only if not done yet
			if !base_placement_done:
				change_state(GameState.BASE_PLACEMENT)
			else:
				change_state(GameState.WEAPON_PLACEMENT)
			
		GameState.BASE_PLACEMENT:
			# Check if it's the AI's turn before creating UI elements
			if ai_controller.is_ai_turn(turn_manager.current_player_index) and ai_opponent:
				ai_controller.handle_base_placement()
			else:
				# Only start regular base placement UI for human player
				weapon_placement.start_base_placement_phase(turn_manager.current_player_index)
				update_ui()
			
		GameState.WEAPON_PLACEMENT:
			weapon_placement.start_placement_phase(turn_manager.current_player_index)
			
			# If it's the AI's turn, trigger AI weapon placement
			if ai_controller.is_ai_turn(turn_manager.current_player_index) and ai_opponent:
				ai_controller.handle_weapon_placement()
				
			# Force refresh of the placement state
			if Engine.has_singleton("GameManager"):
				var game_manager = Engine.get_singleton("GameManager")
				if game_manager and game_manager.placement_state:
					game_manager.placement_state._create_weapon_buttons()
			
		GameState.TARGETING:
			# Reset to player 1 for targeting phase
			turn_manager.reset_current_player()

			GameManager.weapon_manager.collect_weapons()
				
			targeting_state.start_targeting_phase(turn_manager.current_player_index)
			
			# If it's the AI's turn for targeting, handle that
			if ai_controller.is_ai_turn(turn_manager.current_player_index) and ai_opponent:
				var targeting_result = ai_controller.handle_targeting()
				if targeting_result and "selected_weapons" in targeting_result and "targets" in targeting_result:
					_on_targeting_completed(1, targeting_result.selected_weapons, targeting_result.targets)
			
		GameState.ATTACK:
			execute_attacks()
			
		GameState.RESOLUTION:
			# Check for game over condition
			check_game_over()
			
		GameState.GAME_OVER:
			var winner_name = "Player " + str(player_manager.winning_player + 1)
			emit_signal("game_over", player_manager.winning_player)
	
	# Update UI for the new state
	update_ui()

# Update UI
func update_ui():
	ui_manager.update_ui(current_state, turn_manager.current_player_index)

# Handle player change event
func _on_player_changed(new_player_index):
	update_ui()

# Handle AI action completion
func _on_ai_action_completed(action_type):
	match action_type:
		ai_controller.AIAction.BASE_PLACEMENT:
			_on_base_placement_complete(1)  # AI is player 2
		ai_controller.AIAction.WEAPON_PLACEMENT:
			_on_placement_phase_complete(1)  # AI is player 2
		ai_controller.AIAction.TARGETING:
			# Targeting is handled directly when targeting_result is received
			pass  # Added pass statement to fix syntax error

# Handle weapon placement event
func _on_weapon_placed(player_id, weapon_data, _position):
	# Check if player can continue placing weapons
	if weapon_placement.get_player_resources(player_id) <= 0:
		_on_placement_phase_complete(player_id)

# Handle resource update
func _on_resource_updated(player_id, amount):
	ui_manager.update_resource_display(player_id, amount)

# Handle completion of base placement phase for a player
func _on_base_placement_complete(player_id):
	# Check if base placement was actually done through placement
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
		# Restart this player's base placement phase
		weapon_placement.start_base_placement_phase(player_id)
		update_ui()
		return
	
	# If player 1 (index 0) just finished, switch to player 2
	if player_id == 0:
		turn_manager.next_player()
		weapon_placement.start_base_placement_phase(turn_manager.current_player_index)
		update_ui()
	# If player 2 (index 1) just finished, move to regular placement phase
	else:
		# Mark base placement as completed
		base_placement_done = true
		# Start with player 1 for the regular placement phase
		turn_manager.reset_current_player()
		change_state(GameState.WEAPON_PLACEMENT)

# Handle completion of placement phase for a player
func _on_placement_phase_complete(player_id):
	# If player 1 (index 0) just finished, switch to player 2
	if player_id == 0:
		turn_manager.next_player()
		weapon_placement.start_placement_phase(turn_manager.current_player_index)
		update_ui()
	# If player 2 (index 1) just finished, move to targeting phase
	else:
		change_state(GameState.TARGETING)

# Complete the placement phase
func placement_completed():
	if current_state == GameState.WEAPON_PLACEMENT:
		weapon_placement.end_placement_phase()
		_on_placement_phase_complete(turn_manager.current_player_index)
	elif current_state == GameState.BASE_PLACEMENT:
		# For base placement, first check if they actually placed a base
		var base_placed = false
		for x in range(game_board.grid_size.x):
			for y in range(game_board.grid_size.y):
				var cell = game_board.grid[x][y]
				if cell.occupied_by and "weapon_data" in cell.occupied_by:
					var weapon = cell.occupied_by.weapon_data
					if "type" in weapon and weapon.type == "base" and cell.occupied_by.player_id == turn_manager.current_player_index:
						base_placed = true
						break
		
		if base_placed:
			weapon_placement.end_placement_phase()
			_on_base_placement_complete(turn_manager.current_player_index)
		else:
			# Force restart of base placement UI
			if ui_manager:
				ui_manager.create_base_placement_ui(turn_manager.current_player_index)

# Handle completion of targeting phase
func _on_targeting_completed(player_id, selected_weapons, targets):
	# Store the targeting data for later use in attack phase
	attack_state.queue_attacks(player_id, selected_weapons, targets)
	
	# Check if all players have completed targeting
	if player_id == 0:
		# Switch to player 2
		turn_manager.next_player()
		targeting_state.start_targeting_phase(turn_manager.current_player_index)
		update_ui()
		
		# If player 2 is AI, handle AI targeting
		if ai_controller.is_ai_turn(turn_manager.current_player_index) and ai_opponent:
			var targeting_result = ai_controller.handle_targeting()
			if targeting_result and "selected_weapons" in targeting_result and "targets" in targeting_result:
				_on_targeting_completed(1, targeting_result.selected_weapons, targeting_result.targets)
	else:
		# Both players have completed targeting, move to attack phase
		change_state(GameState.ATTACK)

# Execute attacks for both players
func execute_attacks():
	attack_state.execute_attacks()

# Handle attack phase completion
func _on_attack_completed():
	change_state(GameState.RESOLUTION)

# Handle resources or points awarded to a player
func _on_points_awarded(player_id, points):
	if points > 0:
		_on_ingredients_awarded(player_id, points)

func _on_resources_awarded(player_id, resources):
	# No separate action needed - already handled by ingredients
	pass

# Handle ingredients awarded to a player
func _on_ingredients_awarded(player_id, amount):
	# Award ingredients to the player
	turn_manager.award_ingredients(player_id, amount)
	
	# Update UI with new ingredients
	update_ui()

# Check for game over condition
func check_game_over():
	# Check if either player has won
	var winner = attack_state.check_game_over()
	
	if winner >= 0:
		# We have a winner!
		turn_manager.set_winner(winner)
		change_state(GameState.GAME_OVER)
	else:
		# Continue to next round
		turn_manager.reset_current_player()
		change_state(GameState.WEAPON_PLACEMENT)

# Handle input for the current state
func handle_input(event):
	# Block input during AI turns
	if ai_controller.is_thinking():
		return false
	
	# Only process input for the human player (player 1)
	if ai_controller.is_ai_turn(turn_manager.current_player_index):
		return false
		
	# Process input based on current state
	match current_state:
		GameState.BASE_PLACEMENT, GameState.WEAPON_PLACEMENT:
			if weapon_placement:
				weapon_placement.handle_input(event)
				return true
			
		GameState.TARGETING:
			if targeting_state:
				targeting_state.handle_input(event)
				return true
	
	return false

# Override _input to block player input during AI turns
func _input(event):
	# Use AI controller to block input if needed
	ai_controller.block_input_if_needed(event, turn_manager.current_player_index)
