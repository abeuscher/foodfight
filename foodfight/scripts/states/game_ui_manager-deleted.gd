extends Node

# References to UI elements
var player1_name_label
var player2_name_label
var player1_ingredients_label  # Renamed from score_label
var player2_ingredients_label  # Renamed from score_label
var turn_label
var phase_label
# resource_label not needed anymore - consolidated with ingredients
var weapon_buttons_container
var targeting_buttons_container
var end_placement_button
var end_targeting_button
var title_screen

# Reference to components
var weapon_placement
var player_manager
var weapon_manager
var targeting_state
var targeting_manager
var weapon_types
var main_scene
var game_state_machine  # Added reference to game state machine

# New component references
var turn_manager
var ai_controller

# Initialization flag
var is_initialized = false

# Signal for title screen animation completion
signal title_screen_completed

# Ingredients animation properties
var player1_ingredients_tween
var player2_ingredients_tween
var last_player1_ingredients = 0
var last_player2_ingredients = 0

# AI thinking indicator
var ai_thinking_label = null
var is_ai_thinking = false

# UI references
var top_bar_panel
var bottom_bar_panel
var player1_container
var player2_container
var phase_container
var ai_thinking_indicator

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Get reference to main scene
	main_scene = get_parent()
	
	# Get reference to game state machine
	game_state_machine = main_scene.get_node("GameStateMachine")
	
	# Get references to UI elements
	if main_scene.has_node("UI/TopBar/HBoxContainer/Player1Container/NameLabel"):
		player1_name_label = main_scene.get_node("UI/TopBar/HBoxContainer/Player1Container/NameLabel")
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/Player2Container/NameLabel"):
		player2_name_label = main_scene.get_node("UI/TopBar/HBoxContainer/Player2Container/NameLabel")
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel"):
		player1_ingredients_label = main_scene.get_node("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel")
		# Update the text to reflect ingredients
		if player1_ingredients_label:
			player1_ingredients_label.text = "Ingredients: 0"
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel"):
		player2_ingredients_label = main_scene.get_node("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel")
		# Update the text to reflect ingredients
		if player2_ingredients_label:
			player2_ingredients_label.text = "Ingredients: 0"
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel"):
		turn_label = main_scene.get_node("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel")
	
	if main_scene.has_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel"):
		phase_label = main_scene.get_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
	
	if main_scene.has_node("UI/BottomBar/WeaponButtonsContainer"):
		weapon_buttons_container = main_scene.get_node("UI/BottomBar/WeaponButtonsContainer")
	
	if main_scene.has_node("UI/BottomBar/EndPlacementButton"):
		end_placement_button = main_scene.get_node("UI/BottomBar/EndPlacementButton")
	
	if main_scene.has_node("UI/BottomBar/TargetingButtonsContainer"):
		targeting_buttons_container = main_scene.get_node("UI/BottomBar/TargetingButtonsContainer")
	
	if main_scene.has_node("UI/BottomBar/EndTargetingButton"):
		end_targeting_button = main_scene.get_node("UI/BottomBar/EndTargetingButton")
	
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
	
	# Initialize last ingredients
	if player_manager:
		last_player1_ingredients = player_manager.player1_ingredients
		last_player2_ingredients = player_manager.player2_ingredients
	
	is_initialized = true
	print("UI Manager initialized")
	
	# Create AI thinking indicator
	create_ai_thinking_indicator()

	# Get UI references from scene tree
	var root = get_tree().get_root()
	var main_scene = root.get_node("Main")
	
	if main_scene:
		# Get top bar elements
		top_bar_panel = main_scene.get_node("UI/TopBar")
		if top_bar_panel:
			var top_box = top_bar_panel.get_node("HBoxContainer")
			if top_box:
				player1_container = top_box.get_node("Player1Container")
				player2_container = top_box.get_node("Player2Container")
				phase_container = top_box.get_node("PhaseContainer")
				
				if phase_container:
					turn_label = phase_container.get_node("TurnLabel")
					phase_label = phase_container.get_node("PhaseLabel")
		
		# Get bottom bar elements
		bottom_bar_panel = main_scene.get_node("UI/BottomBar")
		if bottom_bar_panel:
			weapon_buttons_container = bottom_bar_panel.get_node("WeaponButtonsContainer")
			targeting_buttons_container = bottom_bar_panel.get_node("TargetingButtonsContainer")
			end_placement_button = bottom_bar_panel.get_node("EndPlacementButton")
			end_targeting_button = bottom_bar_panel.get_node("EndTargetingButton")
		
		# Check for AI thinking indicator, create if not exists
		ai_thinking_indicator = main_scene.get_node_or_null("UI/AIThinkingIndicator")
		if ai_thinking_indicator == null:
			# Create AI thinking indicator
			ai_thinking_indicator = Label.new()
			ai_thinking_indicator.name = "AIThinkingIndicator"
			ai_thinking_indicator.text = "AI is thinking..."
			ai_thinking_indicator.visible = false
			ai_thinking_indicator.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
			ai_thinking_indicator.position = Vector2(600, 400)
			main_scene.get_node("UI").add_child(ai_thinking_indicator)
	
	# Ensure player 2 is labeled as AI
	update_player2_as_ai()

