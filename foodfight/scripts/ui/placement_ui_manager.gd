extends Node

# Placement UI elements
var weapon_buttons_container
var end_placement_button

# Dependencies
var weapon_placement
var weapon_types
var player_manager
var main_scene

# Initialization flag
var is_initialized = false

# Track if buttons have been connected
var buttons_connected = false

# Initialize with UI elements
func initialize(p_weapon_buttons_container, p_end_placement_button, p_weapon_placement, p_weapon_types, p_player_manager, p_main_scene):
	weapon_buttons_container = p_weapon_buttons_container
	end_placement_button = p_end_placement_button
	weapon_placement = p_weapon_placement
	weapon_types = p_weapon_types
	player_manager = p_player_manager
	main_scene = p_main_scene
	
	is_initialized = true
	print("Placement UI Manager initialized")
	
	# Connect end placement button signal
	_connect_end_placement_button()
	
	return self

# Update base placement UI
func update_base_placement_ui(current_state, current_player_index):
	print("PlacementUIManager: update_base_placement_ui called for state " + str(current_state) + " and player " + str(current_player_index + 1))
	if !is_initialized:
		return
		
	print("PlacementUIManager: Updating base placement UI for player", current_player_index + 1)
	
	# First, clear existing weapon buttons
	if weapon_buttons_container:
		for child in weapon_buttons_container.get_children():
			if child.name != "IngredientsLabel": # Keep ingredients label
				child.queue_free()
	
	if current_player_index == 0: # Only human player gets UI
		create_base_placement_ui(current_player_index)
	else:
		# Hide buttons for AI
		if weapon_buttons_container:
			weapon_buttons_container.visible = false
		if end_placement_button:
			end_placement_button.visible = false
	
	if end_placement_button:
		# MISSING VALIDATION: Should check if base is placed before enabling this button
		end_placement_button.text = "End Base Placement"
		end_placement_button.visible = true
		
		# Connect signal if not already connected
		if !buttons_connected:
			_connect_end_placement_button()
	
	# Hide weapon buttons during base placement
	if weapon_buttons_container:
		weapon_buttons_container.visible = false

# Update weapon placement UI
func update_weapon_placement_ui(current_state, current_player_index):
	print("PlacementUIManager: update_weapon_placement_ui called for state " + str(current_state) + " and player " + str(current_player_index + 1))
	if !is_initialized:
		return
		
	print("PlacementUIManager: Updating weapon placement UI for player", current_player_index + 1)
	
	# First, clear existing weapon buttons
	if weapon_buttons_container:
		for child in weapon_buttons_container.get_children():
			if child.name != "IngredientsLabel": # Keep ingredients label
				child.queue_free()
	
	if current_player_index == 0: # Only human player gets UI
		create_weapon_placement_ui(current_player_index)
	else:
		# Hide buttons for AI
		if weapon_buttons_container:
			weapon_buttons_container.visible = false
		if end_placement_button:
			end_placement_button.visible = false
	
	# Show the container
	if weapon_buttons_container and weapon_buttons_container.get_parent():
		weapon_buttons_container.get_parent().visible = true
		weapon_buttons_container.visible = true
	
	# Update end placement button
	if end_placement_button:
		# Check if button signal is connected
		if !buttons_connected:
			_connect_end_placement_button()
		
		end_placement_button.text = "End Placement"
		end_placement_button.visible = true
	
	# Create weapon buttons
	_create_weapon_buttons_for_player(current_player_index)

# Create base placement UI
func create_base_placement_ui(player_id):
	if !is_initialized or !weapon_buttons_container or !weapon_types:
		print("PlacementUIManager: Missing components for base placement UI")
		return
	
	print("PlacementUIManager: Creating base placement UI for Player ", player_id + 1)
	
	# Clear existing buttons
	for child in weapon_buttons_container.get_children():
		if child.name != "IngredientsLabel": # Keep ingredients label
			child.queue_free()
	
	# Get the base weapon type
	var base_weapon = weapon_types.get_base_weapon()
	if !base_weapon:
		print("PlacementUIManager: No base weapon type found")
		return
	
	# Create a button for placing the base
	var button = Button.new()
	button.text = base_weapon.name
	button.tooltip_text = "Size: " + str(base_weapon.size.x) + "x" + str(base_weapon.size.y) + "\n" + \
					   "Your main base. Protect it at all costs!"
	
	# Style the button to make it prominent
	button.custom_minimum_size = Vector2(180, 40)
	button.modulate = Color(1, 0.8, 0.2) # Gold color
	
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
	
	# Update ingredients display in the container
	update_ingredients_display(player_id)

