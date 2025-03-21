extends Node

# Import GameState enum from game_state_machine.gd
const GameState = preload("res://scripts/states/game_state_machine.gd").GameState

# Import Phase enum from phase_manager.gd
const Phase = preload("res://scripts/states/phase_manager.gd").Phase

signal game_initialized
signal component_initialized(component_name)

# Service locator registry
var services = {}

# Component references
@onready var current_scene = null

# Core components
var game_board
var game_state_machine
var base_ui_manager
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
var player_ui_manager
var phase_ui_manager
var placement_ui_manager
var targeting_ui_manager
var ai_ui_manager

# State tracking
var initialization_complete = false
var main_scene_path = "res://scenes/main.tscn"
var is_single_player = true # Now always true - we're converting to single-player only
var ai_difficulty = 1 # 0=easy, 1=medium, 2=hard
var initialization_errors = {} # Store initialization errors

# Initialization controller
var initialization_controller = null

# Add event bus
var event_bus

func _ready():
	if not Engine.has_singleton("GameManager"):
		Engine.register_singleton("GameManager", self)
	
	get_tree().root.ready.connect(_on_scene_tree_ready)
	
	# Create and register event bus - FIX: use load() instead of direct class reference
	var EventBusScript = load("res://scripts/core/event_bus.gd")
	event_bus = EventBusScript.new()
	add_child(event_bus)
	register_service("EventBus", event_bus)

func _on_scene_tree_ready():
	current_scene = get_tree().current_scene

# Main initialization function called from main.gd
func initialize_game(main_node):
	# Get the BaseUIManager immediately and register all UI managers first
	base_ui_manager = main_node.get_node("BaseUIManager")
	if base_ui_manager:
		# Register BaseUIManager as a service
		register_service("BaseUIManager", base_ui_manager)
		
		# Immediately initialize and register UI child components
		# This ensures PhaseUIManager is available before PhaseManager needs it
		if base_ui_manager.has_method("initialize_ui_components"):
			base_ui_manager.initialize_ui_components()
		
		# Direct access to PhaseUIManager to guarantee registration
		phase_ui_manager = base_ui_manager.get_node_or_null("PhaseUIManager")
		if phase_ui_manager:
			register_service("PhaseUIManager", phase_ui_manager)
	
	# Get references to all components
	get_component_references(main_node)
	
	# Create and start initialization controller - FIX: Load script first instead of using class name
	var InitControllerScript = load("res://scripts/core/initialization_controller.gd")
	initialization_controller = InitControllerScript.new(self)
	initialization_controller.stage_completed.connect(_on_initialization_stage_completed)
	initialization_controller.initialization_failed.connect(_on_initialization_failed)
	initialization_controller.all_stages_completed.connect(_on_all_stages_completed)
	
	var init_success = initialization_controller.start_initialization()
	if not init_success:
		push_error("Game initialization failed at setup")
		return false
	
	return true

func _on_initialization_stage_completed(stage_name):
	print("Initialization stage completed: " + stage_name)
	emit_signal("component_initialized", stage_name)

func _on_initialization_failed(stage_name, reason):
	push_error("Initialization failed at stage '" + stage_name + "': " + reason)
	initialization_errors[stage_name] = reason
	# Could implement recovery mechanisms here

func _on_all_stages_completed():
	# Call the new function to ensure all connections are made
	ensure_component_event_connections()
	
	# Then proceed with the original code
	initialization_complete = true
	emit_signal("game_initialized")
	print("All initialization stages completed successfully")

