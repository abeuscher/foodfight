extends Control

# References to the name input fields
@onready var player1_input = $Panel/VBoxContainer/Player1Container/Player1Input
@onready var start_button = $Panel/VBoxContainer/StartButtonContainer/StartButton

func _ready():
	# Set focus to the first player input field when the scene loads
	player1_input.grab_focus()
	
	# Add a subtle animation for the start button
	_animate_start_button()

func _on_start_button_pressed():
	var p1_name = player1_input.text.strip_edges()
	
	# Use default names if fields are empty
	if p1_name.is_empty():
		p1_name = "Player 1"
	
	# Set player names in the global GameData singleton
	GameData.set_player_names(p1_name)
	
	# Change to the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _animate_start_button():
	# Create a subtle pulsing effect for the start button
	var tween = create_tween().set_loops()
	tween.tween_property(start_button, "scale", Vector2(1.05, 1.05), 0.8)
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.8)
