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
var targeting_buttons_container
var end_placement_button
var end_targeting_button

# Reference to components
var weapon_placement
var player_manager
var weapon_manager
var targeting_state
var targeting_manager
var main_scene

# Initialization flag
var is_initialized = false

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Get reference to main scene
	main_scene = get_parent()
	
	# Get references to UI elements
	if main_scene.has_node("UI/TopBar/HBoxContainer/Player1Container/NameLabel"):
		player1_name_label = main_scene.get_node("UI/TopBar/HBoxContainer/Player1Container/NameLabel")
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/Player2Container/NameLabel"):
		player2_name_label = main_scene.get_node("UI/TopBar/HBoxContainer/Player2Container/NameLabel")
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel"):
		player1_score_label = main_scene.get_node("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel")
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel"):
		player2_score_label = main_scene.get_node("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel")
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel"):
		turn_label = main_scene.get_node("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel")
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel"):
		phase_label = main_scene.get_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/ResourceContainer/ResourceLabel"):
		resource_label = main_scene.get_node("UI/TopBar/HBoxContainer/ResourceContainer/ResourceLabel")
	
	if main_scene.has_node("UI/BottomBar/WeaponButtonsContainer"):
		weapon_buttons_container = main_scene.get_node("UI/BottomBar/WeaponButtonsContainer")
	
	if main_scene.has_node("UI/BottomBar/EndPlacementButton"):
		end_placement_button = main_scene.get_node("UI/BottomBar/EndPlacementButton")
	
	if main_scene.has_node("UI/BottomBar/TargetingButtonsContainer"):
		targeting_buttons_container = main_scene.get_node("UI/BottomBar/TargetingButtonsContainer")
	
	if main_scene.has_node("UI/BottomBar/EndTargetingButton"):
		end_targeting_button = main_scene.get_node("UI/BottomBar/EndTargetingButton")
	
	# Get references to other nodes
	if main_scene.has_node("WeaponPlacement"):
		weapon_placement = main_scene.get_node("WeaponPlacement")
	
	if main_scene.has_node("PlayerManager"):
		player_manager = main_scene.get_node("PlayerManager")
	
	is_initialized = true
	print("UI Manager initialized")

# Ensure we have all needed GameManager components
func _ensure_game_components():
	if GameManager:
		if !weapon_manager:
			weapon_manager = GameManager.weapon_manager
			print("UIManager: Got weapon_manager from GameManager")
			
		if !targeting_state:
			targeting_state = GameManager.targeting_state
			print("UIManager: Got targeting_state from GameManager")
			
		if !targeting_manager:
			targeting_manager = GameManager.targeting_manager
			print("UIManager: Got targeting_manager from GameManager")

# Handle player turn started in targeting phase
func handle_player_turn_started(player_id):
	print("GameUIManager: Player turn started for Player ", player_id + 1)
	
	# Make sure we have all needed components
	_ensure_game_components()
	
	# Check if we have all necessary components
	if !is_initialized or !targeting_buttons_container:
		print("GameUIManager: Missing UI components for player turn")
		return
		
	if !weapon_manager:
		print("GameUIManager: Missing weapon_manager for player turn")
		return
	
	print("GameUIManager: Creating buttons for Player ", player_id + 1)
	
	# Clear existing buttons
	for child in targeting_buttons_container.get_children():
		child.queue_free()
	
	# Get player's weapons
	var weapons = weapon_manager.get_player_weapons(player_id)
	print("GameUIManager: Found ", weapons.size(), " weapons for Player ", player_id + 1)
	
	# Create a button for each weapon
	for weapon in weapons:
		var button = Button.new()
		button.text = weapon.data.name
		button.tooltip_text = "Range: " + str(weapon.data.attack_range) + "\n" + \
						   "Damage: " + str(weapon.data.damage) + "\n" + \
						   "Splash: " + str(weapon.data.splash_radius)
		
		# Connect button press to callback in main
		button.pressed.connect(func(): main_scene._on_targeting_button_pressed(weapon, player_id))
		
		# Add to container
		targeting_buttons_container.add_child(button)
	
	# Make container visible
	targeting_buttons_container.visible = true
	
	# Update turn label to show current player
	if turn_label:
		turn_label.text = "Player " + str(player_id + 1) + "'s Turn"
	
	# Update phase label to show remaining attacks
	if phase_label:
		phase_label.text = "Targeting Phase (3 targets left)"
	
	# Make sure end targeting button is visible
	if end_targeting_button:
		end_targeting_button.visible = true
		end_targeting_button.text = "End Player " + str(player_id + 1) + "'s Targeting"

# Update UI based on game state
func update_ui(current_state, current_player_index):
	if !is_initialized:
		print("Warning: UI Manager not fully initialized")
		return
	
	print("GameUIManager: Updating UI - State: ", current_state, ", Player: ", current_player_index + 1)
	
	# Ensure we have game components
	_ensure_game_components()
	
	var game_state_machine = main_scene.get_node("GameStateMachine")
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
			game_state_machine.GameState.TARGETING:
				phase_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))  # Orange for targeting
			game_state_machine.GameState.ATTACK:
				phase_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))  # Red for attack
			game_state_machine.GameState.RESOLUTION:
				phase_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.8))  # Purple for resolution
	
	# Update resource label if in placement phase
	if resource_label and weapon_placement:
		if current_state == game_state_machine.GameState.PLACEMENT:
			resource_label.text = "Resources: " + str(weapon_placement.get_player_resources(current_player_index))
		else:
			resource_label.text = "Resources: -"
	
	# Show/hide UI elements based on game state
	update_ui_visibility(current_state, current_player_index)

# Update visibility of UI elements based on game state
func update_ui_visibility(current_state, current_player_index):
	var game_state_machine = main_scene.get_node("GameStateMachine")
	
	# Show/hide weapon buttons based on game state
	if weapon_buttons_container:
		weapon_buttons_container.visible = (current_state == game_state_machine.GameState.PLACEMENT)
	
	# Show/hide targeting buttons based on game state
	if targeting_buttons_container:
		targeting_buttons_container.visible = (current_state == game_state_machine.GameState.TARGETING)
	
	# Show/hide end placement button
	if end_placement_button and player_manager:
		end_placement_button.visible = (current_state == game_state_machine.GameState.PLACEMENT)
		if current_state == game_state_machine.GameState.PLACEMENT:
			# Make it more visible by bringing it to front and styling it
			end_placement_button.z_index = 1
			end_placement_button.modulate = Color(1, 0.8, 0.2)  # Gold color to stand out
			
			# Update button text to show which player is ending placement
			end_placement_button.text = "End " + player_manager.get_current_player_name() + "'s Placement"
	
	# Show/hide end targeting button
	if end_targeting_button and player_manager:
		end_targeting_button.visible = (current_state == game_state_machine.GameState.TARGETING)
		if current_state == game_state_machine.GameState.TARGETING:
			# Make it more visible by bringing it to front and styling it
			end_targeting_button.z_index = 1
			end_targeting_button.modulate = Color(1, 0.8, 0.2)  # Gold color to stand out
			
			# Update button text to show which player is ending targeting
			end_targeting_button.text = "End " + player_manager.get_current_player_name() + "'s Targeting"

# Update resource display
func update_resource_display(player_id, amount):
	if !is_initialized or !resource_label or !player_manager:
		return
		
	if player_id == player_manager.current_player_index:
		resource_label.text = "Resources: " + str(amount)
