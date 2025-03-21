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
	pass

# Initialize with required references
func initialize(p_game_board, p_weapon_manager, p_targeting_manager):
	game_board = p_game_board
	weapon_manager = p_weapon_manager
	targeting_manager = p_targeting_manager
	return true

# Start targeting for a player - update to use events
# Renamed from start_targeting_phase to start_targeting to match PhaseManager's expectations
func start_targeting(player_id):
	current_player_id = player_id
	is_targeting_active = true
	
	# Clear previous targeting data
	selected_weapon = null
	selected_weapons = []
	targets = []
	
	# Signal that player turn has started (keep for backward compatibility)
	emit_signal("player_turn_started", player_id)
	
	# Emit targeting started event
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.TARGETING_STARTED, {"player_index": player_id})
	
	return true

# For backward compatibility - redirect old function name to new function
func start_targeting_phase(player_id):
	return start_targeting(player_id)

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
	
	selected_weapon = weapon
	
	# Activate targeting manager
	targeting_manager.select_weapon(weapon, player_id)
	targeting_manager.activate_targeting()

# Handle target selection from targeting manager
func _on_target_selected(weapon, target_position):
	if !is_targeting_active:
		return
	
	# Store the targeting information
	selected_weapons.append(weapon)
	targets.append(target_position)
	
	# Reset the current selection
	selected_weapon = null
	
	# Emit target selected event
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.TARGET_SELECTED, {
			"weapon": weapon,
			"target_position": target_position
		})
	
	# Check if max targets reached
	if selected_weapons.size() >= max_targets:
		on_end_targeting_button_pressed()

# End targeting button handler
func on_end_targeting_button_pressed():
	if !is_targeting_active:
		return
	
	is_targeting_active = false
	
	# Deactivate targeting
	targeting_manager.deactivate_targeting()
	
	# Emit targeting completed event
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.TARGETING_COMPLETED, {
			"player_index": current_player_id,
			"weapons": selected_weapons,
			"targets": targets
		})
	
	# Signal that targeting is done (keep for backward compatibility)
	emit_signal("targeting_completed", current_player_id, selected_weapons, targets)

# Get the current targeting data
func get_targeting_data():
	return {
		"player_id": current_player_id,
		"weapons": selected_weapons,
		"targets": targets
	}