# Get all non-base weapons from weapon_types
func _get_non_base_weapons():
	var non_base_weapons = []
	if weapon_types:
		for weapon in weapon_types.get_all_weapons():
			if "type" in weapon and weapon.type != "base":
				non_base_weapons.append(weapon)
	return non_base_weapons

# Handle title screen animation completed
func _on_title_screen_animation_completed():
	emit_signal("title_screen_completed")

# Show title screen for upcoming phase
func show_phase_title(phase_name):
	if !is_initialized:
		print("GameUIManager: Title screen not available")
		emit_signal("title_screen_completed")
		return
	
	print("GameUIManager: Showing title for phase: " + phase_name)
	if title_screen:
		title_screen.visible = true
		title_screen.show_title(phase_name)
	else:
		print("ERROR: No title screen found!")
		emit_signal("title_screen_completed")

# Ensure we have all needed GameManager components
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

# Handle player turn started in targeting phase
func handle_player_turn_started(player_id):
	print("GameUIManager: Player turn started for Player ", player_id + 1)
	
	# Make sure we have all needed components
	_ensure_game_components()
	
	# Check if we have all necessary components
	if !is_initialized or !targeting_buttons_container:
		print("GameUIManager: Missing UI components for player turn")
		return
		
	if !weapon_manager:
		print("GameUIManager: Missing weapon_manager for player turn")
		return
	
	print("GameUIManager: Creating buttons for Player ", player_id + 1)
	
	# Clear existing buttons
	for child in targeting_buttons_container.get_children():
		child.queue_free()
	
	# Get player's offensive weapons only (explicitly exclude bases)
	var weapons = weapon_manager.get_player_weapons(player_id, "offensive")
	print("GameUIManager: Found ", weapons.size(), " offensive weapons for Player ", player_id + 1)
	
	# Double-check that no bases are included
	var filtered_weapons = []
	for weapon in weapons:
		var is_base = false
		
		# Check if this is a base weapon
		if typeof(weapon.data) == TYPE_DICTIONARY:
			if "type" in weapon.data and weapon.data.type == "base":
				is_base = true
			elif "id" in weapon.data and str(weapon.data.id).to_lower().contains("base"):
				is_base = true
			elif "attack_range" in weapon.data and weapon.data.attack_range <= 0:
				is_base = true
		
		if !is_base:
			filtered_weapons.append(weapon)
	
	# Create a button for each weapon
	for weapon in filtered_weapons:
		var button = Button.new()
		button.text = weapon.data.name
		button.tooltip_text = "Range: " + str(weapon.data.attack_range) + "\n" + \
						   "Damage: " + str(weapon.data.damage) + "\n" + \
						   "Splash: " + str(weapon.data.splash_radius)
		
		# Connect button press to callback in main
		button.pressed.connect(func(): main_scene._on_targeting_button_pressed(weapon, player_id))
		
		# Add to container
		targeting_buttons_container.add_child(button)
	
	# Make container visible
	targeting_buttons_container.visible = true
	
	# Update turn label to show current player
	if turn_label:
		turn_label.text = "Player " + str(player_id + 1) + "'s Turn"
	
	# Update phase label to show remaining attacks
	if phase_label:
		phase_label.text = "Targeting Phase (3 targets left)"
	
	# Make sure end targeting button is visible
	if end_targeting_button:
		end_targeting_button.visible = true
		end_targeting_button.text = "End Player " + str(player_id + 1) + "'s Targeting"
	
	# Show AI thinking indicator if it's the AI's turn
	if player_id == 1:  # Player 2 is AI
		show_ai_thinking()
	else:
		hide_ai_thinking()

