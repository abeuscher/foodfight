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

# Event bus reference
var event_bus

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
	
	# Get event bus reference
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		event_bus = game_manager.get_service("EventBus")
	
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

# Emit an event through the event bus
func emit_event(event_name, event_data = null):
	if event_bus:
		print("GameStateMachine: Emitting event: " + event_name)
		event_bus.emit_event(event_name, event_data)
	else:
		print("WARNING: No event bus available to emit event " + event_name)

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
	
	# Emit events for phase and player updates
	emit_event(GameEvents.PHASE_CHANGED, {
		"phase_text": "Base Placement Phase",
		"state": current_state
	})
	
	emit_event(GameEvents.PLAYER_CHANGED, {
		"player_index": player_manager.current_player_index,
		"player_name": player_manager.get_current_player_name()
	})
	
	emit_event(GameEvents.STATE_CHANGED, {
		"old_state": GameState.UNINITIALIZED,
		"new_state": current_state,
		"player_index": player_manager.current_player_index
	})
	
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
		
		# Emit events for player change
		emit_event(GameEvents.PLAYER_CHANGED, {
			"player_index": player_manager.current_player_index,
			"player_name": player_manager.get_current_player_name()
		})
		
		emit_event(GameEvents.STATE_CHANGED, {
			"old_state": current_state,
			"new_state": current_state, # Same state, different player
			"player_index": player_manager.current_player_index
		})
		
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
		print("====== CRITICAL DEBUG: Transitioning to WEAPON_PLACEMENT ======")
		
		# Start the weapon placement phase - IMPORTANT: Call this first
		weapon_placement.start_placement_phase(0)  # Start with Player 1
		
		# Then change the state - this will emit all necessary events
		_set_state(GameState.WEAPON_PLACEMENT)
		
		# Emit explicit phase change event with debug info
		print("Emitting PHASE_CHANGED event for Weapon Placement Phase")
		emit_event(GameEvents.PHASE_CHANGED, {
			"phase_text": "Weapon Placement Phase",
			"state": current_state
		})
		
		# Reset turn to player 1
		player_manager.reset_current_player()
		
		# Emit explicit player changed event with debug info
		print("Emitting PLAYER_CHANGED event for player 1")
		emit_event(GameEvents.PLAYER_CHANGED, {
			"player_index": player_manager.current_player_index,
			"player_name": player_manager.get_current_player_name()
		})
		
		# IMPORTANT: Add this direct call to the UI manager to ensure phase UI is updated
		if Engine.has_singleton("GameManager"):
			var game_manager = Engine.get_singleton("GameManager")
			
			print("====== CRITICAL DEBUG: Available services ======")
			for service_name in game_manager.services.keys():
				print("  - " + service_name + " is registered")
			
			print("====== CRITICAL DEBUG: Accessing PhaseUIManager service ======")
			var phase_ui_manager = game_manager.get_service("PhaseUIManager")
			print("  - PhaseUIManager found: " + str(phase_ui_manager != null))
			
			if phase_ui_manager:
				print("  - Has update_phase_ui method: " + str(phase_ui_manager.has_method("update_phase_ui")))
				print("  - Class type: " + str(phase_ui_manager.get_class()))
				var actual_script = phase_ui_manager.get_script()
				print("  - Script type: " + str(actual_script.get_path() if actual_script else "NONE"))
				
				if phase_ui_manager.has_method("update_phase_ui"):
					print("  - Calling update_phase_ui")
					phase_ui_manager.update_phase_ui(current_state, player_manager.current_player_index)
				else:
					print("  - ERROR: PhaseUIManager doesn't have update_phase_ui method!")
					# Check if it's actually a NullService
					if phase_ui_manager is NullService:
						print("  - CRITICAL ERROR: PhaseUIManager is a NullService!")
			else:
				print("  - ERROR: Could not find PhaseUIManager service!")

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
				# If AI is stuck in targeting, using fallback
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
		
		# Emit player changed event
		emit_event(GameEvents.PLAYER_CHANGED, {
			"player_index": player_manager.current_player_index,
			"player_name": player_manager.get_current_player_name()
		})
		
		emit_event(GameEvents.STATE_CHANGED, {
			"old_state": current_state,
			"new_state": current_state, # Same state, different player
			"player_index": player_manager.current_player_index
		})
		
		print("Switched to AI player for weapon placement")
		
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
		_set_state(GameState.TARGETING)
		
		emit_event(GameEvents.PHASE_CHANGED, {
			"phase_text": "Targeting Phase",
			"state": current_state
		})
		
		# Reset turn to player 1
		player_manager.reset_current_player()
		
		emit_event(GameEvents.PLAYER_CHANGED, {
			"player_index": player_manager.current_player_index,
			"player_name": player_manager.get_current_player_name()
		})
		
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
		
		emit_event(GameEvents.PLAYER_CHANGED, {
			"player_index": player_manager.current_player_index,
			"player_name": player_manager.get_current_player_name()
		})
		
		emit_event(GameEvents.STATE_CHANGED, {
			"old_state": current_state,
			"new_state": current_state, # Same state, different player
			"player_index": player_manager.current_player_index
		})
		
		# Process AI turn if needed
		if _process_ai_turn_if_needed():
			return
	else:
		# Both players have finished targeting, move to attack resolution
		_set_state(GameState.ATTACK_RESOLUTION)
		
		emit_event(GameEvents.PHASE_CHANGED, {
			"phase_text": "Attack Resolution Phase",
			"state": current_state
		})
		
		# Start attack resolution
		attack_state.execute_attacks()

