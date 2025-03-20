extends BaseUIListener

# AI thinking indicator
var ai_thinking_label = null
var is_ai_thinking = false
var blink_timer = null

# Main scene reference
var main_scene

# Initialization flag
var is_initialized = false

# Initialize with UI elements
func initialize(p_main_scene):
	main_scene = p_main_scene
	
	# Create AI thinking indicator
	create_ai_thinking_indicator()
	
	is_initialized = true
	return self

# Event handlers
func on_ai_thinking_started(_event_data = null):
	show_ai_thinking()
	
func on_ai_thinking_completed(_event_data = null):
	hide_ai_thinking()
	
func on_player_changed(event_data):
	# If it's player 2's turn (AI), show thinking indicator
	if event_data.player_index == 1:
		show_ai_thinking()
	else:
		hide_ai_thinking()

# Create a thinking indicator for AI turns
func create_ai_thinking_indicator():
	# We'll use a label in the bottom bar instead of a panel
	if ai_thinking_label != null:
		ai_thinking_label.queue_free()
		
	# Create a new label for the bottom bar
	ai_thinking_label = Label.new()
	ai_thinking_label.name = "AIThinkingLabel"
	ai_thinking_label.text = "AI OPPONENT IS THINKING..."
	ai_thinking_label.add_theme_font_size_override("font_size", 24)
	ai_thinking_label.add_theme_color_override("font_color", Color(1, 0.2, 0))
	ai_thinking_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ai_thinking_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ai_thinking_label.visible = false
	
	# Add to bottom bar
	if main_scene and main_scene.has_node("UI/BottomBar"):
		var bottom_bar = main_scene.get_node("UI/BottomBar")
		bottom_bar.add_child(ai_thinking_label)
		# Make it fill the bottom bar
		ai_thinking_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ai_thinking_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ai_thinking_label.anchors_preset = Control.PRESET_FULL_RECT
	else:
		print("Failed to add AI thinking indicator: Bottom bar not found")

# Show AI thinking indicator
func show_ai_thinking():
	if !is_initialized:
		return
		
	if ai_thinking_label:
		ai_thinking_label.visible = true
		is_ai_thinking = true
		
		# Make the AI thinking more noticeable with blinking
		start_blink_animation()
		
		# Hide other bottom bar elements while AI is thinking
		hide_other_ui_elements(true)
		
		 # REMOVED: This event emission was causing the recursive loop
		# emit_event(GameEvents.AI_THINKING_STARTED)

# Start blinking animation
func start_blink_animation():
	# Cancel any existing timer
	if blink_timer and blink_timer.timeout.is_connected(_on_blink_timer_timeout):
		blink_timer.timeout.disconnect(_on_blink_timer_timeout)
		blink_timer = null
	
	# Start new blinking cycle
	blink_timer = get_tree().create_timer(0.5)
	blink_timer.timeout.connect(_on_blink_timer_timeout)

# Handle the timer timeout for blinking
func _on_blink_timer_timeout():
	if is_ai_thinking and ai_thinking_label and ai_thinking_label.visible:
		var current_color = ai_thinking_label.get_theme_color("font_color")
		var new_color = Color(1, 0.2, 0) if current_color.r < 0.5 else Color(1, 0.6, 0)
		ai_thinking_label.add_theme_color_override("font_color", new_color)
		
		# Continue blinking if still thinking
		if is_ai_thinking:
			start_blink_animation()

# Hide or show other UI elements
func hide_other_ui_elements(should_hide):
	if !main_scene:
		return
		
	var weapon_buttons_container = main_scene.get_node_or_null("UI/BottomBar/WeaponButtonsContainer")
	var targeting_buttons_container = main_scene.get_node_or_null("UI/BottomBar/TargetingButtonsContainer")
	var end_placement_button = main_scene.get_node_or_null("UI/BottomBar/EndPlacementButton")
	var end_targeting_button = main_scene.get_node_or_null("UI/BottomBar/EndTargetingButton")
	
	if weapon_buttons_container:
		weapon_buttons_container.visible = !should_hide
	if targeting_buttons_container:
		targeting_buttons_container.visible = !should_hide
	if end_placement_button:
		end_placement_button.visible = !should_hide
	if end_targeting_button:
		end_targeting_button.visible = !should_hide

# Hide AI thinking indicator
func hide_ai_thinking():
	if !is_initialized:
		return
		
	if ai_thinking_label:
		ai_thinking_label.visible = false
		is_ai_thinking = false
		
		# Show other UI elements again
		hide_other_ui_elements(false)
		
		# Stop blinking
		if blink_timer and blink_timer.timeout.is_connected(_on_blink_timer_timeout):
			blink_timer.timeout.disconnect(_on_blink_timer_timeout)
			blink_timer = null
		
		 # REMOVED: This event emission was causing the recursive loop
		# emit_event(GameEvents.AI_THINKING_COMPLETED)

# Connect signals from AI opponent - legacy method preserved for backward compatibility
func connect_ai_signals(ai_opponent):
	if !is_initialized:
		return
		
	if ai_opponent:
		# First disconnect any existing connections to avoid duplicates
		if ai_opponent.is_connected("thinking_started", Callable(self, "show_ai_thinking")):
			ai_opponent.disconnect("thinking_started", Callable(self, "show_ai_thinking"))
		if ai_opponent.is_connected("thinking_completed", Callable(self, "hide_ai_thinking")):
			ai_opponent.disconnect("thinking_completed", Callable(self, "hide_ai_thinking"))
		
		# Connect AI signals
		ai_opponent.connect("thinking_started", Callable(self, "show_ai_thinking"))
		ai_opponent.connect("thinking_completed", Callable(self, "hide_ai_thinking"))
