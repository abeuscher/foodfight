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
	
	# Create a button for each weapon type
	for weapon in weapon_types.get_all_weapons():
		var button = Button.new()
		button.text = weapon.name + " (" + str(weapon.cost) + ")"
		button.tooltip_text = weapon.description
		button.custom_minimum_size = Vector2(120, 40)
		button.connect("pressed", _on_weapon_button_pressed.bind(weapon.id))
		weapon_buttons_container.add_child(button)

# Handle weapon selection button press
func _on_weapon_button_pressed(weapon_id):
	weapon_placement.select_weapon(weapon_id)

# Handle input for the placement state
func handle_input(event):
	# Forward input to weapon placement system
	weapon_placement.process_input(event)
	
	# Handle escape key to cancel placement
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if weapon_placement.placing_weapon:
			weapon_placement.cancel_placement()
