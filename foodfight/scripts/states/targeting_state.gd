extends Node

signal targeting_completed
signal player_turn_started(player_id)

# References
var game_board
var weapon_manager
var targeting_manager

# State variables
var current_player_id = 0
var is_targeting_active = false
var selected_weapon = null
var selected_weapons = []
var targets = []
var max_targets = 3

func _ready():
	print("TargetingState ready")

# Initialize with required references
func initialize(p_game_board, p_weapon_manager, p_targeting_manager):
	print("Initializing TargetingState...")
	
	game_board = p_game_board
	weapon_manager = p_weapon_manager
	targeting_manager = p_targeting_manager
	
	print("TargetingState initialized")
	return true

# Start targeting for a player
func start_targeting_phase(player_id):
	print("TargetingState: Starting targeting for Player ", player_id + 1)
	current_player_id = player_id
	is_targeting_active = true
	
	# Clear previous targeting data
	selected_weapon = null
	selected_weapons = []
	targets = []
	
	# Signal that player turn has started
	emit_signal("player_turn_started", player_id)
	return true

# Handle input during targeting
func handle_input(event):
	if !is_targeting_active or !selected_weapon:
		return
	
	# Pass input to targeting manager
	targeting_manager.handle_input(event)

# Select a weapon to target with
func select_weapon_for_targeting(weapon, player_id):
	if !is_targeting_active:
		return
	
	print("TargetingState: Weapon selected for targeting: ", weapon.data.name)
	selected_weapon = weapon
	
	# Activate targeting manager
	targeting_manager.select_weapon(weapon, player_id)
	targeting_manager.activate_targeting()

# Handle target selection from targeting manager
func _on_target_selected(weapon, target_position):
	if !is_targeting_active:
		return
	
	print("TargetingState: Target selected at ", target_position)
	
	# Store the targeting information
	selected_weapons.append(weapon)
	targets.append(target_position)
	
	# Reset the current selection
	selected_weapon = null
	
	# Check if max targets reached
	if selected_weapons.size() >= max_targets:
		on_end_targeting_button_pressed()

# End targeting button handler
func on_end_targeting_button_pressed():
	if !is_targeting_active:
		return
	
	print("TargetingState: Ending targeting")
	is_targeting_active = false
	
	# Deactivate targeting
	targeting_manager.deactivate_targeting()
	
	# Signal that targeting is done
	emit_signal("targeting_completed", current_player_id, selected_weapons, targets)

# Get the current targeting data
func get_targeting_data():
	return {
		"player_id": current_player_id,
		"weapons": selected_weapons,
		"targets": targets
	}