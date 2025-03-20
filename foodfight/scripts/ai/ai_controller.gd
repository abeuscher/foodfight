extends Node

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

func initialize(p_ai_opponent, p_ui_manager, p_phase_manager, p_player_manager):
	ai_opponent = p_ai_opponent
	ui_manager = p_ui_manager
	phase_manager = p_phase_manager
	player_manager = p_player_manager
	
	# Try to get a direct reference to the ai_ui_manager
	if ui_manager:
		if ui_manager.has_method("show_ai_thinking"):
			ai_ui_manager = ui_manager
		elif "ai_ui_manager" in ui_manager:
			ai_ui_manager = ui_manager.ai_ui_manager
		elif ui_manager.get_parent() and "ai_ui_manager" in ui_manager.get_parent():
			ai_ui_manager = ui_manager.get_parent().ai_ui_manager
	
	ai_initialized = true
	return self

# Check if the current player is the AI
func is_ai_turn():
	if !player_manager:
		return false
	return player_manager.is_current_player_ai()

# Process AI turn if needed
func process_ai_turn_if_needed():
	if !phase_manager:
		return false
	
	# Handle different states
	match phase_manager.current_phase:
		phase_manager.Phase.BASE_PLACEMENT:
			handle_base_placement()
			return true
			
		phase_manager.Phase.WEAPON_PLACEMENT:
			handle_weapon_placement()
			return true
			
		phase_manager.Phase.TARGETING:
			handle_targeting()
			return true
	
	return false

# Show AI thinking indicator safely
func _show_ai_thinking():
	if ai_ui_manager:
		ai_ui_manager.show_ai_thinking()

# Hide AI thinking indicator safely
func _hide_ai_thinking():
	if ai_ui_manager:
		ai_ui_manager.hide_ai_thinking()

# Handle AI base placement
func handle_base_placement():
	emit_signal("ai_action_started")
	if ai_turn_in_progress:
		return
	
	ai_turn_in_progress = true
	
	# Show AI is thinking
	_show_ai_thinking()
	
	# Connect to completion signal
	if ai_opponent.is_connected("thinking_completed", Callable(self, "_on_base_placement_completed")):
		ai_opponent.disconnect("thinking_completed", Callable(self, "_on_base_placement_completed"))
		
	ai_opponent.connect("thinking_completed", Callable(self, "_on_base_placement_completed"), CONNECT_ONE_SHOT)
	
	# Start AI base placement
	var placement_result = ai_opponent.perform_base_placement()
	if !placement_result:
		get_tree().create_timer(2.0).timeout.connect(func():
			if ai_turn_in_progress:
				call_deferred("_on_base_placement_completed")
		)

# Handle AI base placement completion
func _on_base_placement_completed():
	ai_turn_in_progress = false
	_hide_ai_thinking()
	emit_signal("ai_action_completed")
	
	# Notify PhaseManager directly
	if phase_manager:
		phase_manager.base_placement_completed(player_manager.current_player_index)

# Handle AI weapon placement
func handle_weapon_placement():
	emit_signal("ai_action_started")
	if ai_turn_in_progress:
		return
	
	ai_turn_in_progress = true
	
	# Show AI is thinking
	_show_ai_thinking()
	
	# Connect to completion signal
	if ai_opponent.is_connected("thinking_completed", Callable(self, "_on_weapon_placement_completed")):
		ai_opponent.disconnect("thinking_completed", Callable(self, "_on_weapon_placement_completed"))
		
	ai_opponent.connect("thinking_completed", Callable(self, "_on_weapon_placement_completed"), CONNECT_ONE_SHOT)
	
	# Start AI weapon placement
	var placement_result = ai_opponent.perform_weapon_placement()
	if !placement_result:
		get_tree().create_timer(3.0).timeout.connect(func():
			if ai_turn_in_progress:
				call_deferred("_on_weapon_placement_completed")
		)

# Handle AI weapon placement completion
func _on_weapon_placement_completed():
	ai_turn_in_progress = false
	_hide_ai_thinking()
	emit_signal("ai_action_completed")
	
	# Notify PhaseManager directly
	if phase_manager:
		phase_manager.weapon_placement_completed(player_manager.current_player_index)

# Handle AI targeting
func handle_targeting():
	emit_signal("ai_action_started")
	if ai_turn_in_progress:
		return
	
	ai_turn_in_progress = true
	
	# Show AI is thinking
	_show_ai_thinking()
	
	# Connect to completion signal
	if ai_opponent.is_connected("thinking_completed", Callable(self, "_on_targeting_completed")):
		ai_opponent.disconnect("thinking_completed", Callable(self, "_on_targeting_completed"))
		
	ai_opponent.connect("thinking_completed", Callable(self, "_on_targeting_completed"), CONNECT_ONE_SHOT)
	
	# Start AI targeting
	var targeting_result = ai_opponent.perform_targeting()
	if targeting_result:
		pass # No action needed if targeting succeeds
	else:
		call_deferred("_on_targeting_completed")

# Handle AI targeting completion
func _on_targeting_completed():
	ai_turn_in_progress = false
	_hide_ai_thinking()
	emit_signal("ai_action_completed")
	
	# Notify PhaseManager directly
	if phase_manager:
		phase_manager.targeting_completed(player_manager.current_player_index)

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
