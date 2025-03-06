extends Node

signal attack_executed(attacking_weapon, target_position, damage)
signal attack_completed()

# References to game components
@onready var game_board
@onready var weapon_types
@onready var visual_manager

# Attack phase state
var current_tick = 0
var total_ticks = 10

# Dependencies
var weapon_manager
var targeting_manager

# Initialization flag
var is_initialized = false

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Initialize dependencies
	if has_node("WeaponManager"):
		weapon_manager = get_node("WeaponManager")
	else:
		print("Error: WeaponManager node not found")
	
	if has_node("TargetingManager"):
		targeting_manager = get_node("TargetingManager")
	else:
		print("Error: TargetingManager node not found")

func initialize(p_game_board, p_weapon_types):
	game_board = p_game_board
	weapon_types = p_weapon_types
	
	# Check for required components
	if !game_board:
		print("Error: No game board provided to AttackState")
		return
	
	if !weapon_types:
		print("Error: No weapon types provided to AttackState")
		return
	
	if game_board.has_node("VisualManager"):
		visual_manager = game_board.get_node("VisualManager")
	
	# Initialize dependencies
	if weapon_manager:
		print("WeaponManager node exists: ", weapon_manager != null)
		print("WeaponManager script exists: ", weapon_manager.get_script() != null)
		if weapon_manager.get_script():
			print("WeaponManager script path: ", weapon_manager.get_script().resource_path)
		weapon_manager.initialize(game_board)
	else:
		print("Error: WeaponManager not found")
		return
	
	if targeting_manager:
		targeting_manager.initialize(game_board)
	else:
		print("Error: TargetingManager not found")
		return
	
	is_initialized = true
	print("Attack state initialized")

# Start the attack phase
func start_attack_phase():
	if !is_initialized:
		print("Error: Cannot start attack phase - not initialized")
		emit_signal("attack_completed")
		return
	
	print("Starting attack phase")
	
	# Reset state
	current_tick = 0
	
	# Collect weapons
	weapon_manager.collect_weapons()
	
	# Reset cooldowns
	weapon_manager.reset_weapon_cooldowns()
	
	# Process first tick after a short delay
	await get_tree().create_timer(0.5).timeout
	process_tick()

# Process each tick of the attack phase
func process_tick():
	if !is_initialized:
		print("Error: Cannot process tick - not initialized")
		emit_signal("attack_completed")
		return
	
	current_tick += 1
	print("Processing tick: ", current_tick, "/", total_ticks)
	
	# Process each weapon for both players
	for player_idx in range(2):
		var weapons = weapon_manager.get_player_weapons(player_idx)
		for weapon in weapons:
			# If weapon has no cooldown, it can attack
			if weapon.current_cooldown <= 0:
				# Enemy player is (1-player_idx)
				var target = targeting_manager.get_target_for_weapon(weapon, player_idx)
				if target:
					execute_attack(weapon, target, player_idx)
					# Reset cooldown after attack
					weapon.current_cooldown = weapon.data.cooldown
			else:
				# Decrease cooldown for next tick
				weapon.current_cooldown -= 1
	
	# Check if attack phase is complete
	if current_tick >= total_ticks:
		emit_signal("attack_completed")
		return
	
	# Continue with next tick after a delay
	await get_tree().create_timer(1.0).timeout
	if current_tick < total_ticks:
		process_tick()

# Execute an attack
func execute_attack(weapon, target, player_id):
	if !is_initialized:
		return
	
	print("Player ", player_id + 1, " attacking with ", weapon.data.name, " at position ", target.position)
	
	# Calculate damage based on weapon specs
	var base_damage = weapon.data.damage
	var splash_radius = weapon.data.splash_radius
	
	# Apply direct damage to target
	apply_damage(target, base_damage)
	
	# If splash damage, find targets within splash radius
	if splash_radius > 0:
		for splash_target in weapon_manager.get_player_weapons(1-player_id):
			var distance = targeting_manager.calculate_distance(target.position, splash_target.position)
			if distance <= splash_radius and splash_target != target:
				# Calculate splash damage (reduced by distance)
				var splash_damage = base_damage / (splash_radius + 1) * (splash_radius - distance + 1)
				apply_damage(splash_target, splash_damage)
	
	# Emit signal for visualization
	emit_signal("attack_executed", weapon, target.position, base_damage)

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
		# Remove weapon from board
		if weapon_manager:
			weapon_manager.remove_weapon_from_board(target)

# Handle input for targeting - will be refactored to targeting_manager
func handle_input(event):
	if targeting_manager:
		targeting_manager.handle_input(event)
