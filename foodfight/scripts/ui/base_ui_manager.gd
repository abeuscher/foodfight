# Ensure the class_name is loaded for proper resolution
class_name BaseUIManager
extends BaseUIListener

# Core UI element references
var top_bar_panel
var bottom_bar_panel
var title_screen

# Child UI managers
var player_ui_manager
var phase_ui_manager
var placement_ui_manager
var targeting_ui_manager
var ai_ui_manager

# Initialization flag
var is_initialized = false
var is_initializing = false

# Recursion guards - class level tracking of active method calls
var _active_method_calls = {}

# UI visibility state tracking
var _ui_states = {
	"weapon_buttons_visible": false,
	"targeting_buttons_visible": false,
	"end_placement_visible": false,
	"end_targeting_visible": false
}

func _ready():
	# Call parent ready first, which will register events
	super._ready()
	
	# Mark that initialization has started
	is_initializing = true
	print("BaseUIManager: Starting initialization")
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Initialize UI references
	_initialize_scene_references()
	
	# Create and initialize child managers
	_initialize_child_managers()
	
	is_initialized = true
	is_initializing = false
	print("Base UI Manager initialized")
	
	# Register self as BaseUIManager service
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.register_service("BaseUIManager", self)
		print("BaseUIManager registered as BaseUIManager service")
		
		# Also register child managers as services
		if phase_ui_manager:
			game_manager.register_service("PhaseUIManager", phase_ui_manager)
		if player_ui_manager:
			game_manager.register_service("PlayerUIManager", player_ui_manager)
		if placement_ui_manager:
			game_manager.register_service("PlacementUIManager", placement_ui_manager)
		
		# Initialize placement state with weapon buttons container
		var placement_state = get_service("PlacementState")
		var weapon_buttons_container = get_weapon_buttons_container()
		
		if placement_state and weapon_buttons_container:
			print("BaseUIManager: Registering weapon buttons container with PlacementState")
			if not placement_state.weapon_buttons_container:
				placement_state.weapon_buttons_container = weapon_buttons_container

# Initialize references to scene nodes - simplified to focus on UI elements
func _initialize_scene_references():
	# Get UI references from scene tree
	var main_node = get_tree().get_root().get_node_or_null("Main")
	
	if main_node:
		# Get top and bottom bar elements
		top_bar_panel = main_node.get_node_or_null("UI/TopBar")
		bottom_bar_panel = main_node.get_node_or_null("UI/BottomBar")
		
		# Get title screen
		title_screen = main_node.get_node_or_null("UI/TitleScreen")
		if title_screen and title_screen.has_signal("animation_completed"):
			if !title_screen.is_connected("animation_completed", Callable(self, "_on_title_screen_animation_completed")):
				title_screen.connect("animation_completed", Callable(self, "_on_title_screen_animation_completed"))

# Initialize child UI manager components
func _initialize_child_managers():
	print("====== Creating UI manager children ======")
	
	# Create player UI manager if not exists
	if !player_ui_manager:
		player_ui_manager = Node.new()
		player_ui_manager.name = "PlayerUIManager"
		player_ui_manager.set_script(load("res://scripts/ui/player_ui_manager.gd"))
		add_child(player_ui_manager)
	
	# Create phase UI manager if not exists
	if !phase_ui_manager:
		print("  - Creating new PhaseUIManager")
		phase_ui_manager = Node.new()
		phase_ui_manager.name = "PhaseUIManager"
		phase_ui_manager.set_script(load("res://scripts/ui/phase_ui_manager.gd"))
		add_child(phase_ui_manager)
	else:
		print("  - PhaseUIManager already exists")
	
	# Create placement UI manager if not exists
	if !placement_ui_manager:
		placement_ui_manager = Node.new()
		placement_ui_manager.name = "PlacementUIManager"
		placement_ui_manager.set_script(load("res://scripts/ui/placement_ui_manager.gd"))
		add_child(placement_ui_manager)
	
	# Create targeting UI manager if not exists
	if !targeting_ui_manager:
		targeting_ui_manager = Node.new()
		targeting_ui_manager.name = "TargetingUIManager"
		targeting_ui_manager.set_script(load("res://scripts/ui/targeting_ui_manager.gd"))
		add_child(targeting_ui_manager)
	
	# Create AI UI manager if not exists
	if !ai_ui_manager:
		ai_ui_manager = Node.new()
		ai_ui_manager.name = "AIUIManager"
		ai_ui_manager.set_script(load("res://scripts/ai/ai_ui_manager.gd"))
		add_child(ai_ui_manager)
		
	# Initialize the child managers
	initialize_ui_components()

