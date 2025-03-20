class_name DebugUIManager
extends BaseUIListener

var debug_logs_enabled = true
var debug_overlay = null
var log_entries = []
var max_log_entries = 20

func _ready():
	super._ready()
	
	# Only create debug overlay in debug builds or if specifically enabled
	if OS.is_debug_build() or debug_logs_enabled:
		_create_debug_overlay()
	
	# Register to intercept all events
	_notification_register_events(NOTIFICATION_POSTINITIALIZE)

# Create visual debug overlay
func _create_debug_overlay():
	if debug_overlay != null:
		debug_overlay.queue_free()
	
	# Create the debug panel
	debug_overlay = Control.new()
	debug_overlay.name = "DebugOverlay"
	debug_overlay.visible = false # Hidden by default, toggle with F12
	
	# Create a semi-transparent panel
	var panel = Panel.new()
	panel.name = "Panel"
	panel.anchors_preset = Control.PRESET_FULL_RECT
	panel.self_modulate = Color(0.1, 0.1, 0.1, 0.8)
	debug_overlay.add_child(panel)
	
	# Create a title label
	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "EVENT DEBUG (F12 to hide)"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.position = Vector2(10, 10)
	debug_overlay.add_child(title_label)
	
	# Create a scrollable container for logs
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.anchors_preset = Control.PRESET_FULL_RECT
	scroll.margin_top = 40
	scroll.margin_left = 10
	scroll.margin_right = -10
	scroll.margin_bottom = -10
	debug_overlay.add_child(scroll)
	
	# Create a VBox to hold log entries
	var vbox = VBoxContainer.new()
	vbox.name = "LogEntries"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	# Add to the scene
	var root = get_tree().get_root()
	var main_node = root.get_node_or_null("Main")
	if main_node:
		main_node.add_child(debug_overlay)
	else:
		add_child(debug_overlay)
	
	print("Debug UI overlay created")

# Override _notification to handle input events
func _notification(what):
	if what == NOTIFICATION_PROCESS:
		if Input.is_action_just_pressed("ui_debug_toggle") or Input.is_key_pressed(KEY_F12):
			if debug_overlay:
				debug_overlay.visible = !debug_overlay.visible

# Log all events when in debug mode
func _notification_register_events(what):
	if what == NOTIFICATION_POSTINITIALIZE:
		# Override default methods to intercept all events using the get_all_events static method
		var events = GameEvents.get_all_events()
		for event_value in events:
			self.set("on_" + event_value, Callable(self, "_log_event").bind(event_value))

# Generic event logger that will be called for any event
func _log_event(event_data, event_name):
	if debug_logs_enabled:
		var timestamp = Time.get_ticks_msec() / 1000.0
		var log_text = "[%.2f] %s - %s" % [timestamp, event_name, str(event_data)]
		print(log_text)
		
		# Add to our log entries list
		log_entries.append({
			"timestamp": timestamp,
			"event": event_name,
			"data": event_data,
			"text": log_text
		})
		
		# Limit the number of entries
		if log_entries.size() > max_log_entries:
			log_entries.pop_front()
		
		# Update visual debug overlay if enabled
		_update_debug_overlay()

# Update the visual debug overlay with latest events
func _update_debug_overlay():
	if debug_overlay and debug_overlay.has_node("ScrollContainer/LogEntries"):
		var vbox = debug_overlay.get_node("ScrollContainer/LogEntries")
		
		# Clear existing entries
		for child in vbox.get_children():
			child.queue_free()
		
		# Add new entries (newest at top)
		for entry in log_entries:
			var label = Label.new()
			label.text = entry.text
			label.add_theme_font_size_override("font_size", 14)
			
			# Color code by event type
			if "error" in entry.event.to_lower():
				label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
			elif "warning" in entry.event.to_lower():
				label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
			elif entry.event.begins_with("ai_"):
				label.add_theme_color_override("font_color", Color(0.3, 0.8, 1))
			elif entry.event.begins_with("player_"):
				label.add_theme_color_override("font_color", Color(0.2, 1, 0.3))
			elif entry.event.begins_with("weapon_"):
				label.add_theme_color_override("font_color", Color(1, 0.5, 0.1))
				
			vbox.add_child(label)
		
		# Auto-scroll to bottom
		var scroll = debug_overlay.get_node("ScrollContainer")
		scroll.scroll_vertical = vbox.get_minimum_size().y

# Clear all log entries
func clear_logs():
	log_entries.clear()
	_update_debug_overlay()