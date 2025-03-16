extends Node

signal ai_action_started
signal ai_action_completed(action_type)

# AI turn tracking
var ai_turn_in_progress = false
var ai_initialized = false

# References to game components
var ai_opponent
var ui_manager
var game_state_machine
var player_manager

# AI action types
enum AIAction {BASE_PLACEMENT, WEAPON_PLACEMENT, TARGETING}

func initialize(p_ai_opponent, p_ui_manager, p_game_state_machine, p_player_manager):
	ai_opponent = p_ai_opponent
	ui_manager = p_ui_manager
	game_state_machine = p_game_state_machine
	player_manager = p_player_manager
	ai_initialized = true
	print("AI Controller initialized with all components")
	return self

# Check if the current player is the AI
func is_ai_turn():
	if !player_manager:
		return false
	return player_manager.is_current_player_ai()

# Process AI turn if needed
func process_ai_turn_if_needed():
	if !ai_initialized or !is_ai_turn():
		return false
		
	print("AI turn detected, processing actions for current state")
	
	# Handle different states
	match game_state_machine.current_state:
		game_state_machine.GameState.BASE_PLACEMENT:
			handle_base_placement()
			return true
			
		game_state_machine.GameState.WEAPON_PLACEMENT:
			handle_weapon_placement()
			return true
			
		game_state_machine.GameState.TARGETING:
			handle_targeting()
			return true
			
	return false

# Handle AI base placement
func handle_base_placement():
	if ai_turn_in_progress:
		return
	
	ai_turn_in_progress = true
	emit_signal("ai_action_started")
	
	# Show AI is thinking - works with both original and refactored UI
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
	print("DEBUG: AI base placement completed")
	ai_turn_in_progress = false
	emit_signal("ai_action_completed", AIAction.BASE_PLACEMENT)
	
	# Hide AI thinking - works with both original and refactored UI
	if ui_manager:
		ui_manager.hide_ai_thinking()
	
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
		return
	
	ai_turn_in_progress = true
	emit_signal("ai_action_started")
	
	# Show AI is thinking - works with both original and refactored UI
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
	print("DEBUG: AI weapon placement completed")
	ai_turn_in_progress = false
	emit_signal("ai_action_completed", AIAction.WEAPON_PLACEMENT)
	
	# Hide AI thinking - works with both original and refactored UI
	if ui_manager:
		ui_manager.hide_ai_thinking()
	
	# Print debug information
	print("DEBUG: Current game state before completion:", game_state_machine.current_state)
	
	# Complete placement in game state machine
	print("DEBUG: Calling game_state_machine.placement_completed")
	game_state_machine.placement_completed()
	
	# Print state after completion
	print("DEBUG: After completion - Current game state:", game_state_machine.current_state)

# Handle AI targeting
func handle_targeting():
	if ai_turn_in_progress:
		return
		
	ai_turn_in_progress = true
	emit_signal("ai_action_started")
	
	# Show AI is thinking - works with both original and refactored UI
	if ui_manager:
		ui_manager.show_ai_thinking()
	
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
	if ui_manager:
		ui_manager.hide_ai_thinking()
	
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