# Add this function to create and initialize all UI child managers
func initialize_ui_components():
	print("====== Initializing UI components ======")
	
	# Get UI elements from the scene
	var main_node = get_tree().root.get_node_or_null("Main")
	if !main_node:
		print("ERROR: Cannot find Main node")
		return
	
	# Get UI elements needed by child managers
	var turn_label = main_node.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel")
	var phase_label = main_node.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
	
	var p1_name_label = main_node.get_node_or_null("UI/TopBar/HBoxContainer/Player1Container/NameLabel")
	var p2_name_label = main_node.get_node_or_null("UI/TopBar/HBoxContainer/Player2Container/NameLabel")
	var p1_score_label = main_node.get_node_or_null("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel")
	var p2_score_label = main_node.get_node_or_null("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel")
	
	var weapon_buttons_container = main_node.get_node_or_null("UI/BottomBar/WeaponButtonsContainer")
	var end_placement_button = main_node.get_node_or_null("UI/BottomBar/EndPlacementButton")
	var targeting_buttons_container = main_node.get_node_or_null("UI/BottomBar/TargetingButtonsContainer")
	var end_targeting_button = main_node.get_node_or_null("UI/BottomBar/EndTargetingButton")
	
	# Get dependencies from services
	var player_manager = get_service("PlayerManager")
	var weapon_placement = get_service("WeaponPlacement")
	var weapon_types = get_service("WeaponTypes")
	var weapon_manager = get_service("WeaponManager")
	var targeting_manager = get_service("TargetingManager")
	var targeting_state = get_service("TargetingState")
	
	# Initialize PhaseUIManager
	if phase_ui_manager:
		print("  - Initializing PhaseUIManager")
		phase_ui_manager.initialize(turn_label, phase_label, title_screen, player_manager)
		print("  - PhaseUIManager initialized")
		
		# Register with GameManager
		var game_manager = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
		if game_manager:
			game_manager.register_service("PhaseUIManager", phase_ui_manager)
			print("PhaseUIManager registered as service")
	
	# Initialize PlayerUIManager
	if player_ui_manager and player_manager:
		print("  - Initializing PlayerUIManager")
		player_ui_manager.initialize(p1_name_label, p2_name_label, p1_score_label, p2_score_label, player_manager)
		print("  - PlayerUIManager initialized")
	
	# Initialize PlacementUIManager
	if placement_ui_manager:
		print("  - Initializing PlacementUIManager")
		placement_ui_manager.initialize(weapon_buttons_container, end_placement_button,
									   weapon_placement, weapon_types, player_manager, main_node)
		print("  - PlacementUIManager initialized")
	
	# Initialize TargetingUIManager
	if targeting_ui_manager:
		print("  - Initializing TargetingUIManager")
		targeting_ui_manager.initialize(targeting_buttons_container, end_targeting_button,
									   weapon_manager, targeting_manager, targeting_state, player_manager, main_node)
		print("  - TargetingUIManager initialized")
	
	# Initialize AIUIManager
	if ai_ui_manager:
		print("  - Initializing AIUIManager")
		ai_ui_manager.initialize(main_node)
		print("  - AIUIManager initialized")

# Helper to get weapon buttons container
func get_weapon_buttons_container():
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node:
		return main_node.get_node_or_null("UI/BottomBar/WeaponButtonsContainer")
	return null

# Handle title screen animation completed
func _on_title_screen_animation_completed():
	var game_manager = get_service("GameManager")
	if game_manager:
		game_manager.start_game()

# Event handlers - all now consistently use the service locator pattern
func on_ui_update_required(event_data):
	update_ui(event_data.state, event_data.player_index)
	
func on_phase_changed(event_data):
	update_game_phase(event_data.phase_text)
	
func on_player_changed(event_data):
	update_player_ui(event_data.player_index)
	
func on_ai_thinking_started(_event_data = null):
	show_ai_thinking()

func on_ai_thinking_completed(_event_data = null):
	hide_ai_thinking()

func on_game_over(event_data):
	show_game_over(event_data.winning_player)
	
func on_state_changed(event_data):
	print("BaseUIManager: Handling STATE_CHANGED event: " + str(event_data))
	update_ui(event_data.new_state, event_data.player_index)
	
	# Explicitly trigger placement state UI update for weapon placement
	if event_data.new_state == 3: # WEAPON_PLACEMENT
		var placement_state = get_service("PlacementState")
		if placement_state and placement_state.has_method("create_weapon_buttons_for_current_state"):
			print("BaseUIManager: Explicitly triggering weapon button creation")
			placement_state.create_weapon_buttons_for_current_state()
			
			# Make sure container is visible
			var weapon_buttons_container = get_weapon_buttons_container()
			if weapon_buttons_container:
				weapon_buttons_container.visible = true
				if weapon_buttons_container.get_parent():
					weapon_buttons_container.get_parent().visible = true

