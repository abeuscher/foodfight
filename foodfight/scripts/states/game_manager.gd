extends Node

signal game_initialized
signal component_initialized(component_name)

# Component references with explicit typing
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

# Nested components
var weapon_manager
var targeting_manager

# State tracking
var initialization_complete = false
var main_scene_path = "res://scenes/main.tscn"

func _ready():
	print("GameManager singleton initialized")
	
	# Make sure this instance is available as a singleton
	if not Engine.has_singleton("GameManager"):
		print("Registering GameManager singleton")
		Engine.register_singleton("GameManager", self)
	
	get_tree().root.ready.connect(_on_scene_tree_ready)

func _on_scene_tree_ready():
	# Safely get current scene
	if get_tree() and get_tree().root:
		current_scene = get_tree().current_scene
		if current_scene:
			print("Current scene: ", current_scene.name)
		else:
			print("Warning: Current scene is null. This is normal during testing.")
	else:
		print("Warning: Scene tree not ready")

# Main initialization function called from main.gd
func initialize_game(main_node):
	print("Starting game initialization...")
	
	# Get references to all components
	get_component_references(main_node)
	
	print("References collected. Initializing components...")
	await get_tree().process_frame
	
	# Initialize all components in order
	await initialize_components()
	
	# Mark initialization as complete and signal
	initialization_complete = true
	print("Game initialization complete!")
	emit_signal("game_initialized")
	
	return true

# Get references to all game components
func get_component_references(main_node):
	print("Collecting component references...")
	
	# Get direct component references
	game_board = main_node.get_node_or_null("GameBoard")
	game_state_machine = main_node.get_node_or_null("GameStateMachine")
	game_ui_manager = main_node.get_node_or_null("GameUIManager")
	player_manager = main_node.get_node_or_null("PlayerManager")
	placement_state = main_node.get_node_or_null("PlacementState")
	targeting_state = main_node.get_node_or_null("TargetingState")
	attack_state = main_node.get_node_or_null("AttackState")
	weapon_types = main_node.get_node_or_null("WeaponTypes")
	weapon_placement = main_node.get_node_or_null("WeaponPlacement")

	# Get nested components
	weapon_manager = attack_state.get_node_or_null("WeaponManager")
	targeting_manager = attack_state.get_node_or_null("TargetingManager")
	
	# Log component references status
	print_component_references()
	
	return true

# Helper function to print component references status
func print_component_references():
	print("Components found:")
	print("- Game Board: ", game_board != null)
	print("- Game State Machine: ", game_state_machine != null)
	print("- Game UI Manager: ", game_ui_manager != null)
	print("- Player Manager: ", player_manager != null)
	print("- Placement State: ", placement_state != null)
	print("- Targeting State: ", targeting_state != null)
	print("- Attack State: ", attack_state != null)
	print("- Weapon Manager: ", weapon_manager != null)
	print("- Targeting Manager: ", targeting_manager != null)
	print("- Weapon Types: ", weapon_types != null)
	print("- Weapon Placement: ", weapon_placement != null)

# Initialize all components in the correct order
func initialize_components():
	print("Initializing components in order...")
	
	# 1. Initialize the game board (no dependencies)
	print("Initializing GameBoard...")
	game_board.initialize_grid()
	emit_signal("component_initialized", "GameBoard")
	
	# 2. Initialize player manager (no dependencies)
	print("Player Manager ready")
	emit_signal("component_initialized", "PlayerManager")
	
	# Brief pause between initializations
	await get_tree().process_frame
	
	# 3. Initialize weapon systems
	print("Initializing Weapon Placement...")
	weapon_placement.initialize(game_board, weapon_types)
	emit_signal("component_initialized", "WeaponPlacement")
	
	# 4. Initialize weapon manager
	print("Initializing Weapon Manager...")
	weapon_manager.initialize(game_board)
	emit_signal("component_initialized", "WeaponManager")
	
	# 5. Initialize targeting manager
	print("Initializing Targeting Manager...")
	targeting_manager.initialize(game_board)
	emit_signal("component_initialized", "TargetingManager")
	
	await get_tree().process_frame
	
	# 6. Initialize placement state
	print("Initializing Placement State...")
	var weapon_buttons = null
	
	var main_scene = get_tree().current_scene
	if main_scene.has_node("UI/BottomBar/WeaponButtonsContainer"):
		weapon_buttons = main_scene.get_node("UI/BottomBar/WeaponButtonsContainer")
	
	placement_state.initialize(weapon_types, weapon_placement, weapon_buttons)
	emit_signal("component_initialized", "PlacementState")
	
	# 7. Initialize targeting state
	print("Initializing Targeting State...")
	targeting_state.initialize(game_board, weapon_manager, targeting_manager)
	emit_signal("component_initialized", "TargetingState")
	
	# 8. Initialize attack state
	print("Initializing Attack State...")
	attack_state.initialize(game_board, weapon_types)
	emit_signal("component_initialized", "AttackState")
	
	await get_tree().process_frame
	
	# 10. Initialize game state machine (depends on everything)
	print("Initializing Game State Machine...")
	game_state_machine.initialize(
		game_board,
		weapon_types,
		weapon_placement,
		targeting_state,
		attack_state,
		game_ui_manager,
		player_manager
	)
	emit_signal("component_initialized", "GameStateMachine")
	
	# 11. Connect signals between components
	connect_component_signals()
	
	print("All components initialized")
	return true

