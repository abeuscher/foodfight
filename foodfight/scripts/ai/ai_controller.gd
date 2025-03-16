extends Node

signal ai_action_started
signal ai_action_completed(action_type)

# AI turn tracking
var ai_turn_in_progress = false
var ai_initialized = false

# References to game components
var ai_opponent
var ui_manager
var ai_ui_manager  # Direct reference to AI UI Manager
var game_state_machine
var player_manager

# AI action types
enum AIAction {BASE_PLACEMENT, WEAPON_PLACEMENT, TARGETING}

func initialize(p_ai_opponent, p_ui_manager, p_game_state_machine, p_player_manager):
	ai_opponent = p_ai_opponent
	ui_manager = p_ui_manager
	game_state_machine = p_game_state_machine
	player_manager = p_player_manager
	
	# Try to get a direct reference to the ai_ui_manager
	if ui_manager:
		if ui_manager.has_method("show_ai_thinking"):
			# Original UI structure - use directly
			ai_ui_manager = ui_manager
		elif "ai_ui_manager" in ui_manager:
			# New refactored structure - get the specific manager
			ai_ui_manager = ui_manager.ai_ui_manager
		elif ui_manager.get_parent() and "ai_ui_manager" in ui_manager.get_parent():
			# Try the parent (in case this is base_ui_manager)
			ai_ui_manager = ui_manager.get_parent().ai_ui_manager
		else:
			# No direct access, let's find it through GameManager
			if Engine.has_singleton("GameManager"):
				var GameManager = Engine.get_singleton("GameManager")
				if "ai_ui_manager" in GameManager:
					ai_ui_manager = GameManager.ai_ui_manager
				elif GameManager.game_ui_manager and "ai_ui_manager" in GameManager.game_ui_manager:
					ai_ui_manager = GameManager.game_ui_manager.ai_ui_manager
		
	ai_initialized = true
	print("AI Controller initialized with all components")
	if ai_ui_manager:
		print("AI UI Manager found and connected")
	else:
		print("WARNING: No AI UI Manager found")
	return self

# Check if the current player is the AI
func is_ai_turn():
	if !player_manager:
		return false
	return player_manager.is_current_player_ai()

# Process AI turn if needed
func process_ai_turn_if_needed():
	if !ai_initialized:
		print("AI controller not initialized!")
		return false
		
	if !is_ai_turn():
		print("Not AI's turn according to player manager")
		return false
		
	print("AI turn detected, processing actions for current state: " + str(game_state_machine.GameState.keys()[game_state_machine.current_state]))
	
	# Handle different states
	match game_state_machine.current_state:
		game_state_machine.GameState.BASE_PLACEMENT:
			handle_base_placement()
			return true
			
		game_state_machine.GameState.WEAPON_PLACEMENT:
			print("Handling AI weapon placement!")
			handle_weapon_placement()
			return true
			
		game_state_machine.GameState.TARGETING:
			handle_targeting()
			return true
	
	print("No handler for current game state: " + str(game_state_machine.GameState.keys()[game_state_machine.current_state]))
	return false

# Show AI thinking indicator safely
func _show_ai_thinking():
	if ai_ui_manager and ai_ui_manager.has_method("show_ai_thinking"):
		ai_ui_manager.show_ai_thinking()
	elif ui_manager and ui_manager.has_method("show_ai_thinking"):
		ui_manager.show_ai_thinking()
	else:
		print("Unable to show AI thinking - no suitable UI manager found")

# Hide AI thinking indicator safely
func _hide_ai_thinking():
	if ai_ui_manager and ai_ui_manager.has_method("hide_ai_thinking"):
		ai_ui_manager.hide_ai_thinking()
	elif ui_manager and ui_manager.has_method("hide_ai_thinking"):
		ui_manager.hide_ai_thinking()
	else:
		print("Unable to hide AI thinking - no suitable UI manager found")

# Handle AI base placement
func handle_base_placement():
	if ai_turn_in_progress:
		print("AI base placement already in progress")
		return
	
	print("Starting AI base placement")
	ai_turn_in_progress = true
	emit_signal("ai_action_started")
	
	# Show AI is thinking
	_show_ai_thinking()
	
	# Connect to completion signal
	if ai_opponent.is_connected("thinking_completed", Callable(self, "_on_base_placement_completed")):
		ai_opponent.disconnect("thinking_completed", Callable(self, "_on_base_placement_completed"))
		
	ai_opponent.connect("thinking_completed", Callable(self, "_on_base_placement_completed"), CONNECT_ONE_SHOT)
	
	# Start AI base placement with error handling
	print("Calling ai_opponent.perform_base_placement()")
	var placement_result = ai_opponent.perform_base_placement()
	print("AI base placement call result:", placement_result)
	
	# Safety check - if perform_base_placement returns false or null, force completion after timeout
	if !placement_result:
		print("WARNING: AI base placement call failed, setting fallback timer")
		# Use deferred call to avoid errors
		get_tree().create_timer(2.0).timeout.connect(func():
			if ai_turn_in_progress:
				print("AI base placement timed out, forcing completion")
				call_deferred("_on_base_placement_completed")
		)

