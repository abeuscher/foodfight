extends Node2D

# Pre-load essential base classes
const BaseUIListener = preload("res://scripts/ui/base_ui_listener.gd")

# UI element references using @onready for cleaner initialization
@onready var weapon_buttons_container = $UI/BottomBar/WeaponButtonsContainer
@onready var targeting_buttons_container = $UI/BottomBar/TargetingButtonsContainer
@onready var end_placement_button = $UI/BottomBar/EndPlacementButton
@onready var end_targeting_button = $UI/BottomBar/EndTargetingButton
@onready var phase_label = $UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel
@onready var turn_label = $UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel
@onready var player2_label = $UI/TopBar/HBoxContainer/Player2Container/NameLabel
@onready var ai_thinking_indicator = $UI/AIThinkingIndicator

# References to components - use same property names as game_manager.gd
@onready var game_board = $GameBoard
@onready var game_state_machine = $GameStateMachine
@onready var phase_manager = $PhaseManager
@onready var base_ui_manager = $BaseUIManager
@onready var player_manager = $PlayerManager
@onready var placement_state = $PlacementState
@onready var targeting_state = $TargetingState
@onready var attack_state = $AttackState
@onready var weapon_types = $WeaponTypes
@onready var weapon_placement = $WeaponPlacement
@onready var ai_opponent = $AIOpponent

# UI manager sub-components for direct access if needed
var player_ui_manager
var phase_ui_manager
var placement_ui_manager
var targeting_ui_manager
var ai_ui_manager

# State tracking
var game_initialized = false

func _ready():
	print("Main scene loaded. Initializing game...")
	
	# Register the GameManager singleton - this is the ONLY place it should be created
	if not Engine.has_singleton("GameManager"):
		var game_manager = Node.new()
		game_manager.name = "GameManager"
		Engine.register_singleton("GameManager", game_manager)
	
	# Initialize through GameManager singleton - this is the ONLY initialization path
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		
		# Register all components but do NOT initialize them here
		# GameManager will be responsible for initialization order
		game_manager.game_board = game_board
		game_manager.game_state_machine = game_state_machine
		game_manager.base_ui_manager = base_ui_manager
		game_manager.player_manager = player_manager
		game_manager.placement_state = placement_state
		game_manager.targeting_state = targeting_state
		game_manager.attack_state = attack_state
		game_manager.weapon_types = weapon_types
		game_manager.weapon_placement = weapon_placement
		game_manager.ai_opponent = ai_opponent
		
		# LET THE GAMEMANAGER DO ALL INITIALIZATION - no direct calls here
		print("Starting game initialization through GameManager...")
		game_manager.connect("game_initialized", Callable(self, "_on_game_initialized"))
		game_initialized = await game_manager.initialize_game(self)
	else:
		push_error("GameManager singleton not found")

func _on_game_initialized():
	print("Game initialization complete")
	_setup_ui()
	
	# Ensure PlacementState is initialized with weapon buttons container
	var placement_state = GameManager.get_service("PlacementState")
	var weapon_buttons_container = $UI/BottomBar/WeaponButtonsContainer
	if placement_state and weapon_buttons_container:
		placement_state.weapon_buttons_container = weapon_buttons_container
		placement_state.create_weapon_buttons_for_current_state()
	
	# Let GameManager control the game start sequence
	if Engine.has_singleton("GameManager"):
		Engine.get_singleton("GameManager").start_game()

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
	
	# Check if game is waiting for AI before handling input
	var phase_manager = get_service("PhaseManager")
	if phase_manager and phase_manager.is_game_waiting():
		# Block all input while waiting
		get_viewport().set_input_as_handled()
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

# Helper method to get service from GameManager
func get_service(service_name):
	if Engine.has_singleton("GameManager"):
		return Engine.get_singleton("GameManager").get_service(service_name)
	return null

# Handle targeting button press - this is now a callback for base_ui_manager
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