# Connect signals between components
func connect_component_signals():
	print("Connecting component signals...")
	
	var main_scene = get_tree().current_scene
	
	# Connect UI buttons
	connect_ui_buttons(main_scene)
	
	# Connect gameplay components
	connect_gameplay_signals()
	
	# Connect targeting state to game_ui_manager
	print("Connecting TargetingState.player_turn_started to GameUIManager")
	targeting_state.connect("player_turn_started", Callable(game_ui_manager, "handle_player_turn_started"))

# Helper function to connect UI buttons
func connect_ui_buttons(main_scene):
	# End placement button
	var end_placement_button = main_scene.get_node("UI/BottomBar/EndPlacementButton")
	# Disconnect any existing connections to avoid duplicates
	if end_placement_button.is_connected("pressed", Callable(game_state_machine, "placement_completed")):
		end_placement_button.disconnect("pressed", Callable(game_state_machine, "placement_completed"))
	
	# Connect to the appropriate handler based on current state
	end_placement_button.pressed.connect(func():
		if game_state_machine.current_state == game_state_machine.GameState.BASE_PLACEMENT:
			var current_player = game_state_machine.current_player_index
			game_state_machine._on_base_placement_complete(current_player)
		elif game_state_machine.current_state == game_state_machine.GameState.WEAPON_PLACEMENT:
			game_state_machine.placement_completed()
		else:
			# Fallback for any other state
			game_state_machine.placement_completed()
	)
	print("Connected End Placement button")
	
	# End targeting button
	var end_targeting_button = main_scene.get_node("UI/BottomBar/EndTargetingButton")
	if !end_targeting_button.is_connected("pressed", Callable(targeting_state, "on_end_targeting_button_pressed")):
		end_targeting_button.pressed.connect(Callable(targeting_state, "on_end_targeting_button_pressed"))
		print("Connected End Targeting button")

# Helper function to connect gameplay signals
func connect_gameplay_signals():
	# Weapon placement signals
	if !weapon_placement.is_connected("weapon_placed", Callable(game_state_machine, "_on_weapon_placed")):
		weapon_placement.connect("weapon_placed", Callable(game_state_machine, "_on_weapon_placed"))
	
	if !weapon_placement.is_connected("resource_updated", Callable(game_state_machine, "_on_resource_updated")):
		weapon_placement.connect("resource_updated", Callable(game_state_machine, "_on_resource_updated"))
	
	# Targeting state signals
	if !targeting_state.is_connected("targeting_completed", Callable(game_state_machine, "_on_targeting_completed")):
		targeting_state.connect("targeting_completed", Callable(game_state_machine, "_on_targeting_completed"))
	
	# Targeting manager signals
	if !targeting_manager.is_connected("target_selected", Callable(targeting_state, "_on_target_selected")):
		targeting_manager.connect("target_selected", Callable(targeting_state, "_on_target_selected"))
	
	# Attack state signals
	if !attack_state.is_connected("attack_completed", Callable(game_state_machine, "_on_attack_completed")):
		attack_state.connect("attack_completed", Callable(game_state_machine, "_on_attack_completed"))
		
	# Connect points awarded signal to player manager
	if attack_state.has_signal("points_awarded"):
		if !attack_state.is_connected("points_awarded", Callable(player_manager, "add_points")):
			attack_state.connect("points_awarded", Callable(player_manager, "add_points"))
			print("Connected AttackState.points_awarded to PlayerManager.add_points")
			
	# Connect title screen signals
	if !game_ui_manager.is_connected("title_screen_completed", Callable(game_state_machine, "_on_title_screen_completed")):
		game_ui_manager.connect("title_screen_completed", Callable(game_state_machine, "_on_title_screen_completed"))
		print("Connected GameUIManager.title_screen_completed to GameStateMachine")	
						
# Start the game
func start_game():
	print("Starting game...")
	game_state_machine.start_game()