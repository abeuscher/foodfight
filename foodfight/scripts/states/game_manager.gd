extends Node

signal game_initialized
signal component_initialized(component_name)

# Service locator registry
var services = {}

# Component references
@onready var current_scene = null

# Core components
var game_board
var game_state_machine
var game_ui_manager
var player_manager
var placement_state
var targeting_state
var attack_state
var weapon_types
var weapon_placement
var ai_opponent

# Nested components
var weapon_manager
var targeting_manager

# New separated components
var turn_manager
var ai_controller

# UI manager sub-components
var base_ui_manager
var player_ui_manager
var phase_ui_manager
var placement_ui_manager
var targeting_ui_manager
var ai_ui_manager

# State tracking
var initialization_complete = false
var main_scene_path = "res://scenes/main.tscn"
var is_single_player = true  # Now always true - we're converting to single-player only
var ai_difficulty = 1  # 0=easy, 1=medium, 2=hard

func _ready():
	if not Engine.has_singleton("GameManager"):
		Engine.register_singleton("GameManager", self)
	
	get_tree().root.ready.connect(_on_scene_tree_ready)

func _on_scene_tree_ready():
	current_scene = get_tree().current_scene

# Main initialization function called from main.gd
func initialize_game(main_node):
	# Get references to all components
	get_component_references(main_node)
	
	# Initialize all components in order
	initialize_components()
	
	# Mark initialization as complete and signal
	initialization_complete = true
	emit_signal("game_initialized")
	
	return true

# Get references to all game components
func get_component_references(main_node):
	# Get direct component references
	game_board = main_node.get_node("GameBoard")
	game_state_machine = main_node.get_node("GameStateMachine")
	game_ui_manager = main_node.get_node("GameUIManager")
	player_manager = main_node.get_node("PlayerManager")
	placement_state = main_node.get_node("PlacementState")
	targeting_state = main_node.get_node("TargetingState")
	attack_state = main_node.get_node("AttackState")
	weapon_types = main_node.get_node("WeaponTypes")
	weapon_placement = main_node.get_node("WeaponPlacement")
	ai_opponent = main_node.get_node("AIOpponent")
	
	# Get nested components
	weapon_manager = attack_state.get_node("WeaponManager")
	targeting_manager = attack_state.get_node("TargetingManager")
	
	# Get the new separated components from game state machine after initialization
	if game_state_machine:
		turn_manager = game_state_machine.turn_manager
		ai_controller = game_state_machine.ai_controller
	
	return true

# Register a service in the service locator
func register_service(service_name: String, service_instance: Object) -> void:
	services[service_name] = service_instance
	print("Service registered: " + service_name)

# Get a service from the service locator
func get_service(service_name: String, create_default: bool = false) -> Object:
	if has_service(service_name):
		return services[service_name]
	
	if create_default:
		# Create appropriate default based on service name
		match service_name:
			"GameUIManager":
				var new_service = Node.new()
				new_service.name = "GameUIManager"
				new_service.set_script(load("res://scripts/ui/game_ui_manager.gd"))
				register_service(service_name, new_service)
				return new_service
	
	push_warning("Service not found: " + service_name)
	return null

# Check if a service exists in the service locator
func has_service(service_name: String) -> bool:
	return services.has(service_name)

