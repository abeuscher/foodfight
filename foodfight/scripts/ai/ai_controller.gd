extends Node

# Import Phase enum from phase_manager.gd
const Phase = preload("res://scripts/states/phase_manager.gd").Phase

# Define signals
signal ai_action_started
signal ai_action_completed

# AI turn tracking
var ai_turn_in_progress = false
var ai_initialized = false

# References to game components
var ai_opponent
var ui_manager
var ai_ui_manager # Direct reference to AI UI Manager
var phase_manager
var player_manager

# AI action types
enum AIAction {BASE_PLACEMENT, WEAPON_PLACEMENT, TARGETING}

func initialize(p_ai_opponent, p_ui_manager, p_game_state_machine, p_player_manager):
	print("AIController: Initializing...")
	ai_opponent = p_ai_opponent
	ui_manager = p_ui_manager
	
	# Change: store game_state_machine and get the proper PhaseManager
	var game_state_machine = p_game_state_machine
	# Get the actual PhaseManager from the service registry
	phase_manager = get_service("PhaseManager")
	if !phase_manager:
		push_error("AIController: Failed to get PhaseManager service")
	
	player_manager = p_player_manager
	
	# Try to get a direct reference to the ai_ui_manager
	if ui_manager:
		if ui_manager.has_method("show_ai_thinking"):
			ai_ui_manager = ui_manager
		elif "ai_ui_manager" in ui_manager:
			ai_ui_manager = ui_manager.ai_ui_manager
	
	if !ai_opponent:
		push_error("AIController: Failed to initialize - missing AI opponent!")
		return null
		
	print("AIController: Successfully initialized")
	ai_initialized = true
	return self

# Check if the current player is the AI
func is_ai_turn():
	if !player_manager:
		return false
	return player_manager.is_current_player_ai()

# Process AI turn if needed
func process_ai_turn_if_needed():
	print("AIController: process_ai_turn_if_needed called")
	
	if !player_manager:
		print("AIController: No player manager available!")
		return false
	
	if !player_manager.is_current_player_ai():
		print("AIController: Not AI's turn - player index: " + str(player_manager.current_player_index))
		return false
		
	if !phase_manager:
		print("AIController: No phase manager - skipping")
		return false
	
	if ai_turn_in_progress:
		print("AIController: AI turn already in progress")
		return true
	
	print("AIController: Processing AI turn for phase " + str(phase_manager.current_phase))
	
	# Handle different states
	match phase_manager.current_phase:
		Phase.BASE_PLACEMENT:
			print("AIController: Handling AI base placement")
			handle_base_placement()
			return true
			
		Phase.WEAPON_PLACEMENT:
			print("AIController: Handling AI weapon placement")
			handle_weapon_placement()
			return true
			
		Phase.TARGETING:
			print("AIController: Handling AI targeting")
			handle_targeting()
			return true
	
	print("AIController: No matching phase handler")
	return false

# Show AI thinking indicator safely
func _show_ai_thinking():
	emit_signal("ai_action_started")
	
	if ai_ui_manager and ai_ui_manager.has_method("show_ai_thinking"):
		ai_ui_manager.show_ai_thinking()
	elif ui_manager and ui_manager.has_method("show_ai_thinking"):
		ui_manager.show_ai_thinking()

# Hide AI thinking indicator safely
func _hide_ai_thinking():
	emit_signal("ai_action_completed")
	
	if ai_ui_manager and ai_ui_manager.has_method("hide_ai_thinking"):
		ai_ui_manager.hide_ai_thinking()
	elif ui_manager and ui_manager.has_method("hide_ai_thinking"):
		ui_manager.hide_ai_thinking()

# Handle AI base placement
func handle_base_placement():
	if ai_turn_in_progress:
		print("AIController: Base placement already in progress")
		return
	
	print("AIController: Starting base placement action")
	ai_turn_in_progress = true
	
	# Show AI is thinking
	_show_ai_thinking()
	
	# Start AI base placement
	if !ai_opponent:
		push_error("AIController: No AI opponent to perform base placement")
		ai_turn_in_progress = false
		_hide_ai_thinking()
		_complete_base_placement()
		return
		
	print("AIController: Calling AI opponent perform_base_placement")
	var placement_result = ai_opponent.perform_base_placement()
	
	# Always notify completion via setTimeout to ensure UI update
	get_tree().create_timer(0.5).timeout.connect(_complete_base_placement)