# Get references to all game components
func get_component_references(main_node):
	# Get direct component references
	game_board = main_node.get_node("GameBoard")
	game_state_machine = main_node.get_node("GameStateMachine")
	base_ui_manager = main_node.get_node("BaseUIManager") # Changed from BaseUIManager
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
	# Don't replace a working service with a NullService
	if service_instance is NullService and services.has(service_name) and !(services[service_name] is NullService):
		print("GameManager: Not replacing existing service with NullService: " + service_name)
		return
		
	# Don't replace a service that has the critical methods with one that doesn't
	if services.has(service_name):
		var existing_service = services[service_name]
		
		# Special handling for PhaseUIManager
		if service_name == "PhaseUIManager":
			var existing_has_update = existing_service.has_method("update_phase_ui")
			var new_has_update = service_instance.has_method("update_phase_ui")
			
			# Keep the existing one if it has the method and new one doesn't
			if existing_has_update and !new_has_update:
				print("GameManager: Keeping existing PhaseUIManager with update_phase_ui method")
				return
		
		# Similar logic for BaseUIManager
		if service_name == "BaseUIManager":
			var existing_has_update = existing_service.has_method("update_ui")
			var new_has_update = service_instance.has_method("update_ui")
			
			if existing_has_update and !new_has_update:
				print("GameManager: Keeping existing BaseUIManager with update_ui method")
				return
	
	# Register the service
	print("GameManager: Registering service: " + service_name)
	services[service_name] = service_instance

# Get a service from the service locator
func get_service(service_name: String, create_default: bool = false) -> Object:
	if has_service(service_name):
		return services[service_name]
	
	if create_default:
		# Create appropriate default based on service name
		match service_name:
			"BaseUIManager": # Fixed indentation
				var new_service = Node.new()
				new_service.name = "BaseUIManager"
				new_service.set_script(load("res://scripts/ui/base_ui_manager.gd"))
				register_service(service_name, new_service)
				return new_service
			# Add cases for other services as needed
	
	push_warning("Service not found: " + service_name)
	
	# Load at runtime instead of preload
	var NullServiceScript = load("res://scripts/core/null_service.gd")
	if NullServiceScript:
		return NullServiceScript.new()
	else:
		push_warning("Failed to load NullService script")
		# Return a simple Object as last resort
		return Object.new()

# Check if a service exists in the service locator
func has_service(service_name: String) -> bool:
	return services.has(service_name)

# Connect signals between components
func connect_component_signals():
	var main_scene = get_tree().current_scene
	
	# Connect UI buttons
	connect_ui_buttons(main_scene)
	
	# Connect targeting state to base_ui_manager
	var targeting_state = get_service("TargetingState")
	var base_ui_manager = get_service("BaseUIManager")
	
	if targeting_state and targeting_state.has_method("connect") and base_ui_manager and base_ui_manager.has_method("handle_player_turn_update"):
		if not targeting_state.is_connected("player_turn_started", Callable(base_ui_manager, "handle_player_turn_update")):
			targeting_state.connect("player_turn_started", Callable(base_ui_manager, "handle_player_turn_update"))
	
	# Connect AI signals
	var ai_opponent = get_service("AIOpponent")
	if ai_opponent and base_ui_manager:
		print("Connecting AI opponent signals to UI")
		if base_ui_manager.has_method("show_ai_thinking") and base_ui_manager.has_method("hide_ai_thinking"):
			if not ai_opponent.is_connected("thinking_started", Callable(base_ui_manager, "show_ai_thinking")):
				ai_opponent.connect("thinking_started", Callable(base_ui_manager, "show_ai_thinking"))
			if not ai_opponent.is_connected("thinking_completed", Callable(base_ui_manager, "hide_ai_thinking")):
				ai_opponent.connect("thinking_completed", Callable(base_ui_manager, "hide_ai_thinking"))
	
	# Connect AI controller signals
	var ai_controller = get_service("AIController")
	if ai_controller and base_ui_manager:
		print("Connecting AI controller signals to UI")
		if base_ui_manager.has_method("show_ai_thinking") and base_ui_manager.has_method("hide_ai_thinking"):
			if not ai_controller.is_connected("ai_action_started", Callable(base_ui_manager, "show_ai_thinking")):
				ai_controller.connect("ai_action_started", Callable(base_ui_manager, "show_ai_thinking"))
			if not ai_controller.is_connected("ai_action_completed", Callable(base_ui_manager, "hide_ai_thinking")):
				ai_controller.connect("ai_action_completed", Callable(base_ui_manager, "hide_ai_thinking"))
	
	# Connect turn manager signals - FIX: Check if signal exists first
	var turn_manager = get_service("TurnManager")
	if turn_manager:
		print("Checking TurnManager signals...")
		var signals = turn_manager.get_signal_list()
		var has_player_changed = false
		
		for s in signals:
			if s.name == "player_changed":
				has_player_changed = true
				print("Found 'player_changed' signal in TurnManager")
				break
		
		if has_player_changed and base_ui_manager and base_ui_manager.has_method("update_player_ui"):
			print("Connecting TurnManager.player_changed to BaseUIManager.update_player_ui")
			if not turn_manager.is_connected("player_changed", Callable(base_ui_manager, "update_player_ui")):
				turn_manager.connect("player_changed", Callable(base_ui_manager, "update_player_ui"))
		else:
			print("WARNING: Cannot connect TurnManager signals - signal or handler missing")

