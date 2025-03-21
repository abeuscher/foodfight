extends Control

# Signals
signal animation_completed

# UI elements
var label
var animation_player

# State tracking
var is_animating = false
var animation_queue = []

func _ready():
	# Find components more robustly
	label = find_child("Label", true)
	animation_player = find_child("AnimationPlayer", true)
	
	# Create label if it doesn't exist
	if not label:
		label = Label.new()
		label.name = "TitleLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Create container hierarchy if needed
		var panel = find_child("Panel", true)
		if not panel:
			panel = Panel.new()
			panel.name = "Panel"
			add_child(panel)
			
		panel.add_child(label)
	
	# Hide initially
	visible = false

# Show a title with animation
func show_title(title_text):
	# Print debug to verify the method is called
	print("TitleScreen: Showing title: " + title_text)
	
	# Set the text
	if label:
		label.text = title_text
	
	# Queue this animation if another is playing
	if is_animating:
		animation_queue.push_back(title_text)
		return
	
	# Show the panel
	visible = true
	is_animating = true
	
	# Play the animation
	if animation_player:
		# Reset to start state
		animation_player.stop()
		animation_player.play("show_title")
		
		# Connect to animation finished signal if not already
		if !animation_player.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
			animation_player.animation_finished.connect(_on_animation_finished)
	else:
		# Fallback if no animation player
		print("TitleScreen ERROR: No animation player available")
		await get_tree().create_timer(2.0).timeout
		_on_animation_finished("")

# Handle animation completion
func _on_animation_finished(anim_name):
	is_animating = false
	
	# Hide the panel
	visible = false
	
	# Emit completion signal
	emit_signal("animation_completed")
	
	# Process next queued animation if any
	if animation_queue.size() > 0:
		var next_title = animation_queue.pop_front()
		call_deferred("show_title", next_title)

# Force show for a specific duration (useful for testing)
func show_for_duration(title_text, duration):
	if label:
		label.text = title_text
	
	visible = true
	
	await get_tree().create_timer(duration).timeout
	
	visible = false
	emit_signal("animation_completed")
