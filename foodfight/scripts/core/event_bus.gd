class_name EventBus
extends Node

# Dictionary to store signal connections
# Format: { "event_name": [array_of_listeners] }
var _listeners = {}

# Debug properties
var debug_mode = false
var debug_event_history = []
var max_history_size = 50

# Tracking variables for cycle detection
var _cycle_detection_enabled = false # Renamed from enable_cycle_detection
var _current_event_chain = []
var _max_chain_length = 10

# Emit an event with optional arguments
func emit_event(event_name: String, args = null) -> void:
	if debug_mode:
		_log_event(event_name, args)
	
	# Check for event cycles
	if _cycle_detection_enabled: # Updated variable name
		_current_event_chain.append(event_name)
		if _current_event_chain.size() > _max_chain_length:
			push_warning("EventBus: Excessive event chain length detected! Chain: " + str(_current_event_chain))
			_current_event_chain.clear()
			return
		
		# Check for direct cycle patterns
		if _current_event_chain.size() >= 3:
			var last_three = _current_event_chain.slice(-3)
			if last_three[0] == last_three[2]:
				push_warning("EventBus: Circular event pattern detected: " + str(last_three))
				_current_event_chain.clear()
				return
	
	if not _listeners.has(event_name):
		if debug_mode:
			print("EventBus: No listeners for event " + event_name)
			
		# Reset event chain after emission completes
		if _cycle_detection_enabled: # Updated variable name
			_current_event_chain.pop_back()
			
		return
	
	var listener_count = 0
	for listener in _listeners[event_name]:
		if is_instance_valid(listener):
			if args is Dictionary:
				listener.callv("on_" + event_name, [args])
			else:
				listener.call("on_" + event_name)
			listener_count += 1
		else:
			# Remove invalid listeners
			_listeners[event_name].erase(listener)
			if debug_mode:
				print("EventBus: Removed invalid listener for " + event_name)
	
	if debug_mode:
		print("EventBus: Event " + event_name + " delivered to " + str(listener_count) + " listeners")
	
	# Reset event chain after emission completes
	if _cycle_detection_enabled: # Updated variable name
		_current_event_chain.pop_back()

# Subscribe to an event
func subscribe(event_name: String, listener: Object) -> bool:
	if not listener.has_method("on_" + event_name):
		push_warning("Listener does not implement method 'on_" + event_name + "'")
		return false
	
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	
	if not _listeners[event_name].has(listener):
		_listeners[event_name].append(listener)
		
		if debug_mode:
			print("EventBus: " + str(listener.get_path()) + " subscribed to " + event_name)
		
		return true
	
	if debug_mode:
		print("EventBus: " + str(listener.get_path()) + " already subscribed to " + event_name)
	
	return false

# Unsubscribe from an event
func unsubscribe(event_name: String, listener: Object) -> bool:
	if not _listeners.has(event_name):
		return false
		
	var idx = _listeners[event_name].find(listener)
	if idx >= 0:
		_listeners[event_name].remove_at(idx)
		
		if debug_mode:
			print("EventBus: " + str(listener.get_path()) + " unsubscribed from " + event_name)
			
		return true
		
	return false

# Unsubscribe from all events
func unsubscribe_all(listener: Object) -> void:
	var unsubscribed_count = 0
	
	for event_name in _listeners.keys():
		if unsubscribe(event_name, listener):
			unsubscribed_count += 1
			
	if debug_mode and unsubscribed_count > 0:
		print("EventBus: " + str(listener.get_path()) + " unsubscribed from " + str(unsubscribed_count) + " events")

# Log event for debugging
func _log_event(event_name, args):
	var log_entry = {
		"timestamp": Time.get_unix_time_from_system(),
		"event": event_name,
		"args": args
	}
	
	debug_event_history.append(log_entry)
	if debug_event_history.size() > max_history_size:
		debug_event_history.pop_front()
	
	print("EventBus: " + event_name + " - " + str(args))

# Get event history for debugging
func get_event_history():
	return debug_event_history

# Enable debug mode
func enable_debug_mode(enable: bool = true):
	debug_mode = enable
	if enable:
		print("EventBus: Debug mode enabled")
	else:
		print("EventBus: Debug mode disabled")

# Clear event history
func clear_event_history():
	debug_event_history.clear()
	if debug_mode:
		print("EventBus: Event history cleared")

# Get registered listeners
func get_registered_listeners():
	var result = {}
	for event_name in _listeners.keys():
		result[event_name] = _listeners[event_name].size()
	return result

# Get listener count for an event
func get_listener_count(event_name: String) -> int:
	if not _listeners.has(event_name):
		return 0
	return _listeners[event_name].size()

# Method to dump event listener graph for debugging
func dump_event_listener_graph():
	var graph = {}
	
	for event_name in _listeners.keys():
		var valid_listeners = []
		for listener in _listeners[event_name]:
			if is_instance_valid(listener):
				valid_listeners.append(str(listener.get_path() if listener.has_method("get_path") else listener))
		
		if valid_listeners.size() > 0:
			graph[event_name] = valid_listeners
	
	print("=== EVENT LISTENER GRAPH ===")
	for event_name in graph.keys():
		print("Event: " + event_name)
		for listener in graph[event_name]:
			print("  -> " + listener)
	print("===========================")
	
	return graph

# Enable cycle detection
func enable_cycle_detection(enable: bool = true):
	_cycle_detection_enabled = enable # Updated variable name
	if debug_mode:
		print("EventBus: Cycle detection " + ("enabled" if enable else "disabled"))
