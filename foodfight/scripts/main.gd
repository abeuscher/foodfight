extends Node2D

# References to UI elements
@onready var weapon_buttons_container = $UI/BottomBar/WeaponButtonsContainer
@onready var targeting_buttons_container = $UI/BottomBar/TargetingButtonsContainer
@onready var end_placement_button = $UI/BottomBar/EndPlacementButton
@onready var end_targeting_button = $UI/BottomBar/EndTargetingButton

# State tracking
var game_initialized = false

func _ready():
	print("Main scene ready")
	print("GameManager exists: ", GameManager != null)
	
	# Wait a couple of frames to ensure scene is fully loaded
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Set up UI elements
	_setup_ui()
	
	# Initialize the game through GameManager singleton
	if GameManager:
		print("Starting game initialization through GameManager...")
		GameManager.connect("game_initialized", Callable(self, "_on_game_initialized"))
		# Add await here
		game_initialized = await GameManager.initialize_game(self)
	else:
		push_error("GameManager singleton not found")

func _on_game_initialized():
	print("Game initialization complete, starting game...")
	GameManager.start_game()

# Set up the UI elements
func _setup_ui():
	print("Setting up UI elements...")
	
	# Ensure the end placement button is properly sized and positioned
	if end_placement_button:
		end_placement_button.custom_minimum_size = Vector2(180, 40)
		end_placement_button.position = Vector2(end_placement_button.position.x, end_placement_button.position.y)
		end_placement_button.visible = false
	
	# Set up end targeting button if it exists
	if end_targeting_button:
		end_targeting_button.custom_minimum_size = Vector2(180, 40)
		end_targeting_button.visible = false
		# Connect end targeting button to targeting state handler
		end_targeting_button.pressed.connect(Callable(self, "_on_end_targeting_pressed"))
	
	if targeting_buttons_container:
		targeting_buttons_container.visible = false
	
	if weapon_buttons_container:
		weapon_buttons_container.visible = false

# Handle input events
func _input(event):
	if !game_initialized:
		return
		
	# Forward input to GameManager for handling
	var game_state_machine = GameManager.game_state_machine
	var placement_state = GameManager.placement_state
	var targeting_state = GameManager.targeting_state
	
	if game_state_machine and game_state_machine.is_initialized:
		match game_state_machine.current_state:
			game_state_machine.GameState.PLACEMENT:
				if placement_state:
					placement_state.handle_input(event)
			game_state_machine.GameState.TARGETING:
				if targeting_state:
					targeting_state.handle_input(event)

# Create targeting buttons for player weapons
func create_targeting_buttons(player_id):
	if !game_initialized:
		print("Error: Game not initialized")
		return
	
	if !targeting_buttons_container:
		print("Error: Targeting buttons container not found")
		return
		
	print("Creating targeting buttons for Player", player_id + 1)
	
	var targeting_state = GameManager.targeting_state
	var weapon_manager = GameManager.weapon_manager
	
	if !targeting_state or !weapon_manager:
		print("Error: Missing targeting_state or weapon_manager")
		return
	
	# Clear existing buttons
	for child in targeting_buttons_container.get_children():
		child.queue_free()
	
	# Get player's weapons
	var weapons = weapon_manager.get_player_weapons(player_id)
	print("Found", weapons.size(), "weapons for Player", player_id + 1)
	
	# Create a button for each weapon
	for weapon in weapons:
		print("Creating button for weapon:", weapon.data.name)
		var button = Button.new()
		button.text = weapon.data.name
		button.tooltip_text = "Range: " + str(weapon.data.attack_range) + "\n" + \
						   "Damage: " + str(weapon.data.damage) + "\n" + \
						   "Splash: " + str(weapon.data.splash_radius)
		
		# Connect button press to select weapon
		button.pressed.connect(func(): _on_targeting_button_pressed(weapon, player_id))
		
		# Add to container
		targeting_buttons_container.add_child(button)
	
	# Make sure the container is visible
	targeting_buttons_container.visible = true
	
	# Update phase label to show remaining attacks
	if has_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel"):
		var phase_label = get_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
		phase_label.text = "Targeting Phase (3 targets left)"
	
	# Update turn label to show current player
	if has_node("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel"):
		var turn_label = get_node("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel")
		turn_label.text = "Player " + str(player_id + 1) + "'s Turn"

# Handle targeting button press
func _on_targeting_button_pressed(weapon, player_id):
	var targeting_state = GameManager.targeting_state
	var targeting_manager = GameManager.targeting_manager
	var targeting_visualization = GameManager.targeting_visualization
	
	if !targeting_state or !targeting_manager or !targeting_visualization:
		print("Error: Missing components for targeting")
		return
	
	print("Selected weapon for targeting:", weapon.data.name)
	
	# Use select_weapon_for_attack method in targeting_state
	targeting_state.select_weapon_for_targeting(weapon, player_id)
	
	# Show targeting visualization
	if targeting_visualization.has_method("show_weapon_range"):
		targeting_visualization.show_weapon_range(weapon, targeting_manager.valid_targets)

# Handle end targeting button press
func _on_end_targeting_pressed():
	var targeting_state = GameManager.targeting_state
	
	if targeting_state and targeting_state.has_method("on_end_targeting_button_pressed"):
		targeting_state.on_end_targeting_button_pressed()
		print("End targeting button pressed")

# Update UI based on game state
func update_game_ui(current_state):
	var game_state_machine = GameManager.game_state_machine
	
	if !game_state_machine:
		return
		
	match current_state:
		game_state_machine.GameState.PLACEMENT:
			print("Updating UI for placement state")
			if weapon_buttons_container:
				weapon_buttons_container.visible = true
			if targeting_buttons_container:
				targeting_buttons_container.visible = false
			if end_placement_button:
				end_placement_button.visible = true
			if end_targeting_button:
				end_targeting_button.visible = false
			
		game_state_machine.GameState.TARGETING:
			print("Updating UI for targeting state")
			if weapon_buttons_container:
				weapon_buttons_container.visible = false
			if targeting_buttons_container:
				targeting_buttons_container.visible = true
			if end_placement_button:
				end_placement_button.visible = false
			if end_targeting_button:
				end_targeting_button.visible = true
			
		game_state_machine.GameState.ATTACK:
			print("Updating UI for attack state")
			if weapon_buttons_container:
				weapon_buttons_container.visible = false
			if targeting_buttons_container:
				targeting_buttons_container.visible = false
			if end_placement_button:
				end_placement_button.visible = false
			if end_targeting_button:
				end_targeting_button.visible = false
			
		_:
			if weapon_buttons_container:
				weapon_buttons_container.visible = false
			if targeting_buttons_container:
				targeting_buttons_container.visible = false
			if end_placement_button:
				end_placement_button.visible = false
			if end_targeting_button:
				end_targeting_button.visible = false
