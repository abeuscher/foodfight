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

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Get reference to main scene
	main_scene = get_parent()
	
	# Get reference to game state machine
	game_state_machine = main_scene.get_node("GameStateMachine")
	
	# Get UI references from scene tree
	var root = get_tree().get_root()
	var main_scene = root.get_node("Main")
	
	if main_scene:
		# Get top and bottom bar elements
		top_bar_panel = main_scene.get_node("UI/TopBar")
		bottom_bar_panel = main_scene.get_node("UI/BottomBar")
		
		# Get title screen
		if main_scene.has_node("UI/TitleScreen"):
			title_screen = main_scene.get_node("UI/TitleScreen")
			title_screen.animation_completed.connect(_on_title_screen_animation_completed)
	
	# Get references to other nodes
	if main_scene.has_node("WeaponPlacement"):
		weapon_placement = main_scene.get_node("WeaponPlacement")
	
	if main_scene.has_node("PlayerManager"):
		player_manager = main_scene.get_node("PlayerManager")
	
	if main_scene.has_node("WeaponTypes"):
		weapon_types = main_scene.get_node("WeaponTypes")
		
	# Create child UI managers
	_initialize_child_managers()
	
	is_initialized = true
	print("Base UI Manager initialized")

# Initialize child UI manager components
func _initialize_child_managers():
	# Create player UI manager
	player_ui_manager = Node.new()
	player_ui_manager.name = "PlayerUIManager"
	player_ui_manager.set_script(load("res://scripts/ui/player_ui_manager.gd"))
	add_child(player_ui_manager)
	
	# Create phase UI manager
	phase_ui_manager = Node.new()
	phase_ui_manager.name = "PhaseUIManager"
	phase_ui_manager.set_script(load("res://scripts/ui/phase_ui_manager.gd"))
	add_child(phase_ui_manager)
	
	# Create placement UI manager
	placement_ui_manager = Node.new()
	placement_ui_manager.name = "PlacementUIManager"
	placement_ui_manager.set_script(load("res://scripts/ui/placement_ui_manager.gd"))
	add_child(placement_ui_manager)
	
	# Create targeting UI manager
	targeting_ui_manager = Node.new()
	targeting_ui_manager.name = "TargetingUIManager"
	targeting_ui_manager.set_script(load("res://scripts/ui/targeting_ui_manager.gd"))
	add_child(targeting_ui_manager)
	
	# Create AI UI manager
	ai_ui_manager = Node.new()
	ai_ui_manager.name = "AIUIManager"
	ai_ui_manager.set_script(load("res://scripts/ai/ai_ui_manager.gd"))
	add_child(ai_ui_manager)
	
	# Initialize child managers with their dependencies
	_initialize_child_manager_dependencies()

# Initialize dependencies for child managers
func _initialize_child_manager_dependencies():
	if main_scene:
		# Setup player UI manager
		player_ui_manager.initialize(
			main_scene.get_node_or_null("UI/TopBar/HBoxContainer/Player1Container/NameLabel"),
			main_scene.get_node_or_null("UI/TopBar/HBoxContainer/Player2Container/NameLabel"),
			main_scene.get_node_or_null("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel"),
			main_scene.get_node_or_null("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel"),
			player_manager
		)
		
		# Setup phase UI manager
		phase_ui_manager.initialize(
			main_scene.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel"),
			main_scene.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel"),
			title_screen,
			player_manager
		)
		
		# Setup placement UI manager
		placement_ui_manager.initialize(
			main_scene.get_node_or_null("UI/BottomBar/WeaponButtonsContainer"),
			main_scene.get_node_or_null("UI/BottomBar/EndPlacementButton"),
			weapon_placement,
			weapon_types,
			player_manager,
			main_scene
		)
		
		# Setup targeting UI manager
		targeting_ui_manager.initialize(
			main_scene.get_node_or_null("UI/BottomBar/TargetingButtonsContainer"),
			main_scene.get_node_or_null("UI/BottomBar/EndTargetingButton"),
			weapon_manager,
			targeting_manager,
			targeting_state,
			player_manager,
			main_scene
		)
		
		# Setup AI UI manager
		ai_ui_manager.initialize(main_scene)