# Initialize all components in the correct order
func initialize_components():
	# 1. Initialize the game board (no dependencies)
	game_board.initialize_grid()
	emit_signal("component_initialized", "GameBoard")
	register_service("GameBoard", game_board)
	
	# 2. Initialize player manager (no dependencies)
	# Configure player 2 as AI
	player_manager.set_player_type(1, player_manager.PlayerType.AI)
	player_manager.set_player_name(1, "AI OPPONENT")
	emit_signal("component_initialized", "PlayerManager")
	register_service("PlayerManager", player_manager)
	
	# 3. Initialize weapon systems
	weapon_placement.initialize(game_board, weapon_types)
	emit_signal("component_initialized", "WeaponPlacement")
	register_service("WeaponPlacement", weapon_placement)
	register_service("WeaponTypes", weapon_types)
	
	# 4. Initialize weapon manager
	weapon_manager.initialize(game_board)
	emit_signal("component_initialized", "WeaponManager")
	register_service("WeaponManager", weapon_manager)
	
	# 5. Initialize targeting manager
	targeting_manager.initialize(game_board)
	emit_signal("component_initialized", "TargetingManager")
	register_service("TargetingManager", targeting_manager)
	
	# 6. Initialize placement state
	var main_scene = get_tree().current_scene
	var weapon_buttons = main_scene.get_node("UI/BottomBar/WeaponButtonsContainer")
	
	placement_state.initialize(weapon_types, weapon_placement, weapon_buttons)
	emit_signal("component_initialized", "PlacementState")
	register_service("PlacementState", placement_state)
	
	# 7. Initialize targeting state
	targeting_state.initialize(game_board, weapon_manager, targeting_manager)
	emit_signal("component_initialized", "TargetingState")
	register_service("TargetingState", targeting_state)
	
	# 8. Initialize attack state
	attack_state.initialize(game_board, weapon_types)
	emit_signal("component_initialized", "AttackState")
	register_service("AttackState", attack_state)
	
	# 9. Initialize AI opponent with the appropriate difficulty
	if ai_opponent:
		ai_opponent.initialize(
			game_board, 
			weapon_types, 
			weapon_placement, 
			player_manager, 
			targeting_manager
		)
		ai_opponent.set_difficulty(ai_difficulty)
		emit_signal("component_initialized", "AIOpponent")
		register_service("AIOpponent", ai_opponent)
	
	# 10. Initialize game state machine (depends on everything)
	game_state_machine.initialize(
		game_board,
		weapon_types,
		weapon_placement,
		targeting_state,
		attack_state,
		game_ui_manager,
		player_manager
	)
	
	# Set single player mode in game state machine
	game_state_machine.set_single_player_mode(true)
	
	emit_signal("component_initialized", "GameStateMachine")
	register_service("GameStateMachine", game_state_machine)
	
	# Get references to turn_manager and ai_controller after game_state_machine initialization
	turn_manager = game_state_machine.turn_manager
	ai_controller = game_state_machine.ai_controller
	
	if turn_manager:
		register_service("TurnManager", turn_manager)
	
	if ai_controller:
		register_service("AIController", ai_controller)
		
	if game_ui_manager:
		register_service("GameUIManager", game_ui_manager)
	
	# 11. Connect signals between components
	connect_component_signals()
	
	# 12. Make sure UI is updated correctly for the initial game state
	if game_ui_manager:
		print("Ensuring UI is properly set up for initial state: BASE_PLACEMENT")
		# Check if we need to create a new UI manager
		if !game_ui_manager.has_method("update_ui"):
			print("Creating new GameUIManager instance")
			# Create a new game_ui_manager if needed
			game_ui_manager = Node.new()
			game_ui_manager.name = "GameUIManager"
			game_ui_manager.set_script(load("res://scripts/ui/game_ui_manager.gd"))
			main_scene.add_child(game_ui_manager)
			register_service("GameUIManager", game_ui_manager)
			await get_tree().process_frame
		
		# Try to update the UI
		update_ui(game_state_machine.GameState.BASE_PLACEMENT, 0)
	else:
		push_error("No GameUIManager available for UI update!")
	
	return true

# Connect signals between components
func connect_component_signals():
	var main_scene = get_tree().current_scene
	
	# Connect UI buttons
	connect_ui_buttons(main_scene)
	
	# Connect targeting state to game_ui_manager
	targeting_state.connect("player_turn_started", Callable(game_ui_manager, "handle_player_turn_update"))
	
	# Connect AI signals
	if ai_opponent:
		print("Connecting AI opponent signals to UI")
		ai_opponent.connect("thinking_started", Callable(game_ui_manager, "show_ai_thinking"))
		ai_opponent.connect("thinking_completed", Callable(game_ui_manager, "hide_ai_thinking"))
	
	# Connect AI controller signals
	if ai_controller:
		print("Connecting AI controller signals to UI")
		ai_controller.connect("ai_action_started", Callable(game_ui_manager, "show_ai_thinking"))
		ai_controller.connect("ai_action_completed", Callable(game_ui_manager, "hide_ai_thinking"))
	
	# Connect turn manager signals if available
	if turn_manager:
		turn_manager.connect("player_changed", Callable(game_ui_manager, "update_player_ui"))

# Helper function to connect UI buttons
func connect_ui_buttons(main_scene):
	# End placement button
	var end_placement_button = main_scene.get_node("UI/BottomBar/EndPlacementButton")
	if end_placement_button:
		end_placement_button.pressed.connect(func():
			if game_state_machine.current_state == game_state_machine.GameState.BASE_PLACEMENT:
				var current_player = player_manager.current_player_index
				game_state_machine._on_base_placement_complete(current_player)
			elif game_state_machine.current_state == game_state_machine.GameState.WEAPON_PLACEMENT:
				game_state_machine.placement_completed()
		)
	
	# End targeting button
	var end_targeting_button = main_scene.get_node("UI/BottomBar/EndTargetingButton")
	if end_targeting_button:
		end_targeting_button.pressed.connect(func():
			if game_state_machine.current_state == game_state_machine.GameState.TARGETING:
				game_state_machine.targeting_completed()
		)

# Helper method to safely update UI
func update_ui(state, player_index):
	var ui_manager = get_service("GameUIManager")
	if ui_manager and ui_manager.has_method("update_ui"):
		ui_manager.update_ui(state, player_index)
	else:
		print("WARNING: Cannot update UI - no suitable UI manager found")

# Helper method to update game phase
func update_game_phase(phase_text):
	var ui_manager = get_service("GameUIManager")
	if ui_manager and ui_manager.has_method("update_game_phase"):
		ui_manager.update_game_phase(phase_text)
	else:
		print("WARNING: Cannot update game phase - no suitable UI manager found")

# Start the game
func start_game():
	game_state_machine.start_game()

# Accessor methods for getting component references
func get_weapon_manager():
	return get_service("WeaponManager")

func get_targeting_state():
	return get_service("TargetingState")

func get_targeting_manager():
	return get_service("TargetingManager")

func get_weapon_types():
	return get_service("WeaponTypes")

func get_turn_manager():
	return get_service("TurnManager")

func get_ai_controller():
	return get_service("AIController")

func get_game_state_machine():
	return get_service("GameStateMachine")
