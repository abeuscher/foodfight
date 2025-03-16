extends Node

# AI thinking indicator
var ai_thinking_label = null
var is_ai_thinking = false

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
	print("AI UI Manager initialized")
	return self

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
		print("AI thinking indicator added to bottom bar")
	else:
		print("Failed to add AI thinking indicator: Bottom bar not found")

# Show AI thinking indicator
func show_ai_thinking():
	print("AI UI Manager: Showing AI thinking in bottom bar")
	if ai_thinking_label:
		ai_thinking_label.visible = true
		is_ai_thinking = true
		# Hide other bottom bar elements while AI is thinking
		if main_scene:
			var weapon_buttons_container = main_scene.get_node_or_null("UI/BottomBar/WeaponButtonsContainer")
			var targeting_buttons_container = main_scene.get_node_or_null("UI/BottomBar/TargetingButtonsContainer")
			var end_placement_button = main_scene.get_node_or_null("UI/BottomBar/EndPlacementButton")
			var end_targeting_button = main_scene.get_node_or_null("UI/BottomBar/EndTargetingButton")
			
			if weapon_buttons_container:
				weapon_buttons_container.visible = false
			if targeting_buttons_container:
				targeting_buttons_container.visible = false
			if end_placement_button:
				end_placement_button.visible = false
			if end_targeting_button:
				end_targeting_button.visible = false

# Hide AI thinking indicator
func hide_ai_thinking():
	if ai_thinking_label:
		ai_thinking_label.visible = false
		is_ai_thinking = false
		# The normal UI update will restore appropriate controls

# Connect signals from AI opponent
func connect_ai_signals(ai_opponent):
	if ai_opponent:
		if ai_opponent.is_connected("thinking_started", Callable(self, "show_ai_thinking")):
			ai_opponent.disconnect("thinking_started", Callable(self, "show_ai_thinking"))
		if ai_opponent.is_connected("thinking_completed", Callable(self, "hide_ai_thinking")):
			ai_opponent.disconnect("thinking_completed", Callable(self, "hide_ai_thinking"))
		
		# Connect AI signals
		ai_opponent.connect("thinking_started", Callable(self, "show_ai_thinking"))
		ai_opponent.connect("thinking_completed", Callable(self, "hide_ai_thinking"))