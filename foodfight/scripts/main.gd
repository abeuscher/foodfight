extends Node2D

# UI element references using @onready for cleaner initialization
@onready var weapon_buttons_container = $UI/BottomBar/WeaponButtonsContainer
@onready var targeting_buttons_container = $UI/BottomBar/TargetingButtonsContainer
@onready var end_placement_button = $UI/BottomBar/EndPlacementButton
@onready var end_targeting_button = $UI/BottomBar/EndTargetingButton
@onready var phase_label = $UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel
@onready var turn_label = $UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel

# References to components - use same property names as game_manager.gd
@onready var game_board = $GameBoard
@onready var game_state_machine = $GameStateMachine
@onready var game_ui_manager = $GameUIManager  # Changed from ui_manager
@onready var player_manager = $PlayerManager
@onready var placement_state = $PlacementState
@onready var targeting_state = $TargetingState
@onready var attack_state = $AttackState
@onready var weapon_types = $WeaponTypes
@onready var weapon_placement = $WeaponPlacement
@onready var ai_opponent = $AIOpponent

# State tracking
var game_initialized = false

func _ready():
	print("Main scene loaded. Initializing game...")
	
	# Register the GameManager singleton
	if not Engine.has_singleton("GameManager"):
		var game_manager = Node.new()
		game_manager.name = "GameManager"
		Engine.register_singleton("GameManager", game_manager)
	
	var game_manager = Engine.get_singleton("GameManager")
	
	# Store references in GameManager (property names must match)
	game_manager.game_board = game_board
	game_manager.game_state_machine = game_state_machine
	game_manager.game_ui_manager = game_ui_manager  # Changed from ui_manager
	game_manager.player_manager = player_manager
	game_manager.placement_state = placement_state
	game_manager.targeting_state = targeting_state
	game_manager.attack_state = attack_state
	game_manager.weapon_types = weapon_types
	game_manager.weapon_placement = weapon_placement
	
	# Initialize AI opponent
	game_manager.ai_opponent = ai_opponent
	ai_opponent.initialize(
		game_board,
		weapon_types,
		weapon_placement,
		player_manager,
		attack_state.get_node("TargetingManager")
	)
	
	# Connect AI signals to UI manager
	game_ui_manager.connect_ai_signals(ai_opponent)
	
	# Initialize the core game components (update ui_manager to game_ui_manager)
	game_state_machine.initialize(
		game_board, 
		weapon_types, 
		weapon_placement, 
		targeting_state,
		attack_state,
		game_ui_manager,
		player_manager
	)
	
	# Fix: Initialize placement_state with the correct 3 arguments
	placement_state.initialize(
		weapon_types, 
		weapon_placement,
		weapon_buttons_container  # Use the buttons container, not game_ui_manager
	)
	
	# Fix: Remove the fourth argument (game_ui_manager) to match the function signature
	targeting_state.initialize(
		game_board,
		attack_state.get_node("WeaponManager"),
		attack_state.get_node("TargetingManager")
	)
	
	# Start the game
	game_state_machine.start_game()

	# Allow a frame to ensure all nodes are ready
	await get_tree().process_frame

	# Set up UI elements
	_setup_ui()
	
	# Immediately update the player 2 label to show AI
	var player2_label = $UI/TopBar/HBoxContainer/Player2Container/NameLabel
	if player2_label:
		player2_label.text = "AI OPPONENT"
		player2_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))  # Make it red
		print("Updated Player 2 label to AI OPPONENT")
	
	# Initialize the game through GameManager singleton
	if GameManager:
		print("Starting game initialization through GameManager...")
		GameManager.connect("game_initialized", Callable(self, "_on_game_initialized"))
		game_initialized = await GameManager.initialize_game(self)
	else:
		push_error("GameManager singleton not found")

func _on_game_initialized():
	print("Game initialization complete, starting game...")
	GameManager.start_game()

# Set up the UI elements
func _setup_ui():
	print("Setting up UI elements...")
	
	# Configure end placement button
	if end_placement_button:
		end_placement_button.custom_minimum_size = Vector2(180, 40)
		end_placement_button.visible = false
	
	# Configure end targeting button
	if end_targeting_button:
		end_targeting_button.custom_minimum_size = Vector2(180, 40)
		end_targeting_button.visible = false
	
	# Initially hide weapon containers
	if targeting_buttons_container:
		targeting_buttons_container.visible = false
	
	if weapon_buttons_container:
		weapon_buttons_container.visible = false

# Handle input events
func _input(event):
	if !game_initialized:
		return
	
	var game_state_machine = GameManager.game_state_machine
	if !game_state_machine or !game_state_machine.is_initialized:
		return
	
	# Forward input to appropriate state handlers
	match game_state_machine.current_state:
		game_state_machine.GameState.WEAPON_PLACEMENT, game_state_machine.GameState.BASE_PLACEMENT:
			if GameManager.placement_state:
				GameManager.placement_state.handle_input(event)
				
		game_state_machine.GameState.TARGETING:
			if GameManager.targeting_state:
				GameManager.targeting_state.handle_input(event)

# Handle targeting button press - this is now a callback for game_ui_manager
func _on_targeting_button_pressed(weapon, player_id):
	var targeting_state = GameManager.targeting_state
	var targeting_manager = GameManager.targeting_manager
	
	if !targeting_state or !targeting_manager:
		return
	
	print("Selected weapon for targeting:", weapon.data.name)
	
	# Use targeting state to select weapon
	targeting_state.select_weapon_for_targeting(weapon, player_id)

# Handle end targeting button press
func _on_end_targeting_pressed():
	print("End targeting button pressed")
	var targeting_state = GameManager.targeting_state
	
	if targeting_state:
		targeting_state.on_end_targeting_button_pressed()

# Update UI based on game state
func update_game_ui(current_state):
	var game_state_machine = GameManager.game_state_machine
	if !game_state_machine:
		return
	
	# Reset all UI elements
	_reset_ui_elements()
	
	# Configure UI for current state
	match current_state:
		game_state_machine.GameState.WEAPON_PLACEMENT, game_state_machine.GameState.BASE_PLACEMENT:
			print("Updating UI for placement state")
			if weapon_buttons_container:
				weapon_buttons_container.visible = true
			if end_placement_button:
				end_placement_button.visible = true
			
		game_state_machine.GameState.TARGETING:
			print("Updating UI for targeting state")
			if targeting_buttons_container:
				targeting_buttons_container.visible = true
			if end_targeting_button:
				end_targeting_button.visible = true

# Reset all UI elements to default state
func _reset_ui_elements():
	if weapon_buttons_container:
		weapon_buttons_container.visible = false
	if targeting_buttons_container:
		targeting_buttons_container.visible = false
	if end_placement_button:
		end_placement_button.visible = false
	if end_targeting_button:
		end_targeting_button.visible = false
