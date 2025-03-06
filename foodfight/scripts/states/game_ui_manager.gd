extends Node

# References to UI elements
var player1_name_label
var player2_name_label
var player1_score_label
var player2_score_label
var turn_label
var phase_label
var resource_label
var weapon_buttons_container
var attack_buttons_container
var end_placement_button

# Reference to components
var weapon_placement
var player_manager

# Initialization flag
var is_initialized = false

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Get references to UI elements
	var main = get_parent()
	if main.has_node("UI/TopBar/HBoxContainer/Player1Container/NameLabel"):
		player1_name_label = main.get_node("UI/TopBar/HBoxContainer/Player1Container/NameLabel")
	
	if main.has_node("UI/TopBar/HBoxContainer/Player2Container/NameLabel"):
		player2_name_label = main.get_node("UI/TopBar/HBoxContainer/Player2Container/NameLabel")
	
	if main.has_node("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel"):
		player1_score_label = main.get_node("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel")
	
	if main.has_node("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel"):
		player2_score_label = main.get_node("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel")
	
	if main.has_node("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel"):
		turn_label = main.get_node("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel")
	
	if main.has_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel"):
		phase_label = main.get_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
	
	if main.has_node("UI/TopBar/HBoxContainer/ResourceContainer/ResourceLabel"):
		resource_label = main.get_node("UI/TopBar/HBoxContainer/ResourceContainer/ResourceLabel")
	
	if main.has_node("UI/BottomBar/WeaponButtonsContainer"):
		weapon_buttons_container = main.get_node("UI/BottomBar/WeaponButtonsContainer")
	
	if main.has_node("UI/BottomBar/EndPlacementButton"):
		end_placement_button = main.get_node("UI/BottomBar/EndPlacementButton")
	
	if main.has_node("UI/BottomBar/AttackButtonsContainer"):
		attack_buttons_container = main.get_node("UI/BottomBar/AttackButtonsContainer")
	
	# Get references to other nodes
	if main.has_node("WeaponPlacement"):
		weapon_placement = main.get_node("WeaponPlacement")
	
	if main.has_node("PlayerManager"):
		player_manager = main.get_node("PlayerManager")
	
	is_initialized = true
	print("UI Manager initialized")

# Update UI based on game state
func update_ui(current_state, current_player_index):
	if !is_initialized:
		print("Warning: UI Manager not fully initialized")
		return
		
	var game_state_machine = get_parent().get_node("GameStateMachine")
	if !game_state_machine:
		print("Warning: GameStateMachine not found")
		return
	
	# Update player name labels with visual emphasis for current player
	if player1_name_label and player2_name_label:
		if current_player_index == 0:  # Player 1
			player1_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))  # Gold for active player
			player2_name_label.remove_theme_color_override("font_color")
		else:  # Player 2
			player2_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))  # Gold for active player
			player1_name_label.remove_theme_color_override("font_color")
	
	# Update score labels
	if player1_score_label and player2_score_label and player_manager:
		player1_score_label.text = "Score: " + str(player_manager.player1_score)
		player2_score_label.text = "Score: " + str(player_manager.player2_score)
	
	# Update turn label
	if turn_label and player_manager:
		turn_label.text = player_manager.get_current_player_name() + "'s Turn"
	
	# Update phase label with visual styling
	if phase_label:
		var phase_text = game_state_machine.GameState.keys()[current_state].capitalize() + " Phase"
		phase_label.text = phase_text
		
		# Highlight the phase label based on current state
		match current_state:
			game_state_machine.GameState.SETUP:
				phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))  # Blue for setup
			game_state_machine.GameState.PLACEMENT:
				phase_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))  # Green for placement
			game_state_machine.GameState.ATTACK:
				phase_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))  # Red for attack
			game_state_machine.GameState.RESOLUTION:
				phase_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))  # Orange for resolution
	
	# Update resource label if in placement phase
	if resource_label and weapon_placement:
		if current_state == game_state_machine.GameState.PLACEMENT:
			resource_label.text = "Resources: " + str(weapon_placement.get_player_resources(current_player_index))
		else:
			resource_label.text = "Resources: -"
	
	# Show/hide weapon buttons based on game state
	if weapon_buttons_container:
		weapon_buttons_container.visible = (current_state == game_state_machine.GameState.PLACEMENT)
	
	# Show/hide attack buttons based on game state
	if attack_buttons_container:
		attack_buttons_container.visible = (current_state == game_state_machine.GameState.ATTACK)
	
	# Show/hide end placement button
	if end_placement_button and player_manager:
		end_placement_button.visible = (current_state == game_state_machine.GameState.PLACEMENT)
		if current_state == game_state_machine.GameState.PLACEMENT:
			# Make it more visible by bringing it to front and styling it
			end_placement_button.z_index = 1
			end_placement_button.modulate = Color(1, 0.8, 0.2)  # Gold color to stand out
			
			# Update button text to show which player is ending placement
			end_placement_button.text = "End " + player_manager.get_current_player_name() + "'s Placement"

# Connect the end placement button
func connect_end_placement_button(callback):
	if !is_initialized:
		await _ready()
	
	if end_placement_button and !end_placement_button.is_connected("pressed", callback):
		end_placement_button.pressed.connect(callback)
		print("End placement button connected")
	else:
		print("Warning: Could not connect end placement button")

# Update resource display
func update_resource_display(player_id, amount):
	if !is_initialized or !resource_label or !player_manager:
		return
		
	if player_id == player_manager.current_player_index:
		resource_label.text = "Resources: " + str(amount)

# Create attack buttons
func create_attack_buttons(player_id, weapons_data, weapon_select_callback):
	if !is_initialized or !attack_buttons_container:
		return
	
	# Clear existing buttons
	for child in attack_buttons_container.get_children():
		child.queue_free()
	
	# Create a button for each weapon
	for weapon in weapons_data:
		var button = Button.new()
		button.text = weapon.data.name
		button.tooltip_text = "Range: " + str(weapon.data.attack_range) + "\n" + \
							  "Damage: " + str(weapon.data.damage) + "\n" + \
							  "Splash: " + str(weapon.data.splash_radius)
		
		# Connect button press to callback
		button.pressed.connect(func(): weapon_select_callback.call(weapon, player_id))
		
		# Add to container
		attack_buttons_container.add_child(button)