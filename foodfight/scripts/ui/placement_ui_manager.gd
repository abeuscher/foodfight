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
	return self

# Update base placement UI
func update_base_placement_ui(current_state, current_player_index):
	if !is_initialized:
		return
		
	print("PlacementUIManager: Updating base placement UI for player", current_player_index + 1)
	
	# First, clear existing weapon buttons
	if weapon_buttons_container:
		for child in weapon_buttons_container.get_children():
			if child.name != "IngredientsLabel":  # Keep ingredients label
				child.queue_free()
	
	if current_player_index == 0:  # Only human player gets UI
		create_base_placement_ui(current_player_index)
	else:
		# Hide buttons for AI
		if weapon_buttons_container:
			weapon_buttons_container.visible = false
		if end_placement_button:
			end_placement_button.visible = false

# Update weapon placement UI
func update_weapon_placement_ui(current_state, current_player_index):
	if !is_initialized:
		return
		
	print("PlacementUIManager: Updating weapon placement UI for player", current_player_index + 1)
	
	# First, clear existing weapon buttons
	if weapon_buttons_container:
		for child in weapon_buttons_container.get_children():
			if child.name != "IngredientsLabel":  # Keep ingredients label
				child.queue_free()
	
	if current_player_index == 0:  # Only human player gets UI
		create_weapon_placement_ui(current_player_index)
	else:
		# Hide buttons for AI
		if weapon_buttons_container:
			weapon_buttons_container.visible = false
		if end_placement_button:
			end_placement_button.visible = false

# Create base placement UI
func create_base_placement_ui(player_id):
	if !is_initialized or !weapon_buttons_container or !weapon_types:
		print("PlacementUIManager: Missing components for base placement UI")
		return
	
	print("PlacementUIManager: Creating base placement UI for Player ", player_id + 1)
	
	# Clear existing buttons
	for child in weapon_buttons_container.get_children():
		if child.name != "IngredientsLabel":  # Keep ingredients label
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
		end_placement_button.z_index = 1
		end_placement_button.modulate = Color(1, 0.8, 0.2)  # Gold color to stand out
	
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