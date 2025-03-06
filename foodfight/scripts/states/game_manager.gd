extends Node

# Signals
signal game_initialized
signal component_initialized(component_name)

# Component references
var game_board
var game_state_machine
var game_ui_manager
var player_manager
var placement_state
var targeting_state
var attack_state
var weapon_manager
var targeting_manager
var targeting_visualization
var weapon_types
var weapon_placement

# State tracking
var initialization_complete = false
var current_scene = null
var main_scene_path = "res://scenes/main.tscn"

func _ready():
	print("GameManager singleton initialized")
	# Connect to the scene tree to detect when the scene changes
	get_tree().root.connect("ready", Callable(self, "_on_scene_tree_ready"))

func _on_scene_tree_ready():
	print("Scene tree ready")
	# Wait a frame to ensure everything is loaded
	await get_tree().process_frame
	current_scene = get_tree().current_scene
	print("Current scene: ", current_scene.name)

# This function should be called from main.gd after the scene is ready
func initialize_game(main_node):
	print("Starting game initialization...")
	
	# PHASE 1: Get references to all components from the main scene
	if !get_component_references(main_node):
		push_error("Failed to get component references")
		return false
	
	# Wait to ensure all scripts are attached
	print("Phase 1 complete: References collected")
	print("Waiting for scripts to fully initialize...")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout  # Half-second delay
	
	# PHASE 2: Initialize components in the correct order
	print("Phase 2 starting: Component initialization")
	# Add await here
	if !await initialize_components():
		push_error("Failed to initialize components")
		return false
	
	# Mark initialization as complete
	initialization_complete = true
	print("Game initialization complete!")
	
	# Signal that initialization is done
	emit_signal("game_initialized")
	
	return initialization_complete

# PHASE 1: Get references to all game components
func get_component_references(main_node):
	print("Phase 1: Collecting component references...")
	
	if not main_node:
		push_error("Main node reference is null")
		return false
	
	# Get references to components
	game_board = main_node.get_node_or_null("GameBoard")
	game_state_machine = main_node.get_node_or_null("GameStateMachine")
	game_ui_manager = main_node.get_node_or_null("GameUIManager")
	player_manager = main_node.get_node_or_null("PlayerManager")
	placement_state = main_node.get_node_or_null("PlacementState")
	targeting_state = main_node.get_node_or_null("TargetingState")
	attack_state = main_node.get_node_or_null("AttackState")
	weapon_types = main_node.get_node_or_null("WeaponTypes")
	weapon_placement = main_node.get_node_or_null("WeaponPlacement")
	targeting_visualization = main_node.get_node_or_null("TargetingVisualization")
	
	# Get nested components
	if attack_state:
		weapon_manager = attack_state.get_node_or_null("WeaponManager")
		targeting_manager = attack_state.get_node_or_null("TargetingManager")
	
	# Verify all necessary components exist
	var all_components_found = true
	
	# Critical components - these must exist
	if not game_board: 
		push_error("GameBoard not found")
		all_components_found = false
	
	if not game_state_machine: 
		push_error("GameStateMachine not found")
		all_components_found = false
	
	if not weapon_types: 
		push_error("WeaponTypes not found")
		all_components_found = false
	
	if not weapon_placement: 
		push_error("WeaponPlacement not found")
		all_components_found = false
	
	# Important but not critical components
	if not game_ui_manager: print("Warning: GameUIManager not found")
	if not player_manager: print("Warning: PlayerManager not found")
	if not placement_state: print("Warning: PlacementState not found")
	if not targeting_state: print("Warning: TargetingState not found")
	if not attack_state: print("Warning: AttackState not found")
	if not weapon_manager: print("Warning: WeaponManager not found")
	if not targeting_manager: print("Warning: TargetingManager not found")
	if not targeting_visualization: print("Warning: TargetingVisualization not found")
	
	# Print component reference status for debugging
	print("Game Board: ", game_board != null)
	print("Game State Machine: ", game_state_machine != null)
	print("Game UI Manager: ", game_ui_manager != null)
	print("Player Manager: ", player_manager != null)
	print("Placement State: ", placement_state != null)
	print("Targeting State: ", targeting_state != null)
	print("Attack State: ", attack_state != null)
	print("Weapon Manager: ", weapon_manager != null)
	print("Targeting Manager: ", targeting_manager != null)
	print("Weapon Types: ", weapon_types != null)
	print("Weapon Placement: ", weapon_placement != null)
	print("Targeting Visualization: ", targeting_visualization != null)
	
	return all_components_found