# Getter for phase_ui_manager to maintain API compatibility
func get_phase_ui_manager():
	return phase_ui_manager

# Update UI using service locator - recursive guard included
func update_ui(current_state, current_player_index):
	# Check for recursion
	if _active_method_calls.has("update_ui") and _active_method_calls["update_ui"]:
		return
	
	_active_method_calls["update_ui"] = true
	
	print("BaseUIManager: Updating UI for state " + str(current_state) + " for player " + str(current_player_index + 1))
	
	# Get services using locator pattern
	var phase_ui = get_service("PhaseUIManager")
	var player_ui = get_service("PlayerUIManager")
	var placement_ui = get_service("PlacementUIManager")
	var targeting_ui = get_service("TargetingUIManager")
	var ai_ui = get_service("AIUIManager")
	var game_state_machine = get_service("GameStateMachine")
	var placement_state = get_service("PlacementState")
	
	# Update phase UI
	if phase_ui and phase_ui.has_method("update_phase_ui"):
		phase_ui.update_phase_ui(current_state, current_player_index)
	
	# Update player UI
	if player_ui and player_ui.has_method("update_player_ui"):
		player_ui.update_player_ui(current_player_index)
	
	# Update state-specific UI based on current state
	if game_state_machine:
		match current_state:
			game_state_machine.GameState.BASE_PLACEMENT:
				if placement_ui and placement_ui.has_method("update_base_placement_ui"):
					placement_ui.update_base_placement_ui(current_state, current_player_index)
				_ensure_ui_element_visibility("weapon_buttons_container", true)
				_ensure_ui_element_visibility("end_placement_button", true)
				
				# Update placement state
				if placement_state and placement_state.has_method("create_weapon_buttons_for_current_state"):
					var weapon_buttons_container = get_weapon_buttons_container()
					if weapon_buttons_container:
						placement_state.weapon_buttons_container = weapon_buttons_container
						placement_state.create_weapon_buttons_for_current_state()
				
			game_state_machine.GameState.WEAPON_PLACEMENT:
				if placement_ui and placement_ui.has_method("update_weapon_placement_ui"):
					placement_ui.update_weapon_placement_ui(current_state, current_player_index)
				_ensure_ui_element_visibility("weapon_buttons_container", true)
				_ensure_ui_element_visibility("end_placement_button", true)
				
				# Update placement state
				if placement_state and placement_state.has_method("create_weapon_buttons_for_current_state"):
					var weapon_buttons_container = get_weapon_buttons_container()
					if weapon_buttons_container:
						placement_state.weapon_buttons_container = weapon_buttons_container
						placement_state.create_weapon_buttons_for_current_state()
				
			game_state_machine.GameState.TARGETING:
				if targeting_ui and targeting_ui.has_method("update_targeting_ui"):
					targeting_ui.update_targeting_ui(current_state, current_player_index)
				_ensure_ui_element_visibility("weapon_buttons_container", false)
				_ensure_ui_element_visibility("targeting_buttons_container", true)
				_ensure_ui_element_visibility("end_targeting_button", true)
	
	# For AI turns, show thinking indicator
	var player_manager = get_service("PlayerManager")
	if player_manager and player_manager.is_current_player_ai():
		if ai_ui and ai_ui.has_method("show_ai_thinking"):
			ai_ui.show_ai_thinking()
	else:
		if ai_ui and ai_ui.has_method("hide_ai_thinking"):
			ai_ui.hide_ai_thinking()
	
	_active_method_calls["update_ui"] = false

# Helper to ensure UI element visibility
func _ensure_ui_element_visibility(element_name, visible):
	var element = null
	var main_node = get_tree().root.get_node_or_null("Main")
	
	if main_node:
		match element_name:
			"weapon_buttons_container":
				element = main_node.get_node_or_null("UI/BottomBar/WeaponButtonsContainer")
			"targeting_buttons_container":
				element = main_node.get_node_or_null("UI/BottomBar/TargetingButtonsContainer")
			"end_placement_button":
				element = main_node.get_node_or_null("UI/BottomBar/EndPlacementButton")
			"end_targeting_button":
				element = main_node.get_node_or_null("UI/BottomBar/EndTargetingButton")
	
	if element:
		if element.visible != visible:
			print("BaseUIManager: Setting " + element_name + " visibility to " + str(visible))
			element.visible = visible
			
			# For containers, also ensure parent is visible
			if element_name.ends_with("_container") and element.get_parent():
				element.get_parent().visible = visible
		
		# Track state
		_ui_states[element_name + "_visible"] = visible

