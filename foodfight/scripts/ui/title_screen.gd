extends Panel

signal animation_completed

@onready var title_label = $VBoxContainer/TitleLabel
@onready var animation_player = $AnimationPlayer

# Initialize the title screen
func _ready():
	# Start hidden
	visible = false
	# Connect animation completed signal
	animation_player.animation_finished.connect(_on_animation_finished)

# Show the title screen with the given phase name
func show_title(phase_name):
	# Set the phase title
	title_label.text = phase_name.capitalize() + " Phase"
	
	# Make visible and play animation
	visible = true
	animation_player.play("fade_in")
	
	# Return the animation duration for timing purposes
	return animation_player.get_animation("fade_in").length

# Hide the title screen
func hide_title():
	animation_player.play("fade_out")
	# Return the animation duration for timing purposes
	return animation_player.get_animation("fade_out").length

# Called when an animation finishes
func _on_animation_finished(anim_name):
	if anim_name == "fade_out":
		visible = false
		emit_signal("animation_completed")
	elif anim_name == "fade_in":
		# After fade in, wait a moment then fade out
		await get_tree().create_timer(1.0).timeout
		hide_title()
		emit_signal("animation_completed")