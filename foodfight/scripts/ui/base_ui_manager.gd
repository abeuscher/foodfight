extends Node

signal title_screen_completed

# Core UI element references
var top_bar_panel
var bottom_bar_panel
var title_screen

# References to components
var weapon_placement
var player_manager
var weapon_manager
var targeting_state
var targeting_manager
var weapon_types
var main_scene
var game_state_machine
var turn_manager
var ai_controller

# Child UI managers
var player_ui_manager
var phase_ui_manager
var placement_ui_manager
var targeting_ui_manager
var ai_ui_manager

# Initialization flag
var is_initialized = false
var is_initializing = false

func _ready():
	# Mark that initialization has started
	is_initializing = true
	print("BaseUIManager: Starting initialization")
	
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Get reference to main scene
	_initialize_scene_references()
	
	# Create child UI managers
	_initialize_child_managers()
	
	# Initialize child manager dependencies
	_initialize_child_manager_dependencies()
	
	# Do a final check for any missing components
	_ensure_game_components()
	
	is_initialized = true
	is_initializing = false
	print("Base UI Manager initialized")

# Initialize references to scene nodes
func _initialize_scene_references():
	# First try to get parent as main scene
	main_scene = get_parent()
	
	# Get reference to game state machine (try from parent first, then try global)
	game_state_machine = main_scene.get_node_or_null("GameStateMachine")
	if !game_state_machine and Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		game_state_machine = GameManager.game_state_machine
	
	# Get UI references from scene tree
	var root = get_tree().get_root()
	var main_node = root.get_node_or_null("Main")
	
	if main_node:
		# Get top and bottom bar elements
		top_bar_panel = main_node.get_node_or_null("UI/TopBar")
		bottom_bar_panel = main_node.get_node_or_null("UI/BottomBar")
		
		# Get title screen
		title_screen = main_node.get_node_or_null("UI/TitleScreen")
		if title_screen and title_screen.has_signal("animation_completed"):
			if !title_screen.is_connected("animation_completed", Callable(self, "_on_title_screen_animation_completed")):
				title_screen.connect("animation_completed", Callable(self, "_on_title_screen_animation_completed"))
		else:
			print("BaseUIManager: Title screen not found or doesn't have animation_completed signal")
	
	# Get references to other nodes from both main_scene and main_node
	for node_source in [main_scene, main_node]:
		if node_source:
			if !weapon_placement and node_source.has_node("WeaponPlacement"):
				weapon_placement = node_source.get_node("WeaponPlacement")
			
			if !player_manager and node_source.has_node("PlayerManager"):
				player_manager = node_source.get_node("PlayerManager")
			
			if !weapon_types and node_source.has_node("WeaponTypes"):
				weapon_types = node_source.get_node("WeaponTypes")

# Initialize child UI manager components
func _initialize_child_managers():
	# Create player UI manager if not exists
	if !player_ui_manager:
		player_ui_manager = Node.new()
		player_ui_manager.name = "PlayerUIManager"
		player_ui_manager.set_script(load("res://scripts/ui/player_ui_manager.gd"))
		add_child(player_ui_manager)
	
	# Create phase UI manager if not exists
	if !phase_ui_manager:
		phase_ui_manager = Node.new()
		phase_ui_manager.name = "PhaseUIManager"
		phase_ui_manager.set_script(load("res://scripts/ui/phase_ui_manager.gd"))
		add_child(phase_ui_manager)
	
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