# Complete attack resolution
func attack_resolution_completed():
	print("Attack resolution completed")
	
	# Check for game over
	var winning_player = _check_for_game_over()
	
	if winning_player >= 0:
		# Game over
		_set_state(GameState.GAME_OVER)
		
		emit_event(GameEvents.PHASE_CHANGED, {
			"phase_text": "Game Over",
			"state": current_state
		})
		
		emit_event(GameEvents.GAME_OVER, {
			"winning_player": winning_player
		})
	else:
		# Start a new round with weapon placement
		_set_state(GameState.WEAPON_PLACEMENT)
		
		emit_event(GameEvents.PHASE_CHANGED, {
			"phase_text": "Weapon Placement Phase",
			"state": current_state
		})
		
		# Reset to player 1
		player_manager.reset_current_player()
		
		emit_event(GameEvents.PLAYER_CHANGED, {
			"player_index": player_manager.current_player_index,
			"player_name": player_manager.get_current_player_name()
		})
		
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

# Modified _set_state function to emit an event
func _set_state(new_state):
	var old_state = current_state
	current_state = new_state
	
	print("GameStateMachine: State changed from " + str(GameState.keys()[old_state]) + " to " + str(GameState.keys()[new_state]))
	
	# Emit event for state change
	emit_event(GameEvents.STATE_CHANGED, {
		"old_state": old_state,
		"new_state": new_state,
		"player_index": player_manager.current_player_index
	})
	
	# Emergency direct notification to UI manager to update
	_ensure_ui_manager_updated(new_state)

# New helper function to ensure UI is updated after state changes
func _ensure_ui_manager_updated(state):
	print("====== CRITICAL DEBUG: Ensuring UI manager is updated ======")
	
	# Try multiple approaches to find and use the UI manager
	var ui_manager = null
	
	# Try to get UI manager directly from game manager and update it
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		
		print("DEBUG: Trying to find BaseUIManager service...")
		# Approach 1: Get service by name
		ui_manager = game_manager.get_service("BaseUIManager")
		print("DEBUG: BaseUIManager from get_service: " + ("found" if ui_manager else "not found"))
		
		# Approach 2: Try direct property access
		if !ui_manager and "base_ui_manager" in game_manager:
			ui_manager = game_manager.base_ui_manager
			print("DEBUG: BaseUIManager from direct property: " + ("found" if ui_manager else "not found"))
		
		# Try to use the UI manager we found
		if ui_manager:
			print("DEBUG: BaseUIManager class: " + str(ui_manager.get_class()))
			print("DEBUG: BaseUIManager has update_ui method: " + str(ui_manager.has_method("update_ui")))
			
			if ui_manager.has_method("update_ui"):
				print("GameStateMachine: Direct UI update via BaseUIManager")
				ui_manager.call("update_ui", state, player_manager.current_player_index)
			else:
				# Try to find the method another way - maybe it's stored in a variable?
				var methods = []
				for method in ui_manager.get_method_list():
					methods.append(method["name"])
				print("DEBUG: Available methods: " + str(methods))
				print("WARNING: BaseUIManager found but doesn't have update_ui method")
		else:
			print("WARNING: Could not find BaseUIManager service")
			
		# FALLBACK: Try direct access to UI elements through scene tree
		var main_scene = get_tree().current_scene
		if main_scene:
			# Try to access phase UI directly
			var phase_ui = game_manager.get_service("PhaseUIManager")
			if phase_ui and phase_ui.has_method("update_phase_ui"):
				print("DEBUG: Using PhaseUIManager directly as fallback")
				phase_ui.update_phase_ui(state, player_manager.current_player_index)
