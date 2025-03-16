extends Node

# Targeting UI elements
var targeting_buttons_container
var end_targeting_button

# Dependencies
var weapon_manager
var targeting_manager
var targeting_state
var player_manager
var main_scene

# Initialization flag
var is_initialized = false

# Initialize with UI elements
func initialize(p_targeting_buttons_container, p_end_targeting_button, 
               p_weapon_manager, p_targeting_manager, p_targeting_state,
               p_player_manager, p_main_scene):
               
	targeting_buttons_container = p_targeting_buttons_container
	end_targeting_button = p_end_targeting_button
	weapon_manager = p_weapon_manager
	targeting_manager = p_targeting_manager
	targeting_state = p_targeting_state
	player_manager = p_player_manager
	main_scene = p_main_scene
	
	is_initialized = true
	print("Targeting UI Manager initialized")
	return self

# Update targeting UI
func update_targeting_ui(current_state, current_player_index):
	if !is_initialized:
		return
		
	print("TargetingUIManager: Updating targeting UI for player", current_player_index + 1)
	
	# Show/hide targeting buttons based on player
	if targeting_buttons_container:
		targeting_buttons_container.visible = (current_player_index == 0)
	
	# Show/hide end targeting button
	if end_targeting_button:
		end_targeting_button.visible = (current_player_index == 0)
		
		if current_player_index == 0:  # Player 1
			# Make it more visible by bringing it to front and styling it
			end_targeting_button.z_index = 1
			end_targeting_button.modulate = Color(1, 0.8, 0.2)  # Gold color to stand out
			
			# Update button text to show which player is ending targeting
			if player_manager:
				end_targeting_button.text = "End " + player_manager.get_current_player_name() + "'s Targeting"
	
	# Create weapon buttons for targeting if needed
	if current_player_index == 0:  # Only for human player
		handle_player_turn_started(current_player_index)

# Handle player turn started in targeting phase
func handle_player_turn_started(player_id):
	print("TargetingUIManager: Player turn started for Player ", player_id + 1)
	
	# Check if we have all necessary components
	if !is_initialized or !targeting_buttons_container:
		print("TargetingUIManager: Missing UI components for player turn")
		return
		
	if !weapon_manager:
		print("TargetingUIManager: Missing weapon_manager for player turn")
		return
	
	print("TargetingUIManager: Creating buttons for Player ", player_id + 1)
	
	# Clear existing buttons
	for child in targeting_buttons_container.get_children():
		child.queue_free()
	
	# Get player's offensive weapons only (explicitly exclude bases)
	var weapons = weapon_manager.get_player_weapons(player_id, "offensive")
	print("TargetingUIManager: Found ", weapons.size(), " offensive weapons for Player ", player_id + 1)
	
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
	
	# Update phase label to show remaining attacks
	var phase_label = main_scene.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
	if phase_label:
		phase_label.text = "Targeting Phase (3 targets left)"
	
	# Make sure end targeting button is visible
	if end_targeting_button:
		end_targeting_button.visible = true
		end_targeting_button.text = "End Player " + str(player_id + 1) + "'s Targeting"