# Create base placement UI
func create_base_placement_ui(player_id):
	if !is_initialized or !weapon_buttons_container or !weapon_types:
		print("GameUIManager: Missing components for base placement UI")
		return
	
	print("GameUIManager: Creating base placement UI for Player ", player_id + 1)
	
	# Clear existing buttons
	for child in weapon_buttons_container.get_children():
		if child.name != "IngredientsLabel":  # Keep ingredients label
			child.queue_free()
	
	# Get the base weapon type
	var base_weapon = weapon_types.get_base_weapon()
	if !base_weapon:
		print("GameUIManager: No base weapon type found")
		return
	
	# Create a button for placing the base
	var button = Button.new()
	button.text = base_weapon.name
	button.tooltip_text = "Size: " + str(base_weapon.size.x) + "x" + str(base_weapon.size.y) + "\n" + \
					   "Your main base. Protect it at all costs!"
	
	# Style the button to make it prominent
	button.custom_minimum_size = Vector2(180, 40)
	button.modulate = Color(1, 0.8, 0.2)  # Gold color
	
	# Connect button press to select base for placement
	button.pressed.connect(func(): _on_base_button_pressed(base_weapon.id, player_id))
	
	# Add to container
	weapon_buttons_container.add_child(button)
	
	# Make container visible
	weapon_buttons_container.visible = true
	
	# Set up end placement button
	if end_placement_button and player_manager:
		end_placement_button.visible = true
		end_placement_button.text = "End Base Placement"
		end_placement_button.z_index = 1

# Create weapon placement UI
func create_weapon_placement_ui(player_id):
	if !is_initialized or !weapon_buttons_container or !weapon_types:
		print("GameUIManager: Missing components for weapon placement UI")
		return
	
	print("GameUIManager: Creating weapon placement UI for Player ", player_id + 1)
	
	# Clear existing buttons
	for child in weapon_buttons_container.get_children():
		if child.name != "IngredientsLabel":  # Keep ingredients label
			child.queue_free()
	
	# Get non-base weapons
	var weapons = _get_non_base_weapons()
	print("Found " + str(weapons.size()) + " weapons for placement")
	
	# Create a button for each weapon
	for weapon in weapons:
		var button = Button.new()
		button.text = weapon.name + " (" + str(weapon.cost) + ")"
		button.tooltip_text = weapon.description
		button.custom_minimum_size = Vector2(120, 40)
		button.pressed.connect(Callable(self, "_on_weapon_button_pressed").bind(weapon.id))
		weapon_buttons_container.add_child(button)
	
	# Make container visible
	weapon_buttons_container.visible = true
	
	# Set up end placement button
	if end_placement_button and player_manager:
		end_placement_button.visible = true
		end_placement_button.text = "End Weapon Placement"

# Handle base button pressed
func _on_base_button_pressed(base_id, player_id):
	if !is_initialized or !weapon_placement:
		return
	
	print("GameUIManager: Base button pressed for Player ", player_id + 1)
	weapon_placement.select_weapon_for_placement(base_id)

# Handle weapon button pressed
func _on_weapon_button_pressed(weapon_id):
	if !is_initialized or !weapon_placement:
		return
	
	print("GameUIManager: Weapon button pressed: ", weapon_id)
	weapon_placement.select_weapon_for_placement(weapon_id)

# Update ingredients labels with animation
func update_ingredients_display():
	if !is_initialized or !player1_ingredients_label or !player2_ingredients_label or !player_manager:
		return
		
	# Only animate if the ingredients have changed
	if player_manager.player1_ingredients != last_player1_ingredients:
		animate_ingredients_change(player1_ingredients_label, last_player1_ingredients, player_manager.player1_ingredients)
		last_player1_ingredients = player_manager.player1_ingredients
	
	if player_manager.player2_ingredients != last_player2_ingredients:
		animate_ingredients_change(player2_ingredients_label, last_player2_ingredients, player_manager.player2_ingredients)