# PHASE 2: Initialize all components in the correct order
func initialize_components():
	print("Phase 2: Initializing components in order...")
	
	# Verify scripts are attached to critical components
	if !verify_scripts_attached():
		push_error("Some components are missing their scripts!")
		return false
	
	# 1. Initialize the game board first (no dependencies)
	if game_board and game_board.has_method("initialize_grid"):
		print("Initializing GameBoard...")
		game_board.initialize_grid()
		emit_signal("component_initialized", "GameBoard")
	
	# 2. Initialize player manager (no dependencies)
	if player_manager:
		print("Player Manager ready")
		emit_signal("component_initialized", "PlayerManager")
	
	# 3. Wait a frame between initializations
	await get_tree().process_frame
	
	# 4. Initialize weapon systems
	if weapon_placement and weapon_placement.has_method("initialize"):
		print("Initializing Weapon Placement...")
		weapon_placement.initialize(game_board, weapon_types)
		emit_signal("component_initialized", "WeaponPlacement")
	
	# 5. Initialize weapon manager
	if weapon_manager and weapon_manager.has_method("initialize"):
		print("Initializing Weapon Manager...")
		weapon_manager.initialize(game_board)
		emit_signal("component_initialized", "WeaponManager")
	else:
		print("Warning: WeaponManager not initialized (missing method or node)")
	
	# 6. Initialize targeting manager
	if targeting_manager and targeting_manager.has_method("initialize"):
		print("Initializing Targeting Manager...")
		targeting_manager.initialize(game_board)
		emit_signal("component_initialized", "TargetingManager")
	else:
		print("Warning: TargetingManager not initialized (missing method or node)")
	
	# 7. Wait another frame for initialization
	await get_tree().process_frame
	
	# 8. Initialize placement state
	if placement_state and placement_state.has_method("initialize"):
		print("Initializing Placement State...")
		# Get the weapon buttons container directly from the main scene
		var main_scene = get_tree().current_scene
		var weapon_buttons = null
		
		if main_scene and main_scene.has_node("UI/BottomBar/WeaponButtonsContainer"):
			weapon_buttons = main_scene.get_node("UI/BottomBar/WeaponButtonsContainer")
			print("Found weapon_buttons_container: ", weapon_buttons != null)
		else:
			print("Warning: Could not find weapon_buttons_container in scene")
		
		placement_state.initialize(weapon_types, weapon_placement, weapon_buttons)
		emit_signal("component_initialized", "PlacementState")
	else:
		print("Warning: PlacementState not initialized (missing method or node)")
	
	# 9. Initialize targeting state
	if targeting_state and targeting_state.has_method("initialize"):
		print("Initializing Targeting State...")
		targeting_state.initialize(game_board, weapon_manager, targeting_manager, targeting_visualization)
		emit_signal("component_initialized", "TargetingState")
	else:
		print("Warning: TargetingState not initialized (missing method or node)")
	
	# 10. Initialize attack state
	if attack_state and attack_state.has_method("initialize"):
		print("Initializing Attack State...")
		attack_state.initialize(game_board, weapon_types)
		emit_signal("component_initialized", "AttackState")
	else:
		print("Warning: AttackState not initialized (missing method or node)")
	
	# 11. Initialize targeting visualization
	if targeting_visualization and targeting_visualization.has_method("initialize"):
		print("Initializing Targeting Visualization...")
		targeting_visualization.initialize(game_board, attack_state)
		emit_signal("component_initialized", "TargetingVisualization")
	else:
		print("Warning: TargetingVisualization not initialized (missing method or node)")
	
	# 12. Wait a final frame
	await get_tree().process_frame
	
	# 13. Initialize game state machine (depends on everything)
	if game_state_machine and game_state_machine.has_method("initialize"):
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
	else:
		print("Warning: GameStateMachine not initialized (missing method or node)")
	
	# 14. Connect signals between components
	connect_component_signals()
	
	print("All components initialized")
	return true

