extends Node

# Phase UI elements
var turn_label
var phase_label
var title_screen

# Dependencies
var player_manager

# Initialization flag
var is_initialized = false

# Signal for title screen animation completion
signal title_screen_completed

# Initialize with UI elements
func initialize(p_turn_label, p_phase_label, p_title_screen, p_player_manager):
	turn_label = p_turn_label
	phase_label = p_phase_label
	title_screen = p_title_screen
	player_manager = p_player_manager
	
	if title_screen:
		title_screen.animation_completed.connect(_on_title_screen_animation_completed)
	
	is_initialized = true
	print("Phase UI Manager initialized")
	return self

# Handle title screen animation completed
func _on_title_screen_animation_completed():
	emit_signal("title_screen_completed")

# Show title screen for upcoming phase
func show_phase_title(phase_name):
	if !is_initialized:
		print("PhaseUIManager: Title screen not available")
		emit_signal("title_screen_completed")
		return
	
	print("PhaseUIManager: Showing title for phase: " + phase_name)
	if title_screen:
		title_screen.visible = true
		title_screen.show_title(phase_name)
	else:
		print("ERROR: No title screen found!")
		emit_signal("title_screen_completed")

# Update phase UI
func update_phase_ui(current_state, current_player_index):
	if !is_initialized:
		return
	
	# Get the game state machine
	var game_state_machine = get_node("/root/GameManager").game_state_machine if Engine.has_singleton("GameManager") else null
	if !game_state_machine:
		return
	
	# Update turn label with visual styling
	if turn_label and player_manager:
		turn_label.text = player_manager.get_current_player_name() + "'s Turn"
		
	# Update phase label with visual styling
	if phase_label:
		var phase_text = game_state_machine.GameState.keys()[current_state].capitalize().replace("_", " ") + " Phase"
		phase_label.text = phase_text
		
		# Highlight the phase label based on current state
		phase_label.remove_theme_color_override("font_color")  # Clear previous override
		
		match current_state:
			game_state_machine.GameState.UNINITIALIZED:
				phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			game_state_machine.GameState.START_SCREEN:
				phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))
			game_state_machine.GameState.BASE_PLACEMENT:
				phase_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8))
			game_state_machine.GameState.WEAPON_PLACEMENT:
				phase_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
			game_state_machine.GameState.TARGETING:
				phase_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))
			game_state_machine.GameState.ATTACK_RESOLUTION:
				phase_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			game_state_machine.GameState.GAME_OVER:
				phase_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.8))

# Update the game phase label
func update_game_phase(phase_text):
	if phase_label:
		phase_label.text = phase_text

# Update current turn label
func update_current_turn(player_name):
	if turn_label:
		turn_label.text = player_name + "'s Turn"

# Show game over screen
func show_game_over(winning_player):
	var winner_name = "Player 1"
	
	if player_manager:
		winner_name = player_manager.get_player_name(winning_player)
	
	# Create game over message
	var game_over_message = Label.new()
	game_over_message.name = "GameOverMessage"
	game_over_message.text = winner_name + " wins!"
	game_over_message.add_theme_color_override("font_color", Color(1, 0.8, 0))
	game_over_message.add_theme_font_size_override("font_size", 36)
	game_over_message.position = Vector2(400, 300)
	
	# Add to UI
	var ui_container = get_tree().get_root().get_node("Main/UI")
	if ui_container:
		ui_container.add_child(game_over_message)