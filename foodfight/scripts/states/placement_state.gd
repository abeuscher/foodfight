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
	
	# Get state from game state machine
	var game_state_machine = Engine.get_singleton("GameManager").game_state_machine
	var is_base_placement = game_state_machine.current_state == game_state_machine.GameState.BASE_PLACEMENT
	
	# Get the appropriate weapons for placement
	var weapons_to_show = []
	
	if is_base_placement:
		# Only show base weapon during base placement phase
		weapons_to_show.append(weapon_types.get_base_weapon())
	else:
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
		if weapon.type != "base":
			non_base_weapons.append(weapon)
			
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