# Create weapon placement UI
func create_weapon_placement_ui(player_id):
	if !is_initialized or !weapon_buttons_container or !weapon_types:
		print("PlacementUIManager: Missing components for weapon placement UI")
		return
	
	print("PlacementUIManager: Creating weapon placement UI for Player ", player_id + 1)
	
	# Clear existing buttons
	for child in weapon_buttons_container.get_children():
		if child.name != "IngredientsLabel": # Keep ingredients label
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
		end_placement_button.z_index = 1
		end_placement_button.modulate = Color(1, 0.8, 0.2) # Gold color to stand out
	
	# Update ingredients display in the container
	update_ingredients_display(player_id)

# Get all non-base weapons from weapon_types
func _get_non_base_weapons():
	var non_base_weapons = []
	if weapon_types:
		for weapon in weapon_types.get_all_weapons():
			if "type" in weapon and weapon.type != "base":
				non_base_weapons.append(weapon)
	return non_base_weapons

# Handle base button pressed
func _on_base_button_pressed(base_id, player_id):
	if !is_initialized or !weapon_placement:
		return
	
	print("PlacementUIManager: Base button pressed for Player ", player_id + 1)
	weapon_placement.select_weapon_for_placement(base_id)

# Handle weapon button pressed
func _on_weapon_button_pressed(weapon_id):
	if !is_initialized or !weapon_placement:
		return
	
	print("PlacementUIManager: Weapon button pressed: ", weapon_id)
	weapon_placement.select_weapon_for_placement(weapon_id)

# Update ingredients display in weapon buttons container
func update_ingredients_display(player_id):
	if !player_manager or !weapon_buttons_container or !weapon_buttons_container.visible:
		return
		
	var current_ingredients = player_manager.get_player_ingredients(player_id)
	
	# Update weapon placement UI to show ingredients
	var ingredients_label = weapon_buttons_container.get_node_or_null("IngredientsLabel")
	if not ingredients_label:
		ingredients_label = Label.new()
		ingredients_label.name = "IngredientsLabel"
		ingredients_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		weapon_buttons_container.add_child(ingredients_label)
		
	ingredients_label.text = "Available Ingredients: " + str(current_ingredients)

# Create weapon buttons for the specified player
func _create_weapon_buttons_for_player(player_index):
	print("PlacementUIManager: Creating weapon placement UI for Player " + str(player_index + 1))
	
	# Ensure dependencies are available
	if !weapon_types or !weapon_buttons_container:
		push_error("Cannot create weapon buttons: missing dependencies")
		return
	
	# Clear existing buttons
	for child in weapon_buttons_container.get_children():
		child.queue_free()
	
	# Get weapons for the player
	var weapons = weapon_types.get_weapons_for_player(player_index)
	if weapons.size() == 0:
		print("No weapons available for player " + str(player_index + 1))
		return
	
	# Filter out base weapons for regular placement phase
	var placement_weapons = []
	for weapon in weapons:
		if weapon.type != "base":
			placement_weapons.append(weapon)
	
	print("Found " + str(placement_weapons.size()) + " weapons for placement")

# Connect the end placement button signal
func _connect_end_placement_button():
	if end_placement_button:
		# Disconnect any existing connections to avoid duplicates
		if end_placement_button.pressed.is_connected(Callable(self, "_on_end_placement_pressed")):
			end_placement_button.pressed.disconnect(Callable(self, "_on_end_placement_pressed"))
		
		# Connect the signal
		end_placement_button.pressed.connect(Callable(self, "_on_end_placement_pressed"))
		buttons_connected = true

# Handler for end placement button
func _on_end_placement_pressed():
	if !weapon_placement:
		return
	
	var is_base_phase = false
	var phase_manager = null
	if Engine.has_singleton("GameManager"):
		phase_manager = Engine.get_singleton("GameManager").get_service("PhaseManager")
	
	if phase_manager and "Phase" in phase_manager and "current_phase" in phase_manager:
		is_base_phase = (phase_manager.current_phase == phase_manager.Phase.BASE_PLACEMENT)
	else:
		var game_state_machine = null
		if Engine.has_singleton("GameManager"):
			game_state_machine = Engine.get_singleton("GameManager").get_service("GameStateMachine")
		
		if game_state_machine and "GameState" in game_state_machine and "current_state" in game_state_machine:
			is_base_phase = (game_state_machine.current_state == game_state_machine.GameState.BASE_PLACEMENT)
	
	if is_base_phase:
		var current_player = 0
		if player_manager and "current_player_index" in player_manager:
			current_player = player_manager.current_player_index
			
		if !weapon_placement.base_placement_complete[current_player]:
			return
	
	weapon_placement.end_placement_phase()