# Initialize dependencies for child managers
func _initialize_child_manager_dependencies():
	# Find the main scene - try multiple approaches
	var ui_container_node = null
	var root = get_tree().get_root()
	var main_node = root.get_node_or_null("Main")
	
	if main_node:
		ui_container_node = main_node
	elif main_scene:
		ui_container_node = main_scene
	
	if ui_container_node:
		# Setup player UI manager
		var p1_name_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/Player1Container/NameLabel")
		var p2_name_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/Player2Container/NameLabel")
		var p1_score_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel")
		var p2_score_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel")
		
		if player_ui_manager:
			player_ui_manager.initialize(p1_name_label, p2_name_label, p1_score_label, p2_score_label, player_manager)
		
		# Setup phase UI manager
		var turn_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel")
		var phase_label = ui_container_node.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
		
		if phase_ui_manager:
			phase_ui_manager.initialize(turn_label, phase_label, title_screen, player_manager)
		
		# Setup placement UI manager
		var weapon_buttons_container = ui_container_node.get_node_or_null("UI/BottomBar/WeaponButtonsContainer")
		var end_placement_button = ui_container_node.get_node_or_null("UI/BottomBar/EndPlacementButton")
		
		if placement_ui_manager:
			placement_ui_manager.initialize(weapon_buttons_container, end_placement_button, 
				weapon_placement, weapon_types, player_manager, ui_container_node)
		
		# Setup targeting UI manager
		var targeting_buttons_container = ui_container_node.get_node_or_null("UI/BottomBar/TargetingButtonsContainer")
		var end_targeting_button = ui_container_node.get_node_or_null("UI/BottomBar/EndTargetingButton")
		
		if targeting_ui_manager:
			targeting_ui_manager.initialize(targeting_buttons_container, end_targeting_button,
				weapon_manager, targeting_manager, targeting_state, player_manager, ui_container_node)
		
		# Setup AI UI manager
		if ai_ui_manager:
			ai_ui_manager.initialize(ui_container_node)
	else:
		print("BaseUIManager: Could not find UI container node for initialization")

# Ensure all game components are available
func _ensure_game_components():
	# Try to get components from GameManager if available
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		
		if !weapon_manager and GameManager.has_method("get_weapon_manager"):
			weapon_manager = GameManager.get_weapon_manager()
		
		if !targeting_state and GameManager.has_method("get_targeting_state"):
			targeting_state = GameManager.get_targeting_state()
		
		if !targeting_manager and GameManager.has_method("get_targeting_manager"):
			targeting_manager = GameManager.get_targeting_manager()
		
		if !weapon_types and GameManager.has_method("get_weapon_types"):
			weapon_types = GameManager.get_weapon_types()
		
		if !turn_manager and GameManager.has_method("get_turn_manager"):
			turn_manager = GameManager.get_turn_manager()
		
		if !ai_controller and GameManager.has_method("get_ai_controller"):
			ai_controller = GameManager.get_ai_controller()
			
		if !game_state_machine and GameManager.has_method("get_game_state_machine"):
			game_state_machine = GameManager.get_game_state_machine()
		
		# Get references directly from GameManager fields if methods not available
		if !weapon_manager and "weapon_manager" in GameManager:
			weapon_manager = GameManager.weapon_manager
			
		if !targeting_state and "targeting_state" in GameManager:
			targeting_state = GameManager.targeting_state
			
		if !targeting_manager and "targeting_manager" in GameManager:
			targeting_manager = GameManager.targeting_manager
			
		if !weapon_types and "weapon_types" in GameManager:
			weapon_types = GameManager.weapon_types
			
		if !turn_manager and "turn_manager" in GameManager:
			turn_manager = GameManager.turn_manager
			
		if !ai_controller and "ai_controller" in GameManager:
			ai_controller = GameManager.ai_controller
			
		if !game_state_machine and "game_state_machine" in GameManager:
			game_state_machine = GameManager.game_state_machine
	
	# Update dependencies for child managers
	_update_child_manager_dependencies()

# Update dependencies in child managers
func _update_child_manager_dependencies():
	if player_ui_manager and player_manager:
		player_ui_manager.player_manager = player_manager
	
	if phase_ui_manager and player_manager:
		phase_ui_manager.player_manager = player_manager
	
	if placement_ui_manager:
		if weapon_placement:
			placement_ui_manager.weapon_placement = weapon_placement
		if weapon_types:
			placement_ui_manager.weapon_types = weapon_types
		if player_manager:
			placement_ui_manager.player_manager = player_manager
	
	if targeting_ui_manager:
		if weapon_manager:
			targeting_ui_manager.weapon_manager = weapon_manager
		if targeting_manager:
			targeting_ui_manager.targeting_manager = targeting_manager
		if targeting_state:
			targeting_ui_manager.targeting_state = targeting_state
		if player_manager:
			targeting_ui_manager.player_manager = player_manager