# Animate ingredients change with a tween
func animate_ingredients_change(label, from_value, to_value):
	# Cancel any existing tween
	if label.has_meta("active_tween") and is_instance_valid(label.get_meta("active_tween")):
		label.get_meta("active_tween").kill()
	
	# Create new tween
	var tween = create_tween()
	label.set_meta("active_tween", tween)
	
	# Store current ingredients for interpolation
	var current_value = from_value
	
	# Highlight label
	var original_color = label.get_theme_color("font_color")
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))  # Gold color for highlight
	
	# Animate the ingredients value over 0.5 seconds
	tween.tween_method(func(value):
		current_value = value
		label.text = "Ingredients: " + str(int(value))
	, float(from_value), float(to_value), 0.5)
	
	# Return to normal color after animation
	tween.tween_callback(func():
		label.remove_theme_color_override("font_color")
	)

# Update UI based on game state
func update_ui(current_state, current_player_index):
	if !is_initialized or !game_state_machine:
		return
		
	print("GameUIManager: Updating UI for state " + str(game_state_machine.GameState.keys()[current_state]) + 
		  " for player " + str(current_player_index + 1))
	
	# Ensure we have game components
	_ensure_game_components()
	
	# First, clear existing weapon buttons to avoid wrong state
	if weapon_buttons_container:
		for child in weapon_buttons_container.get_children():
			if child.name != "IngredientsLabel":  # Keep ingredients label
				child.queue_free()
	
	# Handle specific game states
	match current_state:
		game_state_machine.GameState.BASE_PLACEMENT:
			print("UI Update: BASE_PLACEMENT state for player", current_player_index + 1)
			if current_player_index == 0:  # Only human player
				create_base_placement_ui(current_player_index)
			else:
				# Hide buttons for AI
				if weapon_buttons_container:
					weapon_buttons_container.visible = false
				if end_placement_button:
					end_placement_button.visible = false
		
		game_state_machine.GameState.WEAPON_PLACEMENT:
			print("UI Update: WEAPON_PLACEMENT state for player", current_player_index + 1)
			if current_player_index == 0:  # Only human player
				create_weapon_placement_ui(current_player_index)
			else:
				# Hide buttons for AI
				if weapon_buttons_container:
					weapon_buttons_container.visible = false
				if end_placement_button:
					end_placement_button.visible = false
		
		game_state_machine.GameState.TARGETING:
			print("UI Update: TARGETING state for player", current_player_index + 1)
			# This will be handled by handle_player_turn_started
			if targeting_buttons_container:
				targeting_buttons_container.visible = (current_player_index == 0)
			if end_targeting_button:
				end_targeting_button.visible = (current_player_index == 0)
	
	# For AI turns, show thinking indicator
	var is_ai_turn = (current_player_index == 1)
	if is_ai_turn:
		show_ai_thinking()
	else:
		hide_ai_thinking()
	
	# Update player name labels with visual emphasis for current player
	if player1_name_label and player2_name_label:
		if current_player_index == 0:  # Player 1
			player1_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			player2_name_label.remove_theme_color_override("font_color")
		else:  # Player 2
			player2_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			player1_name_label.remove_theme_color_override("font_color")
		
	# Update ingredients display
	update_ingredients_display()
		
	# Update turn label with visual styling
	if turn_label:
		turn_label.text = player_manager.get_current_player_name() + "'s Turn"
		
	# Update phase label with visual styling
	if phase_label:
		var phase_text = game_state_machine.GameState.keys()[current_state].capitalize().replace("_", " ") + " Phase"
		phase_label.text = phase_text
		
		# Highlight the phase label based on current state
		phase_label.remove_theme_color_override("font_color")  # Clear previous override
		
		match current_state:
			game_state_machine.GameState.UNINITIALIZED:
				phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			game_state_machine.GameState.START_SCREEN:
				phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))
			game_state_machine.GameState.BASE_PLACEMENT:
				phase_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8))
			game_state_machine.GameState.WEAPON_PLACEMENT:
				phase_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
			game_state_machine.GameState.TARGETING:
				phase_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))
			game_state_machine.GameState.ATTACK_RESOLUTION:
				phase_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			game_state_machine.GameState.GAME_OVER:
				phase_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.8))

	# Update UI to show current player's ingredients if applicable
	if player_manager and weapon_buttons_container and weapon_buttons_container.visible:
		var current_ingredients = player_manager.get_player_ingredients(current_player_index)
		
		# Update weapon placement UI to show ingredients
		var ingredients_label = weapon_buttons_container.get_node_or_null("IngredientsLabel")
		if not ingredients_label:
			ingredients_label = Label.new()
			ingredients_label.name = "IngredientsLabel"
			ingredients_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			weapon_buttons_container.add_child(ingredients_label)
			
		ingredients_label.text = "Available Ingredients: " + str(current_ingredients)
	
	# Update visibility of UI elements based on game state
	update_ui_visibility(current_state, current_player_index)

