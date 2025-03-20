extends RefCounted
class_name NullService

# Null object pattern implementation for services
# Returns null for any property access - renamed to avoid conflicts with _get
func safe_get_property(property):
	push_warning("Attempted to access property '" + property + "' on NullService")
	return null

# Returns null for any method call - renamed to avoid conflicts with _call
func safe_call_method(method, args):
	push_warning("Attempted to call method '" + method + "' on NullService")
	return null

# No-op implementation for commonly used methods
func safe_connect(signal_name, callable, flags=0):
	push_warning("Attempted to connect signal '" + signal_name + "' on NullService")
	return OK

func safe_emit_signal(signal_name, args=null):
	push_warning("Attempted to emit signal '" + signal_name + "' on NullService")
	return
	
# Renamed to avoid conflict with Object.has_method()
func safe_has_method(_method):
	push_warning("Attempted to call has_method on NullService")
	return false

# Common UI-related methods
func update_ui(state=null, player_index=null):
	push_warning("Attempted to call update_ui on NullService")
	return false

# Add missing phase UI method
func update_phase_ui(state=null, player_index=null):
	push_warning("Attempted to call update_phase_ui on NullService")
	return false

func update_game_phase(phase_text=null):
	push_warning("Attempted to call update_game_phase on NullService")
	return false

func handle_player_turn_update(_player_index):
	push_warning("Attempted to call handle_player_turn_update on NullService")
	return

func show_ai_thinking():
	push_warning("Attempted to call show_ai_thinking on NullService")
	return

func hide_ai_thinking():
	push_warning("Attempted to call hide_ai_thinking on NullService")
	return

func update_player_ui(_player_index):
	push_warning("Attempted to call update_player_ui on NullService")
	return

# Common game state methods
func initialize(arg1=null, arg2=null, arg3=null, arg4=null, arg5=null):
	push_warning("Attempted to call initialize on NullService")
	return false

func start_game():
	push_warning("Attempted to call start_game on NullService")
	return

func get_current_state():
	push_warning("Attempted to call get_current_state on NullService")
	return -1

func set_single_player_mode(_is_single_player):
	push_warning("Attempted to call set_single_player_mode on NullService")
	return

func update(delta=null):
	push_warning("Attempted to call update on NullService")
	return false

func cleanup():
	push_warning("Attempted to call cleanup on NullService")
	return false

# Common weapon and targeting methods
func get_weapon_data(_weapon_id):
	push_warning("Attempted to call get_weapon_data on NullService")
	return null

func get_selected_weapon():
	push_warning("Attempted to call get_selected_weapon on NullService")
	return null

func can_target(_x, _y):
	push_warning("Attempted to call can_target on NullService")
	return false

# Common board methods
func get_cell(_x, _y):
	push_warning("Attempted to call get_cell on NullService")
	return null

func is_valid_position(_x, _y):
	push_warning("Attempted to call is_valid_position on NullService")
	return false

# Common UI manager methods
func update_current_turn(player_name=null):
	push_warning("Attempted to call update_current_turn on NullService")
	return false

func show_game_over(winning_player=null):
	push_warning("Attempted to call show_game_over on NullService")
	return false

# Common event-related methods
func emit_event(event_name=null, event_data=null):
	push_warning("Attempted to call emit_event on NullService")
	return false

func subscribe(event_name=null, listener=null):
	push_warning("Attempted to call subscribe on NullService")
	return false

func unsubscribe(event_name=null, listener=null):
	push_warning("Attempted to call unsubscribe on NullService")
	return false