# Handle title screen animation completed
func _on_title_screen_animation_completed():
	emit_signal("title_screen_completed")

# Show title screen for upcoming phase
func show_phase_title(phase_name):
	if !is_initialized and !is_initializing:
		print("BaseUIManager: Not initialized, deferring phase title")
		call_deferred("show_phase_title", phase_name)
		return
	
	if !phase_ui_manager:
		print("BaseUIManager: Phase UI manager not available")
		call_deferred("emit_signal", "title_screen_completed")
		return
		
	phase_ui_manager.show_phase_title(phase_name)

# Update UI based on game state
func update_ui(current_state, current_player_index):
	if !is_initialized and !is_initializing:
		print("BaseUIManager: Not initialized, deferring UI update")
		call_deferred("update_ui", current_state, current_player_index)
		return
	
	print("BaseUIManager: Updating UI for state " + str(current_state) + " for player " + str(current_player_index + 1))
	
	# Ensure we have game components
	_ensure_game_components()
	
	# Update player UI
	if player_ui_manager:
		player_ui_manager.update_player_ui(current_player_index)
	
	# Update phase UI
	if phase_ui_manager and game_state_machine:
		phase_ui_manager.update_phase_ui(current_state, current_player_index)
	
	# Update state-specific UI based on current state
	if game_state_machine:
		match current_state:
			game_state_machine.GameState.BASE_PLACEMENT:
				if placement_ui_manager:
					placement_ui_manager.update_base_placement_ui(current_state, current_player_index)
			
			game_state_machine.GameState.WEAPON_PLACEMENT:
				if placement_ui_manager:
					placement_ui_manager.update_weapon_placement_ui(current_state, current_player_index)
			
			game_state_machine.GameState.TARGETING:
				if targeting_ui_manager:
					targeting_ui_manager.update_targeting_ui(current_state, current_player_index)
	
	# For AI turns, show thinking indicator
	var is_ai_turn = (current_player_index == 1)
	if is_ai_turn and ai_ui_manager:
		ai_ui_manager.show_ai_thinking()
	elif ai_ui_manager:
		ai_ui_manager.hide_ai_thinking()
	
	# Update ingredients display
	if player_ui_manager:
		player_ui_manager.update_ingredients_display()

# Forward methods to appropriate child managers
func handle_player_turn_update(player_index):
	if !player_manager:
		print("BaseUIManager: Missing player_manager for turn update")
		return
		
	if phase_ui_manager:
		phase_ui_manager.update_current_turn(player_manager.get_player_name(player_index))

# Show AI thinking indicator (forwarded to AI UI manager)
func show_ai_thinking():
	if ai_ui_manager:
		ai_ui_manager.show_ai_thinking()

# Hide AI thinking indicator (forwarded to AI UI manager)
func hide_ai_thinking():
	if ai_ui_manager:
		ai_ui_manager.hide_ai_thinking()

# Update game phase (forwarded to phase UI manager)
func update_game_phase(phase_text):
	if phase_ui_manager:
		phase_ui_manager.update_game_phase(phase_text)
	else:
		print("BaseUIManager: Phase UI manager not available for phase update")

# Update current turn label (forwarded to phase UI manager)
func update_current_turn(player_name):
	if phase_ui_manager:
		phase_ui_manager.update_current_turn(player_name)
	else:
		print("BaseUIManager: Phase UI manager not available for turn update")

# Show game over screen (forwarded to phase UI manager)
func show_game_over(winning_player):
	if phase_ui_manager:
		phase_ui_manager.show_game_over(winning_player)
	else:
		print("BaseUIManager: Phase UI manager not available for game over")

# Connect signals from AI opponent
func connect_ai_signals(ai_opponent):
	if ai_opponent and ai_ui_manager:
		ai_ui_manager.connect_ai_signals(ai_opponent)
	else:
		print("BaseUIManager: Cannot connect AI signals, missing references")