# Handle AI base placement completion
func _on_base_placement_completed():
	print("DEBUG: AI base placement completed")
	ai_turn_in_progress = false
	emit_signal("ai_action_completed", AIAction.BASE_PLACEMENT)
	
	# Hide AI thinking - works with both original and refactored UI
	_hide_ai_thinking()
	
	# Print debug information before calling game state machine
	print("DEBUG: Current player index:", player_manager.current_player_index)
	print("DEBUG: Current game state:", game_state_machine.current_state)
	
	# Trigger completion in game state machine
	print("DEBUG: Calling game_state_machine._on_base_placement_complete")
	game_state_machine._on_base_placement_complete(player_manager.current_player_index)
	
	# Print state after completion
	print("DEBUG: After completion - Current game state:", game_state_machine.current_state)
	
	# Check if we need to process another turn immediately
	print("DEBUG: Checking if we need to process another AI turn")
	if process_ai_turn_if_needed():
		print("DEBUG: Processing another AI turn")

# Handle AI weapon placement
func handle_weapon_placement():
	if ai_turn_in_progress:
		print("AI turn already in progress, not starting weapon placement")
		return
	
	print("Starting AI weapon placement")
	ai_turn_in_progress = true
	emit_signal("ai_action_started")
	
	# Show AI is thinking - works with both original and refactored UI
	_show_ai_thinking()
	print("AI thinking indicator shown")
	
	# Connect to completion signal
	if ai_opponent.is_connected("thinking_completed", Callable(self, "_on_weapon_placement_completed")):
		ai_opponent.disconnect("thinking_completed", Callable(self, "_on_weapon_placement_completed"))
		
	ai_opponent.connect("thinking_completed", Callable(self, "_on_weapon_placement_completed"), CONNECT_ONE_SHOT)
	
	# Start AI weapon placement with error handling
	print("Calling ai_opponent.perform_weapon_placement()")
	var placement_result = ai_opponent.perform_weapon_placement()
	
	# Safety check - if perform_weapon_placement fails, force completion after timeout
	if !placement_result:
		print("WARNING: AI weapon placement call failed, setting fallback timer")
		get_tree().create_timer(3.0).timeout.connect(func():
			# Only force completion if still in progress
			if ai_turn_in_progress:
				print("AI weapon placement timed out, forcing completion")
				_on_weapon_placement_completed()
		)

# Handle AI weapon placement completion
func _on_weapon_placement_completed():
	print("AI weapon placement completed")
	ai_turn_in_progress = false
	emit_signal("ai_action_completed", AIAction.WEAPON_PLACEMENT)
	
	# Hide AI thinking - works with both original and refactored UI
	_hide_ai_thinking()
	print("Hiding AI thinking indicator")
	
	# Complete placement in game state machine
	print("Calling game_state_machine.placement_completed")
	game_state_machine.placement_completed()

# Handle AI targeting
func handle_targeting():
	if ai_turn_in_progress:
		return
		
	ai_turn_in_progress = true
	emit_signal("ai_action_started")
	
	# Show AI is thinking - works with both original and refactored UI
	_show_ai_thinking()
	
	# Connect to completion signal
	if ai_opponent.is_connected("thinking_completed", Callable(self, "_on_targeting_completed")):
		ai_opponent.disconnect("thinking_completed", Callable(self, "_on_targeting_completed"))
		
	ai_opponent.connect("thinking_completed", Callable(self, "_on_targeting_completed"), CONNECT_ONE_SHOT)
	
	# Start AI targeting and get the results
	var targeting_result = ai_opponent.perform_targeting()
	
	# Process the targeting results
	if targeting_result and "selected_weapons" in targeting_result and "targets" in targeting_result:
		for i in range(targeting_result.selected_weapons.size()):
			var weapon = targeting_result.selected_weapons[i]
			var target = targeting_result.targets[i]
			game_state_machine.targeting_state.select_weapon_for_targeting(weapon, player_manager.current_player_index)
			game_state_machine.targeting_state.confirm_target(target)

# Handle AI targeting completion
func _on_targeting_completed():
	print("DEBUG: AI targeting completed")
	ai_turn_in_progress = false
	emit_signal("ai_action_completed", AIAction.TARGETING)
	
	# Hide AI thinking - works with both original and refactored UI
	_hide_ai_thinking()
	
	# Complete targeting in game state machine
	game_state_machine.targeting_completed()

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
