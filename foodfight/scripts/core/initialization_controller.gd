class_name InitializationController
extends Node

signal stage_completed(stage_name)
signal all_stages_completed
signal initialization_failed(stage_name, reason)

enum Stage {
	CORE_SYSTEMS, # Game board, player manager
	WEAPON_SYSTEMS, # Weapon types, placement
	STATE_SYSTEMS, # Placement, targeting, attack states
	AI_SYSTEMS, # AI opponent and controllers
	UI_SYSTEMS, # UI managers
	SIGNAL_BINDING # Connect all signals
}

var current_stage = -1
var stages_completed = []
var initialization_errors = {}
var required_dependencies = {
	"GameBoard": [],
	"PlayerManager": [],
	"WeaponTypes": [],
	"WeaponPlacement": ["GameBoard", "WeaponTypes"],
	"WeaponManager": ["GameBoard"],
	"TargetingManager": ["GameBoard"],
	"PlacementState": ["WeaponTypes", "WeaponPlacement"],
	"TargetingState": ["GameBoard", "WeaponManager", "TargetingManager"],
	"AttackState": ["GameBoard", "WeaponTypes"],
	"AIOpponent": ["GameBoard", "WeaponTypes", "WeaponPlacement", "PlayerManager", "TargetingManager"],
	"GameStateMachine": ["GameBoard", "WeaponTypes", "WeaponPlacement", "TargetingState", "AttackState", "BaseUIManager", "PlayerManager"],
	"PhaseManager": ["GameBoard", "WeaponTypes", "WeaponPlacement", "PlayerManager", "EventBus"]
}

var _game_manager = null

# Use load() instead of preload() for scripts that might have circular dependencies
var PhaseManagerScript = load("res://scripts/states/phase_manager.gd")

func _init(game_manager):
	_game_manager = game_manager

func start_initialization():
	current_stage = Stage.CORE_SYSTEMS
	return process_current_stage()

func process_current_stage() -> bool:
	match current_stage:
		Stage.CORE_SYSTEMS:
			return initialize_core_systems()
		Stage.WEAPON_SYSTEMS:
			return initialize_weapon_systems()
		Stage.STATE_SYSTEMS:
			return initialize_state_systems()
		Stage.AI_SYSTEMS:
			return initialize_ai_systems()
		Stage.UI_SYSTEMS:
			return initialize_ui_systems()
		Stage.SIGNAL_BINDING:
			return connect_signals()
		_:
			push_error("Unknown initialization stage: " + str(current_stage))
			emit_signal("initialization_failed", "Unknown", "Invalid stage index")
			return false

func advance_to_next_stage() -> bool:
	var current_stage_name = Stage.keys()[current_stage]
	stages_completed.append(current_stage_name)
	emit_signal("stage_completed", current_stage_name)
	
	current_stage += 1
	if current_stage >= Stage.size():
		emit_signal("all_stages_completed")
		return true
		
	return process_current_stage()

func check_dependencies(component_name: String) -> Dictionary:
	if not required_dependencies.has(component_name):
		return {"success": true, "missing": []}
		
	var missing = []
	for dependency in required_dependencies[component_name]:
		if not _game_manager.has_service(dependency):
			missing.append(dependency)
	
	return {
		"success": missing.size() == 0,
		"missing": missing
	}

# Stage implementation methods
func initialize_core_systems() -> bool:
	# Initialize EventBus first before any other service that might use it
	_initialize_service("EventBus")
	_initialize_service("GameBoard")
	_initialize_service("PlayerManager")
	
	# Initialize game board (no dependencies)
	_game_manager.game_board.initialize_grid()
	_game_manager.register_service("GameBoard", _game_manager.game_board)
	
	# Initialize player manager (no dependencies)
	_game_manager.player_manager.set_player_type(1, _game_manager.player_manager.PlayerType.AI)
	_game_manager.player_manager.set_player_name(1, "AI OPPONENT")
	_game_manager.register_service("PlayerManager", _game_manager.player_manager)
	
	return advance_to_next_stage()

func initialize_weapon_systems() -> bool:
	# Initialize weapon types (no dependencies)
	_game_manager.register_service("WeaponTypes", _game_manager.weapon_types)
	
	# Initialize weapon placement
	var weapon_placement = _game_manager.weapon_placement
	var dep_check = check_dependencies("WeaponPlacement")
	if not dep_check.success:
		emit_signal("initialization_failed", "WeaponPlacement", "Missing dependencies: " + str(dep_check.missing))
		return false
	
	weapon_placement.initialize(_game_manager.game_board, _game_manager.weapon_types)
	_game_manager.register_service("WeaponPlacement", weapon_placement)
	
	return advance_to_next_stage()

