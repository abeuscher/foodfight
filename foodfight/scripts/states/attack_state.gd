extends Node

signal attack_executed(attacking_weapon, target_position, damage)
signal attack_completed()

# References to game components
var game_board
var weapon_types
var visual_manager

# Dependencies
@onready var weapon_manager = $WeaponManager
@onready var targeting_manager = $TargetingManager

# Initialization flag
var is_initialized = false

func initialize(p_game_board, p_weapon_types):
	print("Initializing AttackState...")
	game_board = p_game_board
	weapon_types = p_weapon_types
	
	# Check for required components
	if !game_board or !weapon_types:
		push_error("AttackState: Missing required components")
		return false
	
	if game_board.has_node("VisualManager"):
		visual_manager = game_board.get_node("VisualManager")
	
	# Validate child components
	if !weapon_manager or !targeting_manager:
		push_error("AttackState: Missing required child components")
		return false
	
	# Initialize child components
	weapon_manager.initialize(game_board)
	targeting_manager.initialize(game_board)
	
	is_initialized = true
	print("Attack state initialized")
	return true

# Execute all queued attacks from the targeting phase
func execute_queued_attacks(queued_attacks):
	if !is_initialized:
		push_error("AttackState: Cannot execute attacks - not initialized")
		emit_signal("attack_completed")
		return
	
	print("Executing queued attacks: ", queued_attacks.size(), " attacks")
	
	# No attacks to execute
	if queued_attacks.size() == 0:
		print("No attacks to execute")
		emit_signal("attack_completed")
		return
	
	# Process each attack in the queue
	for attack in queued_attacks:
		_execute_single_attack(attack)
		# Add delay between attacks for visualization
		await get_tree().create_timer(1.0).timeout
	
	# Signal that all attacks are completed
	print("All attacks executed, attack phase completed")
	emit_signal("attack_completed")

# Execute a single attack
func _execute_single_attack(attack):
	var weapon = attack.weapon
	var target_position = attack.target_position
	var player_id = attack.player_id
	
	# Get the cell at target position
	var target_cell = game_board.get_cell_at_position(game_board.grid_to_world(target_position))
	if !target_cell:
		print("Error: No cell found at target position ", target_position)
		return
		
	print("Player ", player_id + 1, " attacking with ", weapon.data.name, " at position ", target_position)
	
	# Calculate damage based on weapon specs
	var base_damage = weapon.data.damage
	var splash_radius = weapon.data.splash_radius
	
	# Get enemy player ID
	var enemy_player_id = 1 - player_id
	
	# Get targets at the attack location
	var targets_at_cell = _get_targets_at_position(enemy_player_id, target_position)
	
	# Apply damage to primary targets
	for target in targets_at_cell:
		apply_damage(target, base_damage)
	
	# Apply splash damage if any
	if splash_radius > 0 and targets_at_cell.size() > 0:
		_apply_splash_damage(enemy_player_id, target_position, targets_at_cell, base_damage, splash_radius)
	
	# Emit signal for visualization
	emit_signal("attack_executed", weapon, target_position, base_damage)

# Get targets at a specific position
func _get_targets_at_position(player_id, position):
	var targets = []
	
	for weapon in weapon_manager.get_player_weapons(player_id):
		if weapon.position == position:
			targets.append(weapon)
			
	return targets

# Apply splash damage to surrounding targets
func _apply_splash_damage(player_id, center_position, already_hit_targets, base_damage, splash_radius):
	for potential_target in weapon_manager.get_player_weapons(player_id):
		# Skip already damaged targets
		if potential_target in already_hit_targets:
			continue
			
		var distance = targeting_manager.calculate_distance(center_position, potential_target.position)
		if distance <= splash_radius:
			# Calculate splash damage (reduced by distance)
			var splash_damage = base_damage / (splash_radius + 1) * (splash_radius - distance + 1)
			apply_damage(potential_target, splash_damage)

# Apply damage to a target
func apply_damage(target, damage):
	if !is_initialized:
		return
	
	# Reduce target health
	target.health -= damage
	print("Target hit for ", damage, " damage. Health remaining: ", target.health)
	
	# Check if target is destroyed
	if target.health <= 0:
		print("Target destroyed!")
		weapon_manager.remove_weapon_from_board(target)
		
# Attack queuing
var queued_attacks = []

# Queue attacks for later execution
func queue_attacks(player_id, weapons, targets):
	print("Queueing ", weapons.size(), " attacks for Player ", player_id + 1)
	
	for i in range(weapons.size()):
		queued_attacks.append({
			"player_id": player_id,
			"weapon": weapons[i],
			"target_position": targets[i]
		})

# Execute all attacks in the queue
func execute_attacks():
	print("Executing ", queued_attacks.size(), " queued attacks")
	execute_queued_attacks(queued_attacks)
	# Clear the queue after execution
	queued_attacks = []