# Update visibility of UI elements based on game state
func update_ui_visibility(current_state, current_player_index):
	if !game_state_machine:
		return # Can't update without game_state_machine
	
	# Show/hide weapon buttons based on game state
	if weapon_buttons_container:
		weapon_buttons_container.visible = (
			(current_state == game_state_machine.GameState.WEAPON_PLACEMENT and current_player_index == 0) or 
			(current_state == game_state_machine.GameState.BASE_PLACEMENT and current_player_index == 0)
		)
	
	# Show/hide targeting buttons based on game state
	if targeting_buttons_container:
		targeting_buttons_container.visible = (
			current_state == game_state_machine.GameState.TARGETING and 
			current_player_index == 0
		)
	
	# Show/hide end placement button
	if end_placement_button and player_manager:
		end_placement_button.visible = (
			(current_state == game_state_machine.GameState.WEAPON_PLACEMENT and current_player_index == 0) or 
			(current_state == game_state_machine.GameState.BASE_PLACEMENT and current_player_index == 0)
		)
		
		if current_state == game_state_machine.GameState.WEAPON_PLACEMENT:
			# Make it more visible by bringing it to front and styling it
			end_placement_button.z_index = 1
			end_placement_button.modulate = Color(1, 0.8, 0.2)  # Gold color to stand out
			
			# Update button text to show which player is ending placement
			end_placement_button.text = "End " + player_manager.get_current_player_name() + "'s Placement"
		elif current_state == game_state_machine.GameState.BASE_PLACEMENT:
			end_placement_button.text = "End Base Placement"
	
	# Show/hide end targeting button
	if end_targeting_button and player_manager:
		end_targeting_button.visible = (
			current_state == game_state_machine.GameState.TARGETING and
			current_player_index == 0
		)
		
		if current_state == game_state_machine.GameState.TARGETING:
			# Make it more visible by bringing it to front and styling it
			end_targeting_button.z_index = 1
			end_targeting_button.modulate = Color(1, 0.8, 0.2)  # Gold color to stand out
			
			# Update button text to show which player is ending targeting
			end_targeting_button.text = "End " + player_manager.get_current_player_name() + "'s Targeting"

# Update resource display - legacy method now updates ingredients
func update_resource_display(player_id, amount):
	if !is_initialized or !player_manager:
		return
	
	# Get the correct ingredients label for the player - using GDScript's conditional syntax
	var ingredients_label = player1_ingredients_label if player_id == 0 else player2_ingredients_label
	
	# Update the label if we're displaying for the current player
	if player_id == player_manager.current_player_index and ingredients_label:
		# Update directly without animation for immediate feedback
		ingredients_label.text = "Ingredients: " + str(amount)
		
		# Also update our cached value
		if player_id == 0:
			last_player1_ingredients = amount
		else:
			last_player2_ingredients = amount

# Create a thinking indicator for AI turns
func create_ai_thinking_indicator():
	# We'll use a label in the bottom bar instead of a panel
	if ai_thinking_label != null:
		ai_thinking_label.queue_free()
		
	# Create a new label for the bottom bar
	ai_thinking_label = Label.new()
	ai_thinking_label.name = "AIThinkingLabel"
	ai_thinking_label.text = "AI OPPONENT IS THINKING..."
	ai_thinking_label.add_theme_font_size_override("font_size", 24)
	ai_thinking_label.add_theme_color_override("font_color", Color(1, 0.2, 0))
	ai_thinking_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ai_thinking_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ai_thinking_label.visible = false
	
	# Add to bottom bar
	if main_scene and main_scene.has_node("UI/BottomBar"):
		var bottom_bar = main_scene.get_node("UI/BottomBar")
		bottom_bar.add_child(ai_thinking_label)
		# Make it fill the bottom bar
		ai_thinking_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ai_thinking_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ai_thinking_label.anchors_preset = Control.PRESET_FULL_RECT
		print("AI thinking indicator added to bottom bar")
	else:
		print("Failed to add AI thinking indicator: Bottom bar not found")

