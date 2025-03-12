extends Node

# References to weapon systems
@onready var weapon_types
@onready var weapon_placement
@onready var weapon_buttons_container

func initialize(p_weapon_types, p_weapon_placement, p_weapon_buttons_container):
	weapon_types = p_weapon_types
	weapon_placement = p_weapon_placement
	weapon_buttons_container = p_weapon_buttons_container
	
	# Create weapon selection buttons
	_create_weapon_buttons()

# Create buttons for each weapon type
func _create_weapon_buttons():
	# Clear existing buttons
	for child in weapon_buttons_container.get_children():
		child.queue_free()
	
	# Determine if we're in base placement phase
	var is_base_placement = false
	
	# Try different ways to check the current state
	if Engine.has_singleton("GameManager"):
		var game_state_machine = Engine.get_singleton("GameManager").game_state_machine
		if game_state_machine:
			is_base_placement = game_state_machine.current_state == game_state_machine.GameState.BASE_PLACEMENT
			print("PlacementState: Using GameManager to determine state: BASE_PLACEMENT =", is_base_placement)
	else:
		# Fallback method: check if weapon_placement knows it's in base placement phase
		if weapon_placement and "is_base_placement_phase" in weapon_placement:
			is_base_placement = weapon_placement.is_base_placement_phase
			print("PlacementState: Using fallback method to determine state: BASE_PLACEMENT =", is_base_placement)
	
	# Get the appropriate weapons for placement
	var weapons_to_show = []
	
	if is_base_placement:
		print("PlacementState: In BASE_PLACEMENT phase - showing only base")
		# Only show base weapon during base placement phase
		var base_weapon = weapon_types.get_base_weapon()
		if base_weapon:
			weapons_to_show.append(base_weapon)
	else:
		print("PlacementState: In WEAPON_PLACEMENT phase - excluding bases")
		# Only show non-base weapons during regular weapon placement
		weapons_to_show = _get_non_base_weapons()
	
	# Create a button for each weapon type
	for weapon in weapons_to_show:
		var button = Button.new()
		button.text = weapon.name + " (" + str(weapon.cost) + ")"
		button.tooltip_text = weapon.description
		button.custom_minimum_size = Vector2(120, 40)
		button.connect("pressed", _on_weapon_button_pressed.bind(weapon.id))
		weapon_buttons_container.add_child(button)

# Get all weapons except base
func _get_non_base_weapons():
	var non_base_weapons = []
	for weapon in weapon_types.get_all_weapons():
		var is_base = false
		
		# More thoroughly check if it's a base
		if "type" in weapon and weapon.type == "base":
			is_base = true
		elif "id" in weapon and str(weapon.id).to_lower().contains("base"):
			is_base = true
		
		if !is_base:
			non_base_weapons.append(weapon)
			
	print("PlacementState: Found", non_base_weapons.size(), "non-base weapons")
	return non_base_weapons

# Handle weapon selection button press
func _on_weapon_button_pressed(weapon_id):
	weapon_placement.select_weapon_for_placement(weapon_id)

# Handle input for the placement state
func handle_input(event):
	# Forward input to weapon placement system
	weapon_placement.handle_input(event)
	
	# Handle escape key to cancel placement
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if weapon_placement.selected_weapon:
			weapon_placement.selected_weapon = null