# Helper function to connect UI buttons
func connect_ui_buttons(main_scene):
	# Retrieve game_state_machine via the service locator
	var game_state_machine = get_service("GameStateMachine")
	if !game_state_machine:
		push_error("GameStateMachine not found. Cannot connect UI buttons.")
		return
	
	# End placement button
	var end_placement_button = main_scene.get_node("UI/BottomBar/EndPlacementButton")
	if end_placement_button:
		end_placement_button.pressed.connect(func():
			if game_state_machine.current_state == game_state_machine.GameState.BASE_PLACEMENT:
				game_state_machine._on_base_placement_complete(player_manager.current_player_index)
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
	var ui_manager = get_service("BaseUIManager") # Changed from BaseUIManager
	if ui_manager and ui_manager.has_method("update_ui"):
		ui_manager.update_ui(state, player_index)
	else:
		print("WARNING: Cannot update UI - no suitable UI manager found")
	
	# Also emit as an event
	emit_event(GameEvents.UI_UPDATE_REQUIRED, {"state": state, "player_index": player_index})

# Helper method to update game phase
func update_game_phase(phase_text):
	var ui_manager = get_service("BaseUIManager") # Changed from BaseUIManager
	if ui_manager and ui_manager.has_method("update_game_phase"):
		ui_manager.update_game_phase(phase_text)
	else:
		print("WARNING: Cannot update game phase - no suitable UI manager found")
		
	# Also emit as an event
	emit_event(GameEvents.PHASE_CHANGED, {"phase_text": phase_text})

# Start the game
func start_game():
	# Ensure all components are initialized
	if !initialization_complete:
		push_error("GameManager: Cannot start game - initialization incomplete")
		return
	
	# Notify the PhaseManager to transition to BASE_PLACEMENT
	var phase_manager = get_service("PhaseManager")
	if phase_manager:
		phase_manager.transition_to_phase(Phase.BASE_PLACEMENT)
	else:
		push_error("GameManager: PhaseManager not available")

# Add new helper methods for component registration and initialization
func register_component(component_name: String, component: Object) -> bool:
	if component == null:
		push_error("Cannot register null component: " + component_name)
		return false
		
	# Special handling for AI components
	if component_name in ["AIController", "AIOpponent"]:
		print("Registering critical AI component: " + component_name)
	
	# Check dependencies
	if initialization_controller:
		var dependency_check = initialization_controller.check_dependencies(component_name)
		if not dependency_check.success:
			push_error("Cannot register " + component_name + " - missing dependencies: " + str(dependency_check.missing))
			return false
	
	# Register the service
	register_service(component_name, component)
	return true

func initialize_and_register(component_name: String, component: Object, init_args: Array = []) -> bool:
	if component == null:
		push_error("Cannot initialize null component: " + component_name)
		return false
	
	# Call initialize method with args if it exists
	if component.has_method("initialize"):
		var result = component.callv("initialize", init_args)
		if result is bool and result == false:
			push_error("Failed to initialize component: " + component_name)
			return false
	
	return register_component(component_name, component)

# Add helper method to emit events
func emit_event(event_name: String, args = null) -> void:
	var bus = get_service("EventBus")
	if bus:
		bus.emit_event(event_name, args)

# Accessor methods for getting component references - now using service locator
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

func ensure_component_event_connections():
	print("GameManager: Ensuring component event connections...")
	
	# Connect placement state to state changed events
	var placement_state = get_service("PlacementState")
	var event_bus = get_service("EventBus")
	
	if placement_state and event_bus:
		print("GameManager: Connecting PlacementState to STATE_CHANGED events")
		event_bus.subscribe(GameEvents.STATE_CHANGED, placement_state)
	
	# Check if weapon_placement is properly set in placement_state
	if placement_state:
		var weapon_placement = get_service("WeaponPlacement")
		if weapon_placement and not placement_state.weapon_placement:
			print("GameManager: Fixing missing weapon_placement reference in PlacementState")
			placement_state.weapon_placement = weapon_placement
	
	# Explicitly register AI components
	_register_ai_components()
	
	# Check other important connections
	_ensure_all_essential_connections()

# Add this helper function to ensure AI components are registered
func _register_ai_components():
	# Make sure AIOpponent is registered
	if ai_opponent and !has_service("AIOpponent"):
		print("GameManager: Registering AIOpponent service")
		register_service("AIOpponent", ai_opponent)
	
	# Initialize AI Controller if we don't have one
	if !ai_controller and ai_opponent:
		print("GameManager: Creating new AIController since none exists")
		var AIControllerScript = load("res://scripts/ai/ai_controller.gd")
		if AIControllerScript:
			ai_controller = AIControllerScript.new()
			ai_controller.name = "AIController"
			add_child(ai_controller)
			
			# Initialize it with required dependencies
			var phase_manager = get_service("PhaseManager")
			ai_controller.initialize(
				ai_opponent,
				base_ui_manager,
				phase_manager,
				player_manager
			)
	
	# Make sure AIController is registered
	if ai_controller and !has_service("AIController"):
		print("GameManager: Registering AIController service")
		register_service("AIController", ai_controller)
	
	# Verify we have a working AI controller
	var controller = get_service("AIController")
	if controller and controller.has_method("process_ai_turn_if_needed"):
		print("GameManager: AIController successfully registered")
	else:
		push_error("GameManager: Failed to register a working AIController!")

# Add this helper function to verify all important connections
func _ensure_all_essential_connections():
	# Check that weapon_placement has game_board reference
	var weapon_placement = get_service("WeaponPlacement")
	var game_board = get_service("GameBoard")
	
	if weapon_placement and game_board:
		# Check if weapon_placement has a "game_board" property and it's null
		if "game_board" in weapon_placement and not weapon_placement.game_board:
			print("GameManager: Fixing missing game_board reference in WeaponPlacement")
			weapon_placement.game_board = game_board
	
	# Add similar checks for other critical components as needed

# Make sure to explicitly register TargetingState during initialization
func register_core_services():
	# Ensure TargetingState is correctly registered
	print("GameManager: Double-checking TargetingState registration")
	var targeting_state = get_service("TargetingState")
	if targeting_state and targeting_state.has_method("start_targeting"):
		print("GameManager: TargetingState properly registered with correct methods")
	else:
		print("GameManager: TargetingState missing or has incorrect methods, re-registering")
		# Try to find targeting_state in the scene
		var found_targeting_state = get_node_or_null("/root/Main/TargetingState")
		if found_targeting_state:
			register_service("TargetingState", found_targeting_state)
		else:
			print("GameManager: WARNING - Could not find TargetingState in scene tree")
