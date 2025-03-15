extends Node

signal ai_action_started
signal ai_action_completed(action_type)

# AI turn tracking
var ai_turn_in_progress = false

# References to game components
var ai_opponent
var ui_manager
var game_state_machine

# AI action types
enum AIAction {BASE_PLACEMENT, WEAPON_PLACEMENT, TARGETING}

func initialize(p_ai_opponent, p_ui_manager, p_game_state_machine):
	ai_opponent = p_ai_opponent
	ui_manager = p_ui_manager
	game_state_machine = p_game_state_machine
	return self

# Check if the current player is the AI
func is_ai_turn(current_player_index):
	return current_player_index == 1  # AI is player 2 (index 1)

# Handle AI base placement
func handle_base_placement():
	if ai_turn_in_progress:
		return
	
	ai_turn_in_progress = true
	emit_signal("ai_action_started")
	
	# Show AI is thinking
	if ui_manager:
		ui_manager.show_ai_thinking()
	
	# Connect to completion signal
	if ai_opponent.is_connected("thinking_completed", Callable(self, "_on_base_placement_completed")):
		ai_opponent.disconnect("thinking_completed", Callable(self, "_on_base_placement_completed"))
		
	ai_opponent.connect("thinking_completed", Callable(self, "_on_base_placement_completed"), CONNECT_ONE_SHOT)
	
	# Start AI base placement
	ai_opponent.perform_base_placement()

# Handle AI base placement completion
func _on_base_placement_completed():
	ai_turn_in_progress = false
	emit_signal("ai_action_completed", AIAction.BASE_PLACEMENT)

# Handle AI weapon placement
func handle_weapon_placement():
	if ai_turn_in_progress:
		return
	
	ai_turn_in_progress = true
	emit_signal("ai_action_started")
	
	# Show AI is thinking
	if ui_manager:
		ui_manager.show_ai_thinking()
	
	# Connect to completion signal
	if ai_opponent.is_connected("thinking_completed", Callable(self, "_on_weapon_placement_completed")):
		ai_opponent.disconnect("thinking_completed", Callable(self, "_on_weapon_placement_completed"))
		
	ai_opponent.connect("thinking_completed", Callable(self, "_on_weapon_placement_completed"), CONNECT_ONE_SHOT)
	
	# Start AI weapon placement
	ai_opponent.perform_weapon_placement()

# Handle AI weapon placement completion
func _on_weapon_placement_completed():
	ai_turn_in_progress = false
	emit_signal("ai_action_completed", AIAction.WEAPON_PLACEMENT)

# Handle AI targeting
func handle_targeting():
	if ai_turn_in_progress:
		return
		
	ai_turn_in_progress = true
	emit_signal("ai_action_started")
	
	# Show AI is thinking
	if ui_manager:
		ui_manager.show_ai_thinking()
	
	# Connect to completion signal
	if ai_opponent.is_connected("thinking_completed", Callable(self, "_on_targeting_completed")):
		ai_opponent.disconnect("thinking_completed", Callable(self, "_on_targeting_completed"))
		
	ai_opponent.connect("thinking_completed", Callable(self, "_on_targeting_completed"), CONNECT_ONE_SHOT)
	
	# Start AI targeting and get the results
	var targeting_result = ai_opponent.perform_targeting()
	
	# Return the targeting result for processing
	return targeting_result

# Handle AI targeting completion
func _on_targeting_completed():
	ai_turn_in_progress = false
	emit_signal("ai_action_completed", AIAction.TARGETING)

# Check if AI is currently processing
func is_thinking():
	return ai_turn_in_progress

# Block player input (call this from _input method)
func block_input_if_needed(event, current_player_index):
	# If it's AI's turn or AI is thinking, block input
	if current_player_index == 1 or ai_turn_in_progress:
		get_viewport().set_input_as_handled()
		return true
	return false
