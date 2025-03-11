extends Node

signal attack_executed(attacking_weapon, target_position, damage)
signal attack_completed()
signal points_awarded(player_id, points)

# References to game components
var game_board
var weapon_types
var visual_manager

# Dependencies
@onready var weapon_manager = $WeaponManager
@onready var targeting_manager = $TargetingManager

# Attack settings
var attack_delay = 0.8  # Seconds between attacks
var points_per_damage = 10  # Points awarded per damage point

func initialize(p_game_board, p_weapon_types):
	print("Initializing AttackState...")
	game_board = p_game_board
	weapon_types = p_weapon_types
	
	if game_board.has_node("VisualManager"):
		visual_manager = game_board.get_node("VisualManager")
	
	# Initialize child components
	weapon_manager.initialize(game_board)
	targeting_manager.initialize(game_board)
	
	print("Attack state initialized")
	return true

# Execute all queued attacks from the targeting phase
func execute_queued_attacks(queued_attacks):
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
		await get_tree().create_timer(attack_delay).timeout
	
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
	
	print("Player ", player_id + 1, " attacking with ", weapon.data.name, " at position ", target_position)
	
	# Calculate damage based on weapon specs
	var base_damage = weapon.data.damage
	var splash_radius = weapon.data.splash_radius
	
	# Get enemy player ID
	var enemy_player_id = 1 - player_id
	
	# Get targets at the attack location
	var targets_at_cell = _get_targets_at_position(enemy_player_id, target_position)
	
	# Visualize the attack
	if visual_manager:
		visual_manager.create_attack_animation(weapon.position, target_position, base_damage)
	else:
		# Fallback to basic visualization if visual_manager isn't available
		game_board.visualize_attack(weapon.position, target_position, base_damage)
	
	# Track total damage for scoring
	var total_damage = 0
	
	# Apply damage to primary targets
	for target in targets_at_cell:
		var damage_dealt = apply_damage(target, base_damage)
		total_damage += damage_dealt
	
	# Apply splash damage if any
	if splash_radius > 0 and targets_at_cell.size() > 0:
		var splash_damage = _apply_splash_damage(enemy_player_id, target_position, targets_at_cell, base_damage, splash_radius)
		total_damage += splash_damage
	
	# Award points based on damage dealt
	if total_damage > 0:
		award_points(player_id, total_damage)
	
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
	var total_splash_damage = 0
	
	for potential_target in weapon_manager.get_player_weapons(player_id):
		# Skip already damaged targets
		if potential_target in already_hit_targets:
			continue
			
		var distance = targeting_manager.calculate_distance(center_position, potential_target.position)
		if distance <= splash_radius:
			# Calculate splash damage (reduced by distance)
			var splash_damage = base_damage / (splash_radius + 1) * (splash_radius - distance + 1)
			var damage_dealt = apply_damage(potential_target, splash_damage)
			total_splash_damage += damage_dealt
	
	return total_splash_damage

# Apply damage to a target
func apply_damage(target, damage):
	# Store original health for damage calculation
	var original_health = target.health
	
	# Reduce target health
	target.health -= damage
	
	# Calculate actual damage dealt (avoid negative health)
	var actual_damage = original_health - max(0, target.health)
	
	print("Target hit for ", actual_damage, " damage. Health remaining: ", target.health)
	
	# Update visual representation of health
	if visual_manager:
		visual_manager.show_weapon_damage(target, actual_damage)
	
	# Check if target is destroyed
	if target.health <= 0:
		print("Target destroyed!")
		weapon_manager.remove_weapon_from_board(target)
	
	return actual_damage

# Award points to a player based on damage dealt
func award_points(player_id, damage):
	var points = int(damage * points_per_damage)
	print("Player ", player_id + 1, " awarded ", points, " points for dealing ", damage, " damage")
	
	# Emit signal for score tracking
	emit_signal("points_awarded", player_id, points)

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

# Check for game over condition
func check_game_over():
	# Check if all bases of player 0 are destroyed
	var player0_has_bases = false
	for weapon in weapon_manager.get_player_weapons(0):
		# Check if the data has a type property
		if "data" in weapon and weapon.data is Object and weapon.data.has_method("get_type"):
			if weapon.data.get_type() == "base":
				player0_has_bases = true
				break
		# Or try to check the "id" property as a fallback to identify bases
		elif "data" in weapon and "id" in weapon.data:
			var id = str(weapon.data.id).to_lower()
			if id.contains("base"):
				player0_has_bases = true
				break
	
	# Check if all bases of player 1 are destroyed
	var player1_has_bases = false
	for weapon in weapon_manager.get_player_weapons(1):
		# Check if the data has a type property
		if "data" in weapon and weapon.data is Object and weapon.data.has_method("get_type"):
			if weapon.data.get_type() == "base":
				player1_has_bases = true
				break
		# Or try to check the "id" property as a fallback to identify bases
		elif "data" in weapon and "id" in weapon.data:
			var id = str(weapon.data.id).to_lower()
			if id.contains("base"):
				player1_has_bases = true
				break
	
	# Return winning player ID or -1 if no winner yet
	if !player0_has_bases:
		return 1  # Player 2 wins
	elif !player1_has_bases:
		return 0  # Player 1 wins
	else:
		return -1  # No winner yet