# Ensure all game components are available
func _ensure_game_components():
	if Engine.has_singleton("GameManager"):
		var GameManager = Engine.get_singleton("GameManager")
		if !weapon_manager:
			weapon_manager = GameManager.weapon_manager
		if !targeting_state:
			targeting_state = GameManager.targeting_state
		if !targeting_manager:
			targeting_manager = GameManager.targeting_manager
		if !weapon_types:
			weapon_types = GameManager.weapon_types
		if !turn_manager:
			turn_manager = GameManager.turn_manager
		if !ai_controller:
			ai_controller = GameManager.ai_controller
		if !game_state_machine:
			game_state_machine = GameManager.game_state_machine
		
		# Update dependencies for child managers
		if player_ui_manager:
			player_ui_manager.player_manager = player_manager
		
		if phase_ui_manager:
			phase_ui_manager.player_manager = player_manager
		
		if placement_ui_manager:
			placement_ui_manager.weapon_placement = weapon_placement
			placement_ui_manager.weapon_types = weapon_types
			placement_ui_manager.player_manager = player_manager
		
		if targeting_ui_manager:
			targeting_ui_manager.weapon_manager = weapon_manager
			targeting_ui_manager.targeting_manager = targeting_manager
			targeting_ui_manager.targeting_state = targeting_state
			targeting_ui_manager.player_manager = player_manager

# Handle title screen animation completed
func _on_title_screen_animation_completed():
	emit_signal("title_screen_completed")

# Show title screen for upcoming phase
func show_phase_title(phase_name):
	if !is_initialized:
		print("BaseUIManager: Title screen not available")
		emit_signal("title_screen_completed")
		return
	
	phase_ui_manager.show_phase_title(phase_name)

# Update UI based on game state
func update_ui(current_state, current_player_index):
	if !is_initialized or !game_state_machine:
		return
		
	print("BaseUIManager: Updating UI for state " + str(game_state_machine.GameState.keys()[current_state]) + 
		  " for player " + str(current_player_index + 1))
	
	# Ensure we have game components
	_ensure_game_components()
	
	# Update player UI
	player_ui_manager.update_player_ui(current_player_index)
	
	# Update phase UI
	phase_ui_manager.update_phase_ui(current_state, current_player_index)
	
	# Update state-specific UI
	match current_state:
		game_state_machine.GameState.BASE_PLACEMENT:
			placement_ui_manager.update_base_placement_ui(current_state, current_player_index)
		
		game_state_machine.GameState.WEAPON_PLACEMENT:
			placement_ui_manager.update_weapon_placement_ui(current_state, current_player_index)
		
		game_state_machine.GameState.TARGETING:
			targeting_ui_manager.update_targeting_ui(current_state, current_player_index)
	
	# For AI turns, show thinking indicator
	var is_ai_turn = (current_player_index == 1)
	if is_ai_turn:
		ai_ui_manager.show_ai_thinking()
	else:
		ai_ui_manager.hide_ai_thinking()
	
	# Update ingredients display
	player_ui_manager.update_ingredients_display()

# Forward methods to appropriate child managers
func handle_player_turn_update(player_index):
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
	phase_ui_manager.update_game_phase(phase_text)

# Update current turn label (forwarded to phase UI manager)
func update_current_turn(player_name):
	phase_ui_manager.update_current_turn(player_name)

# Show game over screen (forwarded to phase UI manager)
func show_game_over(winning_player):
	phase_ui_manager.show_game_over(winning_player)

# Connect signals from AI opponent
func connect_ai_signals(ai_opponent):
	if ai_opponent and ai_ui_manager:
		ai_ui_manager.connect_ai_signals(ai_opponent)