# Show AI thinking indicator
func show_ai_thinking():
	print("UI Manager: Showing AI thinking in bottom bar")
	if ai_thinking_label:
		ai_thinking_label.visible = true
		is_ai_thinking = true
		# Hide other bottom bar elements while AI is thinking
		if weapon_buttons_container:
			weapon_buttons_container.visible = false
		if targeting_buttons_container:
			targeting_buttons_container.visible = false
		if end_placement_button:
			end_placement_button.visible = false
		if end_targeting_button:
			end_targeting_button.visible = false

# Hide AI thinking indicator
func hide_ai_thinking():
	if ai_thinking_label:
		ai_thinking_label.visible = false
		is_ai_thinking = false
		# The normal UI update will restore appropriate controls

# Update turn UI elements
func update_turn_ui(player_id):
	var turn_label = get_node_or_null("TopBar/HBoxContainer/PhaseContainer/TurnLabel") 
	if turn_label:
		if player_id == 0:
			turn_label.text = "Player 1's Turn"
		else:
			turn_label.text = "AI's Turn"
			
	# Update AI thinking indicator
	if player_id == 1:
		show_ai_thinking()
	else:
		hide_ai_thinking()

# Connect signals from AI opponent
func connect_ai_signals(ai_opponent):
	if ai_opponent:
		if ai_opponent.is_connected("thinking_started", Callable(self, "show_ai_thinking")):
			ai_opponent.disconnect("thinking_started", Callable(self, "show_ai_thinking"))
		if ai_opponent.is_connected("thinking_completed", Callable(self, "hide_ai_thinking")):
			ai_opponent.disconnect("thinking_completed", Callable(self, "hide_ai_thinking"))
		
		# Connect AI signals
		ai_opponent.connect("thinking_started", Callable(self, "show_ai_thinking"))
		ai_opponent.connect("thinking_completed", Callable(self, "hide_ai_thinking"))

# Update player UI (called from turn_manager)
func update_player_ui(new_player_index):
	# Update UI to reflect the new active player
	if player1_name_label and player2_name_label:
		if new_player_index == 0:  # Player 1
			player1_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			player2_name_label.remove_theme_color_override("font_color")
		else:  # Player 2/AI
			player2_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			player1_name_label.remove_theme_color_override("font_color")
	
	# Update turn label
	if turn_label:
		if new_player_index == 0:
			turn_label.text = "Player 1's Turn"
		else:
			turn_label.text = "AI's Turn"
	
	# Show AI thinking if it's the AI's turn
	if new_player_index == 1:
		show_ai_thinking()
	else:
		hide_ai_thinking()

# Update Player 2 label to show "AI Opponent"
func update_player2_as_ai():
	if player2_container:
		var name_label = player2_container.get_node("NameLabel")
		if name_label:
			name_label.text = "AI OPPONENT"
			name_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))

# Update the game phase label
func update_game_phase(phase_text):
	if phase_label:
		phase_label.text = phase_text

# Update current turn label
func update_current_turn(player_name):
	if turn_label:
		turn_label.text = player_name + "'s Turn"
	
	# If it's AI's turn, make sure AI thinking indicator shows
	var player_manager = get_node("/root/GameManager").player_manager if Engine.has_singleton("GameManager") else null
	if player_manager and player_manager.is_current_player_ai():
		show_ai_thinking()
	else:
		hide_ai_thinking()

# Show game over screen
func show_game_over(winning_player):
	var winner_name = "Player 1"
	var player_manager = get_node("/root/GameManager").player_manager if Engine.has_singleton("GameManager") else null
	
	if player_manager:
		winner_name = player_manager.get_player_name(winning_player)
	
	# Create game over message
	var game_over_message = Label.new()
	game_over_message.name = "GameOverMessage"
	game_over_message.text = winner_name + " wins!"
	game_over_message.add_theme_color_override("font_color", Color(1, 0.8, 0))
	game_over_message.add_theme_font_size_override("font_size", 36)
	game_over_message.position = Vector2(400, 300)
	
	# Add to UI
	var ui_container = get_tree().get_root().get_node("Main/UI")
	if ui_container:
		ui_container.add_child(game_over_message)

# Handle player turn started (simplified version used for signal connections)
func handle_player_turn_update(player_index):
	update_current_turn(get_node("/root/GameManager").player_manager.get_player_name(player_index))