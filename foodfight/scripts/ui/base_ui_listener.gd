extends Node
class_name BaseUIListener

# Base class for all UI components that listen to game events
# Provides automatic event subscription and common event handling methods

# References
var event_bus

# Initialize flag
var _events_connected = false

func _ready():
	# Try to get event bus from GameManager
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		event_bus = game_manager.get_service("EventBus")
		
		if event_bus:
			# Connect to all relevant events - automatic registration based on methods
			_connect_to_events()
		else:
			push_warning("BaseUIListener: No EventBus service available")

# Emit an event through the event bus
func emit_event(event_name, event_data = null):
	if event_bus:
		event_bus.emit_event(event_name, event_data)
	else:
		push_warning("BaseUIListener: Cannot emit event, no EventBus available")

# Connect to all events this listener can handle
func _connect_to_events():
	if _events_connected:
		return
	
	if !event_bus:
		return
	
	var connected_count = 0
	
	# Get all available events
	var all_events = GameEvents.get_all_events()
	
	# Look for corresponding handler methods
	for event_name in all_events:
		var method_name = "on_" + event_name
		if has_method(method_name):
			# Connect to the event
			event_bus.subscribe(event_name, self)
			connected_count += 1
	
	_events_connected = true
	
	if connected_count > 0:
		print(str(get_path()) + ": Connected to " + str(connected_count) + " events")

# Default implementations for common events - can be overridden
# These are stubs that can be overridden by subclasses

func on_state_changed(_event_data):
	pass
	
func on_phase_changed(_event_data):
	pass
	
func on_player_changed(_event_data):
	pass
	
func on_game_over(_event_data):
	pass
	
func on_ui_update_required(_event_data):
	pass
	
func on_ai_thinking_started(_event_data = null):
	pass
	
func on_ai_thinking_completed(_event_data = null):
	pass
