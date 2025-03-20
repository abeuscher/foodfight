extends Node

# References to weapon systems
@onready var weapon_types
@onready var weapon_placement
@onready var weapon_buttons_container

# Track if buttons have been created for the current state
var buttons_created_for_state = false
# Debug flag - set to false to reduce console spam
var debug_input = false

func initialize(p_weapon_types, p_weapon_placement, p_weapon_buttons_container):
	weapon_types = p_weapon_types
	weapon_placement = p_weapon_placement
	weapon_buttons_container = p_weapon_buttons_container
	
	# Subscribe to state change events
	var event_bus = get_service("EventBus")
	if event_bus:
		event_bus.subscribe("STATE_CHANGED", self)
	
	return true

# Create buttons for each weapon type
func create_weapon_buttons_for_current_state():
	# Reset tracking flag at the start
	buttons_created_for_state = false
	
	if !weapon_types or !weapon_placement or !weapon_buttons_container:
		# Attempt to recover dependencies if needed
		if !weapon_types and Engine.has_singleton("GameManager"):
			weapon_types = Engine.get_singleton("GameManager").get_service("WeaponTypes")
		
		if !weapon_placement and Engine.has_singleton("GameManager"):
			weapon_placement = Engine.get_singleton("GameManager").get_service("WeaponPlacement")
		
		# If still missing dependencies, can't continue
		if !weapon_types or !weapon_placement:
			return
	
	# Clear existing buttons
	for child in weapon_buttons_container.get_children():
		child.queue_free()
	
	# Determine if we're in base placement phase
	var is_base_placement = _is_base_placement_phase()
	
	# Get the appropriate weapons for placement
	var weapons_to_show = []
	
	if is_base_placement:
		# Only show base weapon during base placement phase
		var base_weapon = weapon_types.get_base_weapon()
		if base_weapon:
			weapons_to_show.append(base_weapon)
	else:
		# Only show non-base weapons during regular weapon placement
		weapons_to_show = _get_non_base_weapons()
	
	# Create a button for each weapon type
	for weapon in weapons_to_show:
		var button = Button.new()
		button.text = weapon.name + " (" + str(weapon.cost) + ")"
		button.tooltip_text = weapon.description
		button.custom_minimum_size = Vector2(120, 40)
		
		 # Store the weapon ID directly in the button metadata
		button.set_meta("weapon_id", weapon.id)
		
		# Connect button press signal - use direct connection
		button.pressed.connect(Callable(self, "_on_weapon_button_pressed").bind(weapon.id))
		weapon_buttons_container.add_child(button)
	
	# Make weapon buttons container visible
	weapon_buttons_container.visible = true
	
	# Mark that buttons have been created for this state
	buttons_created_for_state = true

# Determine if we're in base placement phase
func _is_base_placement_phase():
	# First try using phase_manager
	var phase_manager = get_service("PhaseManager")
	if phase_manager != null and !is_instance_of(phase_manager, NullService) and "current_phase" in phase_manager:
		if "Phase" in phase_manager and "BASE_PLACEMENT" in phase_manager.Phase:
			return phase_manager.current_phase == phase_manager.Phase.BASE_PLACEMENT
	
	# Fallback to game_state_machine
	var game_state_machine = get_service("GameStateMachine")
	if game_state_machine and "current_state" in game_state_machine and "GameState" in game_state_machine:
		return game_state_machine.current_state == game_state_machine.GameState.BASE_PLACEMENT
	
	# If all else fails, assume not in base placement
	return false

# Get all weapons except base
func _get_non_base_weapons():
	var non_base_weapons = []
	for weapon in weapon_types.get_all_weapons():
		if weapon.type != "base":
			non_base_weapons.append(weapon)
			
	return non_base_weapons

# Handle weapon selection button press
func _on_weapon_button_pressed(weapon_id):
	if weapon_placement:
		weapon_placement.select_weapon_for_placement(weapon_id)

# Handle input for the placement state
func handle_input(event):
	if !weapon_placement:
		return
		
	# Check if it's a left mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# IMPORTANT: Process placement attempt directly here
		var is_base_placement = _is_base_placement_phase()
		
		if is_base_placement:
			weapon_placement.attempt_base_placement(event.global_position)
			return  # Don't forward this click further
		elif weapon_placement.selected_weapon:
			weapon_placement.attempt_weapon_placement(event.global_position)
			return  # Don't forward this click further
	
	# Only handle mouse motion and other events in weapon_placement
	if event is InputEventMouseMotion:
		weapon_placement.handle_input(event)
	
	# Handle escape key to cancel placement
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if weapon_placement.selected_weapon:
			weapon_placement.selected_weapon = null

# Handle state changes
func on_state_changed(state_data):
	var new_state = state_data.new_state
	
	# Check if this is for weapon placement or base placement state
	# 2 = BASE_PLACEMENT, 3 = WEAPON_PLACEMENT (hardcoded for safety)
	if new_state == 2 or new_state == 3:
		create_weapon_buttons_for_current_state()
		
		# Make sure parent container is visible
		if weapon_buttons_container and weapon_buttons_container.get_parent():
			weapon_buttons_container.get_parent().visible = true

# Helper method to get a service
func get_service(service_name):
	if Engine.has_singleton("GameManager"):
		return Engine.get_singleton("GameManager").get_service(service_name)
	return null