# Verify that scripts are attached to components
func verify_scripts_attached():
	print("Verifying scripts are attached to components...")
	
	var all_scripts_attached = true
	
	# Check critical components
	if game_board and !game_board.get_script():
		push_error("GameBoard is missing its script!")
		all_scripts_attached = false
	
	if game_state_machine and !game_state_machine.get_script():
		push_error("GameStateMachine is missing its script!")
		all_scripts_attached = false
	
	if weapon_types and !weapon_types.get_script():
		push_error("WeaponTypes is missing its script!")
		all_scripts_attached = false
	
	if weapon_placement and !weapon_placement.get_script():
		push_error("WeaponPlacement is missing its script!")
		all_scripts_attached = false
	
	# Check other components
	if weapon_manager:
		print("WeaponManager script attached: ", weapon_manager.get_script() != null)
		if !weapon_manager.get_script():
			push_error("WeaponManager is missing its script!")
			all_scripts_attached = false
	
	if targeting_manager:
		print("TargetingManager script attached: ", targeting_manager.get_script() != null)
		if !targeting_manager.get_script():
			push_error("TargetingManager is missing its script!")
			all_scripts_attached = false
	
	if placement_state:
		print("PlacementState script attached: ", placement_state.get_script() != null)
		if !placement_state.get_script():
			push_error("PlacementState is missing its script!")
			all_scripts_attached = false
	
	if targeting_state:
		print("TargetingState script attached: ", targeting_state.get_script() != null)
		if !targeting_state.get_script():
			push_error("TargetingState is missing its script!")
			all_scripts_attached = false
	
	if attack_state:
		print("AttackState script attached: ", attack_state.get_script() != null)
		if !attack_state.get_script():
			push_error("AttackState is missing its script!")
			all_scripts_attached = false
	
	return all_scripts_attached

