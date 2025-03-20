extends Node

# References to game components
var game_board
var weapon_types
var visual_manager

# Dependencies
@onready var weapon_manager = $WeaponManager
@onready var targeting_manager = $TargetingManager

# Attack settings
var attack_delay = 0.8
var ingredients_per_damage = 0.25
var min_ingredients_per_hit = 1

# Damage system constants
var min_damage_percent = 0.25

# Attack system
var attack_in_progress = false
var attack_animations_completed = 0
var total_attack_animations = 0
var attack_animation_timeout = 5.0 # Seconds to wait before auto-completing

func initialize(p_game_board, p_weapon_types):
	game_board = p_game_board
	weapon_types = p_weapon_types
	visual_manager = game_board.get_node("VisualManager")
	
	weapon_manager.initialize(game_board)
	targeting_manager.initialize(game_board)
	return true

# Execute all queued attacks from the targeting phase
func execute_queued_attacks(queued_attacks):
	# No attacks to execute
	if queued_attacks.size() == 0:
		print("No attacks in queue, completing attack phase immediately")
		var phase_manager = get_service("PhaseManager")
		if phase_manager:
			phase_manager.attack_resolution_completed()
		return
	
	# Set attack tracking variables
	attack_in_progress = true
	attack_animations_completed = 0
	total_attack_animations = queued_attacks.size()
	
	print("Executing " + str(total_attack_animations) + " queued attacks")
	
	# Process each attack in the queue with a delay between each
	for i in range(queued_attacks.size()):
		var attack = queued_attacks[i]
		await get_tree().create_timer(0.5).timeout # Short delay between attacks
		_execute_single_attack(attack)
	
	# Safety timeout in case animations don't complete properly
	get_tree().create_timer(attack_animation_timeout).timeout.connect(func():
		if attack_in_progress:
			print("Attack animations timeout - forcing completion")
			_on_all_attacks_completed()
	)

# Execute a single attack
func _execute_single_attack(attack):
	var weapon = attack.weapon
	var target_position = attack.target_position
	var player_id = attack.player_id
	
	var base_damage = weapon.data.damage
	var splash_radius = weapon.data.splash_radius
	
	var enemy_player_id = 1 - player_id
	
	var targets_at_cell = _get_targets_at_position(enemy_player_id, target_position)
	
	print("Creating attack animation from " + str(weapon.position) + " to " + str(target_position))
	
	# Create the attack visual
	if visual_manager and visual_manager.has_method("create_attack_animation"):
		visual_manager.create_attack_animation(weapon.position, target_position, base_damage)
	else:
		# Fallback to weapon_attack if available
		var weapon_attack = get_node_or_null("../WeaponAttack")
		if weapon_attack and weapon_attack.has_method("create_attack_animation"):
			weapon_attack.create_attack_animation(weapon.position, target_position, base_damage)
		else:
			print("WARNING: No visual system available for attack animations")
	
	# Apply damage after a short delay to let the animation play
	await get_tree().create_timer(attack_delay).timeout
	
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
	
	# Track attack animation completion
	attack_animations_completed += 1
	print("Attack animation completed: " + str(attack_animations_completed) + " of " + str(total_attack_animations))
	
	# Check if all animations are completed
	if attack_animations_completed >= total_attack_animations:
		_on_all_attacks_completed()

# Handle completion of all attack animations
func _on_all_attacks_completed():
	if !attack_in_progress:
		return
		
	attack_in_progress = false
	
	# Notify PhaseManager directly
	var phase_manager = get_service("PhaseManager")
	if phase_manager:
		phase_manager.attack_resolution_completed()

# Get targets at a specific position
func _get_targets_at_position(player_id, position):
	var targets = []
	
	for weapon in weapon_manager.get_player_weapons(player_id):
		var root_pos = weapon.position
		var size = weapon.data.size
		
		# Check if the target position is within the area covered by this weapon
		for x in range(size.x):
			for y in range(size.y):
				var check_pos = Vector2(root_pos.x + x, root_pos.y + y)
				if check_pos == position:
					targets.append(weapon)
					break
			
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
	var original_health = target.health
	
	var defense_bonus = weapon_manager.get_defensive_bonus(target.position, target.player_id)
	
	var modified_damage = damage
	if defense_bonus > 0:
		var damage_reduction = clamp(defense_bonus * 0.25, 0, 0.75)
		modified_damage = damage * (1.0 - damage_reduction)
		modified_damage = max(modified_damage, damage * min_damage_percent)
	
	# Reduce target health
	target.health = max(0, target.health - modified_damage)
	
	# Calculate actual damage dealt
	var actual_damage = original_health - target.health
	
	# Show damage numbers and update health bars
	if visual_manager and visual_manager.has_method("show_weapon_damage"):
		visual_manager.show_weapon_damage(target, actual_damage)
	
	# Update weapon health display
	weapon_manager.update_weapon_health_display(target)
	
	# Check if target is destroyed
	if target.health <= 0:
		weapon_manager.remove_weapon_from_board(target)
	
	return actual_damage

# Award ingredients to a player based on damage dealt
func award_points(player_id, damage):
	var ingredients = max(min_ingredients_per_hit, int(floor(damage * ingredients_per_damage)))
	
	# Notify GameManager directly
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		game_manager.emit_event(GameEvents.INGREDIENTS_AWARDED, {
			"player_id": player_id,
			"amount": ingredients
		})

# Attack queuing
var queued_attacks = []

# Queue attacks for later execution
func queue_attacks(player_id, weapons, targets):
	for i in range(weapons.size()):
		queued_attacks.append({
			"player_id": player_id,
			"weapon": weapons[i],
			"target_position": targets[i]
		})

# Execute all attacks in the queue
func execute_attacks():
	print("Executing all queued attacks: " + str(queued_attacks.size()) + " attacks")
	execute_queued_attacks(queued_attacks)
	queued_attacks = []

# Check for game over condition
func check_game_over():
	# Check if all bases of player 0 are destroyed
	var player0_has_bases = false
	for weapon in weapon_manager.get_player_weapons(0):
		if weapon.data.type == "base":
			player0_has_bases = true
			break
	
	# Check if all bases of player 1 are destroyed
	var player1_has_bases = false
	for weapon in weapon_manager.get_player_weapons(1):
		if weapon.data.type == "base":
			player1_has_bases = true
			break
	
	# Return winning player ID or -1 if no winner yet
	if !player0_has_bases:
		return 1 # Player 2 wins
	elif !player1_has_bases:
		return 0 # Player 1 wins
	else:
		return -1 # No winner yet

# Helper method to get a service using the service locator pattern
func get_service(service_name):
	if Engine.has_singleton("GameManager"):
		return Engine.get_singleton("GameManager").get_service(service_name)
	return null