# Complete the base placement process
func _complete_base_placement():
	print("AIController: Base placement action complete")
	ai_turn_in_progress = false
	_hide_ai_thinking()
	
	var player_idx = player_manager.current_player_index
	print("AIController: Emitting PHASE_ACTION_COMPLETED event for player " + str(player_idx))
	
	# Ensure we're emitting for the correct player (the AI)
	if player_idx != 1: # AI is typically player 1
		print("AIController: WARNING - Current player index mismatch, correcting to AI player (1)")
		player_idx = 1
	
	# Use event bus to emit event with the corrected player index
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event("PHASE_ACTION_COMPLETED", {
			"phase": 2, # BASE_PLACEMENT
			"player_index": player_idx,
			"all_players_complete": player_idx == 1
		})

# Handle AI weapon placement
func handle_weapon_placement():
	if ai_turn_in_progress:
		return
	
	ai_turn_in_progress = true
	
	# Show AI is thinking
	_show_ai_thinking()
	
	# Start AI weapon placement
	if !ai_opponent:
		ai_turn_in_progress = false
		_hide_ai_thinking()
		return
		
	var placement_result = ai_opponent.perform_weapon_placement()
	
	# Create a short timer to complete the action (gives UI time to update)
	get_tree().create_timer(1.0).timeout.connect(func():
		ai_turn_in_progress = false
		_hide_ai_thinking()
		
		# Notify PhaseManager directly
		if phase_manager:
			phase_manager.weapon_placement_completed(player_manager.current_player_index)
	)

# Handle AI targeting
func handle_targeting():
	if ai_turn_in_progress:
		return
	
	ai_turn_in_progress = true
	
	# Show AI is thinking
	_show_ai_thinking()
	
	# Start AI targeting
	if !ai_opponent:
		ai_turn_in_progress = false
		_hide_ai_thinking()
		return
		
	var targeting_result = ai_opponent.perform_targeting()
	
	# Create a short timer to complete the action (gives UI time to update)
	get_tree().create_timer(1.0).timeout.connect(func():
		ai_turn_in_progress = false
		_hide_ai_thinking()
		
		# Notify PhaseManager directly
		if phase_manager:
			phase_manager.targeting_completed(player_manager.current_player_index)
	)

# Check if AI is currently processing
func is_thinking():
	return ai_turn_in_progress

# Block player input (call this from _input method)
func block_input_if_needed(event, current_player_index):
	# If it's AI's turn or AI is thinking, block input
	if (player_manager and player_manager.is_current_player_ai()) or ai_turn_in_progress:
		get_viewport().set_input_as_handled()
		return true
	return false

# Helper to get a service using the service locator
func get_service(service_name):
	if Engine.has_singleton("GameManager"):
		return Engine.get_singleton("GameManager").get_service(service_name)
	return null

# Add event listeners to respond to game events
func on_next_player_turn(event_data):
	if !player_manager.is_current_player_ai():
		return
		
	# Simply respond to events that any human player would also receive
	match event_data.phase:
		Phase.BASE_PLACEMENT:
			_start_ai_base_placement()
		Phase.WEAPON_PLACEMENT:
			_start_ai_weapon_placement()

# Add these helper methods that were referenced:
func _start_ai_base_placement():
	handle_base_placement()
	
func _start_ai_weapon_placement():
	handle_weapon_placement()

# New method that takes a completion callback
func process_ai_turn_with_callback(completion_callback):
	print("AIController: process_ai_turn_with_callback called")
	
	# ALWAYS get a fresh reference to PhaseManager
	phase_manager = get_service("PhaseManager")
	
	if !phase_manager:
		print("AIController: CRITICAL ERROR - Cannot get PhaseManager service!")
		completion_callback.call() # Still call callback to unblock
		return false
		
	print("AIController: Current phase from phase_manager: " + str(phase_manager.current_phase)
		  +" (" + (str(Phase.keys()[phase_manager.current_phase]) if phase_manager.current_phase < len(Phase.keys()) else "UNKNOWN") + ")")
	
	# Debug phase enumeration
	print("AIController: BASE_PLACEMENT = " + str(Phase.BASE_PLACEMENT))
	
	if !player_manager:
		print("AIController: No player manager available!")
		completion_callback.call() # Still call callback to unblock
		return false
	
	if !player_manager.is_current_player_ai():
		print("AIController: Not AI's turn - player index: " + str(player_manager.current_player_index))
		completion_callback.call() # Still call callback to unblock
		return false
	
	if ai_turn_in_progress:
		print("AIController: AI turn already in progress")
		completion_callback.call() # Still call callback to unblock
		return true
	
	# Start AI processing
	ai_turn_in_progress = true
	_show_ai_thinking()
	
	print("AIController: Processing AI turn for phase " + str(phase_manager.current_phase))
	
	# CRITICAL FIX: Handle base placement explicitly for phase 2
	if phase_manager.current_phase == 2: # BASE_PLACEMENT
		print("AIController: Explicit handler for BASE_PLACEMENT (phase 2)")
		_handle_base_placement_with_callback(completion_callback)
		return true
	
	# Regular phase handling
	match phase_manager.current_phase:
		Phase.BASE_PLACEMENT:
			print("AIController: Handling BASE_PLACEMENT via enum match")
			_handle_base_placement_with_callback(completion_callback)
		Phase.WEAPON_PLACEMENT:
			_handle_weapon_placement_with_callback(completion_callback)
		Phase.TARGETING:
			_handle_targeting_with_callback(completion_callback)
		_:
			print("AIController: No matching phase handler for phase " + str(phase_manager.current_phase))
			ai_turn_in_progress = false
			_hide_ai_thinking()
			completion_callback.call() # Must call callback to unblock game
	
	return true
	