# Connect signals between components
func connect_component_signals():
	print("Connecting component signals...")

	# Connect end placement button
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_node("UI/BottomBar/EndPlacementButton"):
		var end_placement_button = main_scene.get_node("UI/BottomBar/EndPlacementButton")
		if end_placement_button and game_state_machine and !end_placement_button.is_connected("pressed", Callable(game_state_machine, "placement_completed")):
			print("Connecting End Placement button to GameStateMachine")
			end_placement_button.pressed.connect(Callable(game_state_machine, "placement_completed"))
		else:
			print("Warning: Could not connect End Placement button")
	
	# Connect end targeting button
	if main_scene and main_scene.has_node("UI/BottomBar/EndTargetingButton"):
		var end_targeting_button = main_scene.get_node("UI/BottomBar/EndTargetingButton")
		if end_targeting_button and targeting_state and !end_targeting_button.is_connected("pressed", Callable(targeting_state, "on_end_targeting_button_pressed")):
			print("Connecting End Targeting button to TargetingState")
			end_targeting_button.pressed.connect(Callable(targeting_state, "on_end_targeting_button_pressed"))
		else:
			print("Warning: Could not connect End Targeting button")
			
	# Connect weapon placement signals to game state machine
	if weapon_placement and game_state_machine:
		if !weapon_placement.is_connected("weapon_placed", Callable(game_state_machine, "_on_weapon_placed")):
			weapon_placement.connect("weapon_placed", Callable(game_state_machine, "_on_weapon_placed"))
		
		if !weapon_placement.is_connected("resource_updated", Callable(game_state_machine, "_on_resource_updated")):
			weapon_placement.connect("resource_updated", Callable(game_state_machine, "_on_resource_updated"))
	
	# Connect targeting state signals to game state machine
	if targeting_state and game_state_machine:
		if !targeting_state.is_connected("targeting_completed", Callable(game_state_machine, "_on_targeting_completed")):
			targeting_state.connect("targeting_completed", Callable(game_state_machine, "_on_targeting_completed"))
			print("Connected TargetingState.targeting_completed to GameStateMachine._on_targeting_completed")
	
	# Connect targeting manager signals to targeting state
	if targeting_manager and targeting_state:
		if !targeting_manager.is_connected("target_selected", Callable(targeting_state, "_on_target_selected")):
			targeting_manager.connect("target_selected", Callable(targeting_state, "_on_target_selected"))
			print("Connected TargetingManager.target_selected to TargetingState._on_target_selected")
	
	# Connect targeting state signals to main scene for UI updates
	if main_scene and targeting_state:
		if !targeting_state.is_connected("player_turn_started", Callable(main_scene, "create_targeting_buttons")):
			targeting_state.connect("player_turn_started", Callable(main_scene, "create_targeting_buttons"))
			print("Connected TargetingState.player_turn_started to Main.create_targeting_buttons")
	
	# Connect attack state signals
	if attack_state and targeting_visualization:
		if !attack_state.is_connected("attack_executed", Callable(targeting_visualization, "_on_attack_executed")):
			attack_state.connect("attack_executed", Callable(targeting_visualization, "_on_attack_executed"))
	
	if attack_state and game_state_machine:
		if !attack_state.is_connected("attack_completed", Callable(game_state_machine, "_on_attack_completed")):
			attack_state.connect("attack_completed", Callable(game_state_machine, "_on_attack_completed"))
	print("Connecting component signals...")

	# Connect end placement button
	if main_scene and main_scene.has_node("UI/BottomBar/EndPlacementButton"):
		var end_button = main_scene.get_node("UI/BottomBar/EndPlacementButton")
		if end_button and game_state_machine and !end_button.is_connected("pressed", Callable(game_state_machine, "placement_completed")):
			print("Connecting End Placement button to GameStateMachine")
			end_button.pressed.connect(Callable(game_state_machine, "placement_completed"))
		else:
			print("Warning: Could not connect End Placement button")
			
	# Connect weapon placement signals to game state machine
	if weapon_placement and game_state_machine:
		if !weapon_placement.is_connected("weapon_placed", Callable(game_state_machine, "_on_weapon_placed")):
			weapon_placement.connect("weapon_placed", Callable(game_state_machine, "_on_weapon_placed"))
		
		if !weapon_placement.is_connected("resource_updated", Callable(game_state_machine, "_on_resource_updated")):
			weapon_placement.connect("resource_updated", Callable(game_state_machine, "_on_resource_updated"))
	
	# Connect targeting state signals to game state machine
	if targeting_state and game_state_machine:
		if !targeting_state.is_connected("targeting_completed", Callable(game_state_machine, "_on_targeting_completed")):
			targeting_state.connect("targeting_completed", Callable(game_state_machine, "_on_targeting_completed"))
			print("Connected TargetingState.targeting_completed to GameStateMachine._on_targeting_completed")
	
	# Connect targeting manager signals to targeting state
	if targeting_manager and targeting_state:
		if !targeting_manager.is_connected("target_selected", Callable(targeting_state, "_on_target_selected")):
			targeting_manager.connect("target_selected", Callable(targeting_state, "_on_target_selected"))
			print("Connected TargetingManager.target_selected to TargetingState._on_target_selected")
	
	# Connect targeting state signals to main scene for UI updates
	if main_scene and targeting_state:
		if !targeting_state.is_connected("player_turn_started", Callable(main_scene, "create_attack_buttons")):
			targeting_state.connect("player_turn_started", Callable(main_scene, "create_attack_buttons"))
			print("Connected TargetingState.player_turn_started to Main.create_attack_buttons")
	
	# Connect attack state signals
	if attack_state and targeting_visualization:
		if !attack_state.is_connected("attack_executed", Callable(targeting_visualization, "_on_attack_executed")):
			attack_state.connect("attack_executed", Callable(targeting_visualization, "_on_attack_executed"))
	
	if attack_state and game_state_machine:
		if !attack_state.is_connected("attack_completed", Callable(game_state_machine, "_on_attack_completed")):
			attack_state.connect("attack_completed", Callable(game_state_machine, "_on_attack_completed"))

# Start the game
func start_game():
	if !initialization_complete:
		push_error("Cannot start game - not initialized")
		return
	
	print("Starting game...")
	
	# Start with game state machine
	if game_state_machine and game_state_machine.has_method("start_game"):
		game_state_machine.start_game()
	else:
		push_error("Cannot start game - GameStateMachine missing start_game method")

# Helper function to safely call methods if they exist
func call_if_exists(object, method_name, args = []):
	if object and object.has_method(method_name):
		if args.size() > 0:
			return object.callv(method_name, args)
		else:
			return object.call(method_name)
	return null
