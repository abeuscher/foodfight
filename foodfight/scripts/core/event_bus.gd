extends Node

class_name EventBus

# Event subscribers
var subscribers = {}

# Verbose debug mode
var verbose_debug = false

# Blocking mode properties
var blocking_mode_active = false
var queued_events = []
var allowed_events_during_blocking = ["AI_THINKING_COMPLETED", "AI_ACTION_COMPLETED"]

# Enter blocking mode - queue events instead of processing them
func enter_blocking_mode():
	print("EventBus: Entering blocking mode - events will be queued")
	blocking_mode_active = true
	
# Exit blocking mode and process any queued events
func exit_blocking_mode():
	print("EventBus: Exiting blocking mode - processing queued events")
	blocking_mode_active = false
	
	# Process queued events
	var events_to_process = queued_events.duplicate()
	queued_events.clear()
	
	for event in events_to_process:
		emit_event(event.name, event.data)

# Emit an event to all subscribers
func emit_event(event_name: String, event_data = null) -> void:
	# Ensure event_name is a string (handle constants)
	if typeof(event_name) != TYPE_STRING:
		event_name = str(event_name)
	
	# Handle blocking mode - queue events instead of processing them
	if blocking_mode_active and not event_name in allowed_events_during_blocking:
		if verbose_debug:
			print("EventBus: Event " + event_name + " queued (blocking mode active)")
		queued_events.append({"name": event_name, "data": event_data})
		return
		
	if verbose_debug:
		print("EventBus: Emitting event: " + event_name)
		
	if not event_name in subscribers:
		if verbose_debug:
			print("EventBus: No subscribers for event: " + event_name)
		return
	
	# Create a temporary copy of subscribers to prevent modification issues
	var current_subscribers = subscribers[event_name].duplicate()
	
	for subscriber in current_subscribers:
		# Check if subscriber is still valid
		if is_instance_valid(subscriber):
			# Try both conventions: on_EVENT_NAME (exact case) and on_event_name (lowercase)
			var handler_name_exact = "on_" + event_name
			var handler_name_lower = "on_" + event_name.to_lower()
			
			if subscriber.has_method(handler_name_exact):
				# Call the event handler with exact case
				subscriber.call(handler_name_exact, event_data)
			elif subscriber.has_method(handler_name_lower):
				# Call the event handler with lowercase
				subscriber.call(handler_name_lower, event_data)
			else:
				print("EventBus WARNING: Subscriber " + subscriber.name +
					  " doesn't have handler for " + event_name +
					  " (tried " + handler_name_exact + " and " + handler_name_lower + ")")
		else:
			# Clean up invalid subscriber
			subscribers[event_name].erase(subscriber)
			print("EventBus: Removed invalid subscriber for event: " + event_name)

# Subscribe to an event
func subscribe(event_name: String, subscriber: Object) -> void:
	# Ensure event_name is a string (handle constants)
	if typeof(event_name) != TYPE_STRING:
		event_name = str(event_name)
		
	if not event_name in subscribers:
		subscribers[event_name] = []
	
	# Avoid duplicate subscriptions
	if not subscriber in subscribers[event_name]:
		subscribers[event_name].append(subscriber)
		
		if verbose_debug:
			print("EventBus: " + subscriber.name + " subscribed to " + event_name)

# Unsubscribe from an event
func unsubscribe(event_name: String, subscriber: Object) -> void:
	if not event_name in subscribers:
		return
	
	if subscriber in subscribers[event_name]:
		subscribers[event_name].erase(subscriber)

# Debug method to list all subscribers
func list_subscribers() -> void:
	print("===== EVENT BUS SUBSCRIBERS =====")
	for event in subscribers.keys():
		print("Event: " + event)
		for subscriber in subscribers[event]:
			if is_instance_valid(subscriber):
				print("  - " + subscriber.name)
			else:
				print("  - [INVALID]")
	print("=================================")

# Enable verbose debug output
func enable_verbose_debug() -> void:
	verbose_debug = true
	print("EventBus: Verbose debug enabled")