# Forward methods to appropriate services - with recursion guards

func handle_player_turn_update(player_index):
	if _active_method_calls.has("handle_player_turn_update") and _active_method_calls["handle_player_turn_update"]:
		return
		
	_active_method_calls["handle_player_turn_update"] = true
	
	var phase_ui = get_service("PhaseUIManager")
	var player_manager = get_service("PlayerManager")
	
	if phase_ui and player_manager and phase_ui.has_method("update_current_turn"):
		phase_ui.update_current_turn(player_manager.get_player_name(player_index))
	
	_active_method_calls["handle_player_turn_update"] = false

func show_ai_thinking():
	if _active_method_calls.has("show_ai_thinking") and _active_method_calls["show_ai_thinking"]:
		return
		
	_active_method_calls["show_ai_thinking"] = true
	
	var ai_ui = get_service("AIUIManager")
	if ai_ui and ai_ui.has_method("show_ai_thinking"):
		ai_ui.show_ai_thinking()
	
	# Emit event after delegating to AI UI manager
	if !_active_method_calls.get("on_ai_thinking_started", false):
		emit_event(GameEvents.AI_THINKING_STARTED)
	
	_active_method_calls["show_ai_thinking"] = false

func hide_ai_thinking():
	if _active_method_calls.has("hide_ai_thinking") and _active_method_calls["hide_ai_thinking"]:
		return
		
	_active_method_calls["hide_ai_thinking"] = true
	
	var ai_ui = get_service("AIUIManager")
	if ai_ui and ai_ui.has_method("hide_ai_thinking"):
		ai_ui.hide_ai_thinking()
	
	# Emit event after delegating to AI UI manager
	if !_active_method_calls.get("on_ai_thinking_completed", false):
		emit_event(GameEvents.AI_THINKING_COMPLETED)
	
	_active_method_calls["hide_ai_thinking"] = false

func update_game_phase(phase_text):
	if _active_method_calls.has("update_game_phase") and _active_method_calls["update_game_phase"]:
		return
		
	_active_method_calls["update_game_phase"] = true
	
	var phase_ui = get_service("PhaseUIManager")
	if phase_ui and phase_ui.has_method("update_game_phase"):
		phase_ui.update_game_phase(phase_text)
	
	_active_method_calls["update_game_phase"] = false

func update_current_turn(player_name):
	if _active_method_calls.has("update_current_turn") and _active_method_calls["update_current_turn"]:
		return
		
	_active_method_calls["update_current_turn"] = true
	
	var phase_ui = get_service("PhaseUIManager")
	if phase_ui and phase_ui.has_method("update_current_turn"):
		phase_ui.update_current_turn(player_name)
	
	_active_method_calls["update_current_turn"] = false

func update_player_ui(player_index):
	if _active_method_calls.has("update_player_ui") and _active_method_calls["update_player_ui"]:
		return
		
	_active_method_calls["update_player_ui"] = true
	
	var player_ui = get_service("PlayerUIManager")
	if player_ui and player_ui.has_method("update_player_ui"):
		player_ui.update_player_ui(player_index)
	
	_active_method_calls["update_player_ui"] = false

func show_game_over(winning_player):
	if _active_method_calls.has("show_game_over") and _active_method_calls["show_game_over"]:
		return
		
	_active_method_calls["show_game_over"] = true
	
	var phase_ui = get_service("PhaseUIManager")
	if phase_ui and phase_ui.has_method("show_game_over"):
		phase_ui.show_game_over(winning_player)
	
	_active_method_calls["show_game_over"] = false

# Connect signals from AI opponent
func connect_ai_signals(ai_opponent):
	var ai_ui = get_service("AIUIManager")
	if ai_opponent and ai_ui and ai_ui.has_method("connect_ai_signals"):
		ai_ui.connect_ai_signals(ai_opponent)

# Helper to get a service - use proper service locator pattern
func get_service(service_name):
	if Engine.has_singleton("GameManager"):
		return Engine.get_singleton("GameManager").get_service(service_name)
	return null

# Helper to emit event
func emit_event(event_name, event_data = null):
	var event_bus = get_service("EventBus")
	if event_bus:
		event_bus.emit_event(event_name, event_data)