func initialize_state_systems() -> bool:
	# Initialize weapon manager
	var weapon_manager = _game_manager.weapon_manager
	var dep_check = check_dependencies("WeaponManager")
	if not dep_check.success:
		emit_signal("initialization_failed", "WeaponManager", "Missing dependencies: " + str(dep_check.missing))
		return false
	
	weapon_manager.initialize(_game_manager.game_board)
	_game_manager.register_service("WeaponManager", weapon_manager)
	
	# Initialize targeting manager
	var targeting_manager = _game_manager.targeting_manager
	dep_check = check_dependencies("TargetingManager")
	if not dep_check.success:
		emit_signal("initialization_failed", "TargetingManager", "Missing dependencies: " + str(dep_check.missing))
		return false
	
	targeting_manager.initialize(_game_manager.game_board)
	_game_manager.register_service("TargetingManager", targeting_manager)
	
	# Initialize placement state
	var placement_state = _game_manager.placement_state
	dep_check = check_dependencies("PlacementState")
	if not dep_check.success:
		emit_signal("initialization_failed", "PlacementState", "Missing dependencies: " + str(dep_check.missing))
		return false
	
	var main_scene = _game_manager.get_tree().current_scene
	var weapon_buttons = main_scene.get_node("UI/BottomBar/WeaponButtonsContainer")
	placement_state.initialize(
		_game_manager.weapon_types,
		_game_manager.weapon_placement,
		weapon_buttons,
		_game_manager.player_manager # Added the missing argument
	)
	_game_manager.register_service("PlacementState", placement_state)
	
	# Initialize targeting state
	var targeting_state = _game_manager.targeting_state
	dep_check = check_dependencies("TargetingState")
	if not dep_check.success:
		emit_signal("initialization_failed", "TargetingState", "Missing dependencies: " + str(dep_check.missing))
		return false
	
	targeting_state.initialize(_game_manager.game_board, weapon_manager, targeting_manager)
	_game_manager.register_service("TargetingState", targeting_state)
	
	# Initialize attack state
	var attack_state = _game_manager.attack_state
	dep_check = check_dependencies("AttackState")
	if not dep_check.success:
		emit_signal("initialization_failed", "AttackState", "Missing dependencies: " + str(dep_check.missing))
		return false
	
	attack_state.initialize(_game_manager.game_board, _game_manager.weapon_types)
	_game_manager.register_service("AttackState", attack_state)
	
	# Initialize PhaseManager after EventBus and all other state systems
	_initialize_phase_manager()
	
	return advance_to_next_stage()

# Added new method to initialize PhaseManager correctly
func _initialize_phase_manager():
	# Get the PhaseManager from the main scene
	var main_scene = _game_manager.get_tree().current_scene
	var phase_manager = main_scene.get_node_or_null("PhaseManager")
	
	if phase_manager:
		# Check dependencies
		var dep_check = check_dependencies("PhaseManager")
		if not dep_check.success:
			push_error("PhaseManager missing dependencies: " + str(dep_check.missing))
			# Continue anyway - we'll try to recover
		
		# Initialize PhaseManager with all dependencies
		phase_manager.initialize(
			_game_manager.game_board,
			_game_manager.weapon_types,
			_game_manager.weapon_placement,
			_game_manager.targeting_state,
			_game_manager.attack_state,
			_game_manager.base_ui_manager,
			_game_manager.player_manager
		)
		
		# Register as service
		_game_manager.register_service("PhaseManager", phase_manager)
		
		# Explicitly connect to EventBus
		if phase_manager and phase_manager.has_method("_subscribe_to_events"):
			phase_manager._subscribe_to_events()
			print("Explicitly connected PhaseManager to EventBus")
	else:
		push_error("PhaseManager not found in main scene")

func initialize_ai_systems() -> bool:
	# Initialize AI opponent
	var ai_opponent = _game_manager.ai_opponent
	if ai_opponent:
		var dep_check = check_dependencies("AIOpponent")
		if not dep_check.success:
			emit_signal("initialization_failed", "AIOpponent", "Missing dependencies: " + str(dep_check.missing))
			return false
		
		ai_opponent.initialize(
			_game_manager.game_board,
			_game_manager.weapon_types,
			_game_manager.weapon_placement,
			_game_manager.player_manager,
			_game_manager.targeting_manager
		)
		ai_opponent.set_difficulty(_game_manager.ai_difficulty)
		_game_manager.register_service("AIOpponent", ai_opponent)
	
	return advance_to_next_stage()