# Phase-specific methods with callbacks
func _handle_base_placement_with_callback(completion_callback):
	print("AIController: Starting base placement with callback")
	
	if !ai_opponent:
		print("AIController: No AI opponent available!")
		ai_turn_in_progress = false
		_hide_ai_thinking()
		completion_callback.call()
		return
		
	# Run AI base placement with timeout to ensure completion
	print("AIController: Calling AI opponent perform_base_placement()")
	var placement_result = ai_opponent.perform_base_placement()
	
	# Complete after a short delay
	get_tree().create_timer(1.0).timeout.connect(func():
		# Complete the phase
		print("AIController: Base placement timer completed")
		ai_turn_in_progress = false
		_hide_ai_thinking()
		
		var player_idx = player_manager.current_player_index
		# Directly tell phase manager the action is complete
		if phase_manager:
			print("AIController: Telling phase_manager base_placement_completed for player " + str(player_idx))
			phase_manager.base_placement_completed(player_idx)
		else:
			print("AIController: NO PHASE MANAGER to tell base_placement_completed!")
			
		# Call the callback to unblock the game
		print("AIController: Calling completion callback")
		completion_callback.call()
	)

# Add similar methods for other phases
func _handle_weapon_placement_with_callback(completion_callback):
	if !ai_opponent:
		ai_turn_in_progress = false
		_hide_ai_thinking()
		completion_callback.call()
		return
	
	# Create wrapper function to handle the async operation without requiring await
	_start_weapon_placement(func():
		ai_turn_in_progress = false
		_hide_ai_thinking()
		
		var player_idx = player_manager.current_player_index
		if phase_manager:
			phase_manager.weapon_placement_completed(player_idx)
			
		completion_callback.call()
	)

# Helper function to handle the async operation
func _start_weapon_placement(on_complete_callback):
	# Start AI weapon placement and connect it to a one-shot completion function
	if ai_opponent and ai_opponent.has_method("perform_weapon_placement"):
		# Connect to AI's action_taken signal as a oneshot for weapon placement completion
		if !ai_opponent.is_connected("action_taken", Callable(self, "_on_weapon_placement_complete")):
			ai_opponent.action_taken.connect(_on_weapon_placement_complete, CONNECT_ONE_SHOT)
		
		# Store the callback for later use
		_weapon_placement_callback = on_complete_callback
		
		# Start the weapon placement - don't try to get or await the result
		ai_opponent.perform_weapon_placement()
	else:
		# If AI opponent doesn't have the method, call the callback directly
		on_complete_callback.call()

# Callback variable - needs to be a class property
var _weapon_placement_callback = null

# Signal handler for weapon placement completion
func _on_weapon_placement_complete(action_type):
	if action_type == "weapon_placement" and _weapon_placement_callback != null:
		# Call the stored callback and clear it
		var callback = _weapon_placement_callback
		_weapon_placement_callback = null
		callback.call()

func _handle_targeting_with_callback(completion_callback):
	if !ai_opponent:
		ai_turn_in_progress = false
		_hide_ai_thinking()
		completion_callback.call()
		return
		
	var targeting_result = ai_opponent.perform_targeting()
	
	get_tree().create_timer(0.5).timeout.connect(func():
		ai_turn_in_progress = false
		_hide_ai_thinking()
		
		var player_idx = player_manager.current_player_index
		if phase_manager:
			phase_manager.targeting_completed(player_idx)
			
		completion_callback.call()
	)
