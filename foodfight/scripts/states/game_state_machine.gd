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
var phase_manager

# State management
var current_state = GameState.UNINITIALIZED
var is_initialized = false

# Turn management
var turn_manager
var ai_controller
var single_player_mode = true # Always true in this version

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
	
	# Initialize phase manager
	phase_manager = Node.new()
	phase_manager.name = "PhaseManager"
	phase_manager.set_script(load("res://scripts/states/phase_manager.gd"))
	add_child(phase_manager)
	
	# Initialize phase manager with all dependencies
	phase_manager.initialize(game_board, weapon_types, weapon_placement,
							 targeting_state, attack_state, ui_manager, player_manager)
	
	# Connect phase manager signals
	phase_manager.phase_started.connect(_on_phase_started)
	phase_manager.phase_completed.connect(_on_phase_completed)
	
	# Register phase manager as service
	if Engine.has_singleton("GameManager"):
		Engine.get_singleton("GameManager").register_service("PhaseManager", phase_manager)
	
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
	single_player_mode = true # Always true

# Initialize the game state machine with the initial state
func initialize_state(initial_state):
	current_state = initial_state
	is_initialized = true
	print("GameStateMachine: Initialized with state " + str(GameState.keys()[initial_state]))

# Phase started callback
func _on_phase_started(phase, player_index):
	_set_state(phase)

# Phase completed callback
func _on_phase_completed(phase, player_index):
	print("GameStateMachine: Phase " + str(GameState.keys()[phase]) + " completed")

# Delegated methods - now pass through to PhaseManager
func _on_base_placement_complete(player_index):
	phase_manager.base_placement_completed(player_index)

# Check if a fallback is needed for AI actions
func check_ai_fallback_needed():
	# Only call this if we don't have a phase manager
	if phase_manager == null:
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
					if phase_manager != null:
						phase_manager.weapon_placement_completed(player_manager.current_player_index)
					return true
					
				GameState.TARGETING:
					# If AI is stuck in targeting, using fallback
					print("AI appears stuck in targeting, using fallback")
					phase_manager.targeting_completed()
					return true
		
		return false
	else:
		# Delegate to phase manager
		return false

# Fallback function to force AI base placement if needed
func _force_ai_base_placement():
	if phase_manager != null:
		phase_manager._force_ai_base_placement()
	else:
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
			_on_base_placement_complete(1) # Move to Player 2's base placement completion
		else:
			print("CRITICAL ERROR: Cannot find AI opponent for fallback base placement")
			# As last resort, just move to next phase
			await get_tree().create_timer(1.0).timeout
			_on_base_placement_complete(1)

# Modified _set_state function to emit an event
func _set_state(new_state):
	var old_state = current_state
	current_state = new_state
	
	print("GameStateMachine: State changed from " + str(GameState.keys()[old_state]) + " to " + str(GameState.keys()[new_state]))
	
	# Only emit event if phase_manager is not available (to avoid duplicates)
	if phase_manager == null:
		# Emit event for state change
		emit_event("STATE_CHANGED", {
			"old_state": old_state,
			"new_state": new_state,
			"player_index": player_manager.current_player_index
		})
	
	# Emergency direct notification to UI manager to update
	_ensure_ui_manager_updated(new_state)

# Helper function to ensure UI is updated after state changes
func _ensure_ui_manager_updated(state):
	# Try multiple approaches to find and use the UI manager
	var ui_manager = null
	
	# Try to get UI manager directly from game manager and update it
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		
		# Approach 1: Get service by name
		ui_manager = game_manager.get_service("BaseUIManager")
		
		# Approach 2: Try direct property access
		if !ui_manager and "base_ui_manager" in game_manager:
			ui_manager = game_manager.base_ui_manager
		
		# Try to use the UI manager we found
		if ui_manager and ui_manager.has_method("update_ui"):
			ui_manager.call("update_ui", state, player_manager.current_player_index)
		
		# FALLBACK: Try direct access to phase UI
		var phase_ui = game_manager.get_service("PhaseUIManager")
		if phase_ui and phase_ui.has_method("update_phase_ui"):
			phase_ui.update_phase_ui(state, player_manager.current_player_index)

# Resource update notification
func _on_resource_updated(player_id, amount):
	emit_event("INGREDIENTS_UPDATED", {
		"player_id": player_id,
		"amount": amount
	})

# Add a method to retrieve the game_state_machine via the service locator
func get_game_state_machine():
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		return game_manager.get_service("GameStateMachine")
	return null

# Update the connect_ui_buttons function to use the service locator
func connect_ui_buttons(main_scene):
	var game_state_machine = get_game_state_machine()
	if !game_state_machine:
		push_error("GameStateMachine not found. Cannot connect UI buttons.")
		return
	
	# End placement button
	var end_placement_button = main_scene.get_node("UI/BottomBar/EndPlacementButton")
	if end_placement_button:
		end_placement_button.pressed.connect(func():
			if game_state_machine.current_state == game_state_machine.GameState.BASE_PLACEMENT:
				game_state_machine._on_base_placement_complete(player_manager.current_player_index)
			elif game_state_machine.current_state == game_state_machine.GameState.WEAPON_PLACEMENT:
				game_state_machine.placement_completed()
		)
	
	# End targeting button
	var end_targeting_button = main_scene.get_node("UI/BottomBar/EndTargetingButton")
	if end_targeting_button:
		end_targeting_button.pressed.connect(func():
			if game_state_machine.current_state == game_state_machine.GameState.TARGETING:
				game_state_machine.targeting_completed()
		)