func initialize_ui_systems() -> bool:
	# Initialize game UI manager
	if _game_manager.base_ui_manager:
		_game_manager.register_service("BaseUIManager", _game_manager.base_ui_manager)
		
		# Important: Initialize and register PhaseUIManager BEFORE proceeding
		var phase_ui_manager = _game_manager.base_ui_manager.get_node_or_null("PhaseUIManager")
		if phase_ui_manager:
			print("PhaseUIManager found in BaseUIManager")
			_game_manager.register_service("PhaseUIManager", phase_ui_manager)
		else:
			print("PhaseUIManager not found in BaseUIManager")
		
		# Initialize other UI managers here
		var player_ui_manager = _game_manager.base_ui_manager.get_node_or_null("PlayerUIManager")
		if player_ui_manager:
			_game_manager.register_service("PlayerUIManager", player_ui_manager)
			
		var placement_ui_manager = _game_manager.base_ui_manager.get_node_or_null("PlacementUIManager")
		if placement_ui_manager:
			_game_manager.register_service("PlacementUIManager", placement_ui_manager)
	else:
		# Create a default UI manager if needed
		var main_scene = _game_manager.get_tree().current_scene
		var base_ui_manager = Node.new()
		base_ui_manager.name = "BaseUIManager"
		base_ui_manager.set_script(load("res://scripts/ui/base_ui_manager.gd"))
		main_scene.add_child(base_ui_manager)
		_game_manager.base_ui_manager = base_ui_manager
		_game_manager.register_service("BaseUIManager", base_ui_manager)
	
	return advance_to_next_stage()

func connect_signals() -> bool:
	# Initialize game state machine (depends on everything)
	var game_state_machine = _game_manager.game_state_machine
	var dep_check = check_dependencies("GameStateMachine")
	if not dep_check.success:
		emit_signal("initialization_failed", "GameStateMachine", "Missing dependencies: " + str(dep_check.missing))
		return false
	
	game_state_machine.initialize(
		_game_manager.game_board,
		_game_manager.weapon_types,
		_game_manager.weapon_placement,
		_game_manager.targeting_state,
		_game_manager.attack_state,
		_game_manager.base_ui_manager,
		_game_manager.player_manager
	)
	
	# Set single player mode in game state machine
	game_state_machine.set_single_player_mode(true)
	_game_manager.register_service("GameStateMachine", game_state_machine)
	
	# Make sure player_manager is properly set for GameStateMachine
	game_state_machine.player_manager = _game_manager.player_manager
	
	# Get references to turn_manager and ai_controller after game_state_machine initialization
	_game_manager.turn_manager = game_state_machine.turn_manager
	_game_manager.ai_controller = game_state_machine.ai_controller
	
	if _game_manager.turn_manager:
		_game_manager.register_service("TurnManager", _game_manager.turn_manager)
	
	if _game_manager.ai_controller:
		_game_manager.register_service("AIController", _game_manager.ai_controller)
	
	# Connect UI buttons
	_game_manager.connect_component_signals()
	
	# Make sure UI is updated correctly for the initial game state
	var base_ui_manager = _game_manager.get_service("BaseUIManager")
	if base_ui_manager and base_ui_manager.has_method("update_ui"):
		_game_manager.update_ui(game_state_machine.GameState.BASE_PLACEMENT, 0)
	else:
		push_error("No BaseUIManager available for UI update!")
	
	# Ensure PhaseManager connects to EventBus properly
	var phase_manager = _game_manager.get_service("PhaseManager")
	if phase_manager and phase_manager.has_method("_subscribe_to_events"):
		phase_manager._subscribe_to_events()
		print("Final check: Ensuring PhaseManager is connected to EventBus")
	
	return advance_to_next_stage()

# Method to handle service initialization
func _initialize_service(service_name):
	print("Initializing service: " + service_name)
	
	# Special case for critical services
	if service_name == "EventBus":
		# Make sure EventBus is created first
		var event_bus = _game_manager.event_bus
		if event_bus:
			_game_manager.register_service("EventBus", event_bus)
		else:
			push_error("Failed to initialize EventBus")
	
	# For PhaseManager specifically, ensure it's properly connected to EventBus
	elif service_name == "PhaseManager":
		var phase_manager = _game_manager.get_service("PhaseManager")
		if phase_manager and phase_manager.has_method("_subscribe_to_events"):
			phase_manager._subscribe_to_events()
			print("Explicitly connected PhaseManager to EventBus")
	
	# Return true indicating success
	return true
