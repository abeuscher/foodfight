extends Node2D

# References to UI elements
@onready var weapon_buttons_container = $UI/BottomBar/WeaponButtonsContainer
@onready var attack_buttons_container = $UI/BottomBar/AttackButtonsContainer
@onready var end_placement_button = $UI/BottomBar/EndPlacementButton

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
# In main.gd's _ready() function
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
	
	if attack_buttons_container:
		attack_buttons_container.visible = false
	
	if weapon_buttons_container:
		weapon_buttons_container.visible = false

# Handle input events
func _input(event):
	if !game_initialized:
		return
		
	# Forward input to GameManager for handling
	var game_state_machine = GameManager.game_state_machine
	var placement_state = GameManager.placement_state
	var attack_state = GameManager.attack_state
	
	if game_state_machine and game_state_machine.is_initialized:
		match game_state_machine.current_state:
			game_state_machine.GameState.PLACEMENT:
				if placement_state:
					placement_state.handle_input(event)
			game_state_machine.GameState.ATTACK:
				if attack_state:
					attack_state.handle_input(event)

# Create attack buttons for player weapons
func create_attack_buttons(player_id):
	if !game_initialized or !attack_buttons_container:
		return
		
	var attack_state = GameManager.attack_state
	var weapon_manager = GameManager.weapon_manager
	
	if !attack_state or !weapon_manager:
		return
		
	# Clear existing buttons
	for child in attack_buttons_container.get_children():
		child.queue_free()
	
	# Get player's weapons
	var weapons = weapon_manager.get_player_weapons(player_id)
	
	# Create a button for each weapon
	for weapon in weapons:
		var button = Button.new()
		button.text = weapon.data.name
		button.tooltip_text = "Range: " + str(weapon.data.attack_range) + "\n" + \
							"Damage: " + str(weapon.data.damage) + "\n" + \
							"Splash: " + str(weapon.data.splash_radius)
		
		# Connect button press to select weapon
		button.pressed.connect(func(): _on_attack_button_pressed(weapon, player_id))
		
		# Add to container
		attack_buttons_container.add_child(button)

# Handle attack button press
func _on_attack_button_pressed(weapon, player_id):
	var targeting_manager = GameManager.targeting_manager
	var targeting_visualization = GameManager.targeting_visualization
	
	if !targeting_manager or !targeting_visualization:
		return
		
	targeting_manager.select_weapon(weapon, player_id)
	
	# Show targeting visualization
	if targeting_visualization.has_method("show_weapon_range"):
		targeting_visualization.show_weapon_range(weapon, targeting_manager.valid_targets)

# Update UI based on game state
func update_game_ui(current_state):
	var game_state_machine = GameManager.game_state_machine
	
	if !game_state_machine:
		return
		
	match current_state:
		game_state_machine.GameState.PLACEMENT:
			if weapon_buttons_container:
				weapon_buttons_container.visible = true
			if attack_buttons_container:
				attack_buttons_container.visible = false
			if end_placement_button:
				end_placement_button.visible = true
		game_state_machine.GameState.ATTACK:
			if weapon_buttons_container:
				weapon_buttons_container.visible = false
			if attack_buttons_container:
				attack_buttons_container.visible = true
			if end_placement_button:
				end_placement_button.visible = false
		_:
			if weapon_buttons_container:
				weapon_buttons_container.visible = false
			if attack_buttons_container:
				attack_buttons_container.visible = false
			if end_placement_button:
				end_placement_button.visible = false
