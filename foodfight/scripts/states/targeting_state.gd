extends Node

signal targeting_completed()
signal player_turn_started(player_id)

# References to game components
var game_board
var weapon_manager
var targeting_manager
var targeting_visualization

# Targeting phase state
var current_player_idx = 0
var player_targets_remaining = 3  # Maximum 3 targets per player
var is_targeting_active = false
var queued_attacks = []  # Store attacks to be executed

# Initialization flag
var is_initialized = false

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame

func initialize(p_game_board, p_weapon_manager, p_targeting_manager, p_targeting_visualization):
	game_board = p_game_board
	weapon_manager = p_weapon_manager
	targeting_manager = p_targeting_manager
	targeting_visualization = p_targeting_visualization
	
	# Check for required components
	if !game_board or !weapon_manager or !targeting_manager or !targeting_visualization:
		print("Error: Required components missing in TargetingState")
		return
	
	# Connect to targeting manager's signals
	if !targeting_manager.is_connected("target_selected", Callable(self, "_on_target_selected")):
		targeting_manager.connect("target_selected", Callable(self, "_on_target_selected"))
	
	is_initialized = true
	print("Targeting state initialized")

# Start the targeting phase
func start_targeting_phase():
	if !is_initialized:
		print("Error: Cannot start targeting phase - not initialized")
		emit_signal("targeting_completed")
		return
	
	print("Starting targeting phase")
	print("Current player index at start: ", current_player_idx)
	
	# Reset state
	current_player_idx = 0
	queued_attacks = []
	
	# Make sure weapons are collected
	if weapon_manager:
		weapon_manager.collect_weapons()
	
	# Start first player's turn
	start_player_turn(current_player_idx)

# Start a player's turn
func start_player_turn(player_id):
	print("Starting player turn for player: ", player_id)
	if !is_initialized:
		return
		
	print("Starting Player ", player_id + 1, "'s targeting turn")
	
	# Reset targets remaining
	player_targets_remaining = 3
	
	# Get the main scene and update targeting buttons
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("create_targeting_buttons"):
		main_scene.create_targeting_buttons(player_id)
	print("Player weapons: ", weapon_manager.get_player_weapons(player_id).size())
	
	# Signal player turn start
	emit_signal("player_turn_started", player_id)

# End the current player's turn
func end_player_turn():
	if !is_initialized:
		return
		
	# Switch to next player or end phase
	current_player_idx += 1
	
	if current_player_idx >= 2:  # Both players have taken their turns
		# End targeting phase
		print("Both players have completed targeting")
		emit_signal("targeting_completed")
	else:
		# Start next player's turn
		start_player_turn(current_player_idx)

# Handle when player clicks "End Targeting" button
func on_end_targeting_button_pressed():
	if is_targeting_active:
		# Cancel targeting if active
		targeting_manager.deactivate_targeting()
		is_targeting_active = false
	
	end_player_turn()

# When a target is selected
func _on_target_selected(weapon, target_position):
	print("Target selected for weapon ", weapon.data.name, " at position ", target_position)
	
	# Queue the attack for later execution
	queued_attacks.append({
		"weapon": weapon,
		"target_position": target_position,
		"player_id": current_player_idx
	})
	
	# Decrease remaining targets
	player_targets_remaining -= 1
	
	# If no more targets, automatically end turn
	if player_targets_remaining <= 0:
		print("No more targets remaining, ending turn...")
		end_player_turn()
	else:
		# Update UI to show remaining targets
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel"):
			var phase_label = main_scene.get_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
			phase_label.text = "Targeting Phase (" + str(player_targets_remaining) + " targets left)"

# Handle input for targeting
func handle_input(event):
	if targeting_manager and is_targeting_active:
		targeting_manager.handle_input(event)

# Called when a weapon is selected for targeting
func select_weapon_for_targeting(weapon, player_id):
	print("Weapon selected for targeting: ", weapon.data.name)
	
	# Activate targeting mode
	is_targeting_active = true
	targeting_manager.activate_targeting()
	targeting_manager.select_weapon(weapon, player_id)

# Get the queued attacks for the attack phase
func get_queued_attacks():
	return queued_attacks