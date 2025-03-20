class_name InitializationController
extends Node

signal stage_completed(stage_name)
signal all_stages_completed
signal initialization_failed(stage_name, reason)

enum Stage {
	CORE_SYSTEMS,     # Game board, player manager
	WEAPON_SYSTEMS,   # Weapon types, placement
	STATE_SYSTEMS,    # Placement, targeting, attack states
	AI_SYSTEMS,       # AI opponent and controllers
	UI_SYSTEMS,       # UI managers
	SIGNAL_BINDING    # Connect all signals
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
	"GameStateMachine": ["GameBoard", "WeaponTypes", "WeaponPlacement", "TargetingState", "AttackState", "BaseUIManager", "PlayerManager"]
}

var _game_manager = null

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
		return { "success": true, "missing": [] }
		
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
	placement_state.initialize(_game_manager.weapon_types, _game_manager.weapon_placement, weapon_buttons)
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
	
	return advance_to_next_stage()

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
	
	return advance_to_next_stage()
