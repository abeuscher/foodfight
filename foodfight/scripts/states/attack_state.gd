extends Node

signal attack_executed(attacking_weapon, target_position, damage)
signal attack_completed()

# References to game components
@onready var game_board
@onready var weapon_types
@onready var visual_manager

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

# Execute all queued attacks from the targeting phase
func execute_queued_attacks(queued_attacks):
	if !is_initialized:
		print("Error: Cannot execute attacks - not initialized")
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
		var weapon = attack.weapon
		var target_position = attack.target_position
		var player_id = attack.player_id
		
		# Get the cell at target position
		var target_cell = game_board.get_cell_at_grid_position(target_position)
		if target_cell:
			print("Player ", player_id + 1, " attacking with ", weapon.data.name, " at position ", target_position)
			
			# Calculate damage based on weapon specs
			var base_damage = weapon.data.damage
			var splash_radius = weapon.data.splash_radius
			
			# Get enemy weapons at the target cell
			var enemy_player_id = 1 - player_id
			var targets_at_cell = []
			
			for enemy_weapon in weapon_manager.get_player_weapons(enemy_player_id):
				if enemy_weapon.position == target_position:
					targets_at_cell.append(enemy_weapon)
			
			# If there's a target at the cell, apply damage
			if targets_at_cell.size() > 0:
				# Apply direct damage to all targets at cell (usually just one)
				for target in targets_at_cell:
					apply_damage(target, base_damage)
				
				# If splash damage, find targets within splash radius
				if splash_radius > 0:
					for splash_target in weapon_manager.get_player_weapons(enemy_player_id):
						if splash_target not in targets_at_cell:  # Skip already damaged targets
							var distance = targeting_manager.calculate_distance(target_position, splash_target.position)
							if distance <= splash_radius:
								# Calculate splash damage (reduced by distance)
								var splash_damage = base_damage / (splash_radius + 1) * (splash_radius - distance + 1)
								apply_damage(splash_target, splash_damage)
			
			# Emit signal for visualization
			emit_signal("attack_executed", weapon, target_position, base_damage)
			
			# Add delay between attacks for visualization
			await get_tree().create_timer(1.0).timeout
	
	# Signal that all attacks are completed
	print("All attacks executed, attack phase completed")
	emit_signal("attack_completed")

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
