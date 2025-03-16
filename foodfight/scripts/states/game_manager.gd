extends Node

signal game_initialized
signal component_initialized(component_name)

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

# Initialize all components in the correct order
func initialize_components():
	# 1. Initialize the game board (no dependencies)
	game_board.initialize_grid()
	emit_signal("component_initialized", "GameBoard")
	
	# 2. Initialize player manager (no dependencies)
	# Configure player 2 as AI
	player_manager.set_player_type(1, player_manager.PlayerType.AI)
	player_manager.set_player_name(1, "AI OPPONENT")
	emit_signal("component_initialized", "PlayerManager")
	
	# 3. Initialize weapon systems
	weapon_placement.initialize(game_board, weapon_types)
	emit_signal("component_initialized", "WeaponPlacement")
	
	# 4. Initialize weapon manager
	weapon_manager.initialize(game_board)
	emit_signal("component_initialized", "WeaponManager")
	
	# 5. Initialize targeting manager
	targeting_manager.initialize(game_board)
	emit_signal("component_initialized", "TargetingManager")
	
	# 6. Initialize placement state
	var main_scene = get_tree().current_scene
	var weapon_buttons = main_scene.get_node("UI/BottomBar/WeaponButtonsContainer")
	
	placement_state.initialize(weapon_types, weapon_placement, weapon_buttons)
	emit_signal("component_initialized", "PlacementState")
	
	# 7. Initialize targeting state
	targeting_state.initialize(game_board, weapon_manager, targeting_manager)
	emit_signal("component_initialized", "TargetingState")
	
	# 8. Initialize attack state
	attack_state.initialize(game_board, weapon_types)
	emit_signal("component_initialized", "AttackState")
	
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
	
	# Get references to turn_manager and ai_controller after game_state_machine initialization
	turn_manager = game_state_machine.turn_manager
	ai_controller = game_state_machine.ai_controller
	
	
	# 11. Connect signals between components
	connect_component_signals()
	
	# 12. Make sure UI is updated correctly for the initial game state
	if game_ui_manager:
		print("Ensuring UI is properly set up for initial state: BASE_PLACEMENT")
		# Use update_ui instead of update_for_state
		game_ui_manager.update_ui(game_state_machine.GameState.BASE_PLACEMENT, 0)
	
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
		ai_opponent.connect("thinking_started", Callable(game_ui_manager, "show_ai_thinking"))
		ai_opponent.connect("thinking_completed", Callable(game_ui_manager, "hide_ai_thinking"))

# Helper function to connect UI buttons
func connect_ui_buttons(main_scene):
	# End placement button
	var end_placement_button = main_scene.get_node("UI/BottomBar/EndPlacementButton")
	
	end_placement_button.pressed.connect(func():
		if game_state_machine.current_state == game_state_machine.GameState.BASE_PLACEMENT:
			var current_player = turn_manager.current_player_index
			game_state_machine._on_base_placement_complete(current_player)
		elif game_state_machine.current_state == game_state_machine.GameState.WEAPON_PLACEMENT:
			game_state_machine.placement_completed()
		else:
			game_state_machine.placement_completed()
	)
	
	# End targeting button
	var end_targeting_button = main_scene.get_node("UI/BottomBar/EndTargetingButton")
	if turn_manager:
		turn_manager.connect("player_changed", Callable(game_ui_manager, "update_player_ui"))
	
	# Connect ai_controller signals
	if ai_controller:
		ai_controller.connect("ai_action_started", Callable(game_ui_manager, "show_ai_thinking"))
						
# Start the game
func start_game():
	game_state_machine.start_game()
