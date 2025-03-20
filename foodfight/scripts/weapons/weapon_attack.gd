extends Node

signal attack_animation_completed(attacker_pos, target_pos)

# References
var game_board
var visual_manager

# Attack animation properties
var active_attacks = []
var damage_indicators = []

# Animation control
var animation_speed = 3.0  # Cells per second
var damage_indicator_lifetime = 1.5  # Seconds to show damage indicators
var damage_float_speed = 20  # Pixels per second upward movement

func initialize(p_game_board, p_visual_manager):
	game_board = p_game_board
	visual_manager = p_visual_manager
	return self

# Process function needs to be called from _process in a parent
func _process(delta):
	if active_attacks.size() > 0 or damage_indicators.size() > 0:
		process_animations(delta)

# Create an attack animation
func create_attack_animation(attacker_pos, target_pos, damage):
	print("Creating attack animation: " + str(attacker_pos) + " -> " + str(target_pos))
	
	# Add to active attacks array
	var attack = {
		"start": attacker_pos,
		"end": target_pos,
		"damage": damage,
		"progress": 0.0,
		"completed": false
	}
	
	active_attacks.append(attack)
	
	# If we're using the game board's built-in visualizations
	if game_board and game_board.has_method("visualize_attack"):
		game_board.visualize_attack(attacker_pos, target_pos, damage)
	
	return true

# Create a damage indicator
func create_damage_indicator(position, damage):
	# Convert position to world coordinates if it's a grid position
	var world_pos = position
	if game_board and "cell_size" in game_board:
		world_pos = Vector2(position.x * game_board.cell_size.x, 
		                    position.y * game_board.cell_size.y)
	
	var indicator = {
		"position": world_pos,
		"damage": damage,
		"lifetime": damage_indicator_lifetime,
		"offset": 0,      # Initial vertical offset
		"active": true
	}
	
	damage_indicators.append(indicator)
	
	# Create a visual representation of the damage
	if visual_manager and visual_manager.has_method("create_damage_number"):
		visual_manager.create_damage_number(world_pos, damage)

# Process attack animations
func process_animations(delta):
	# Update active attacks
	var i = 0
	while i < active_attacks.size():
		var attack = active_attacks[i]
		
		# Update progress
		attack.progress += delta * animation_speed
		
		# Check if attack completed
		if attack.progress >= 1.0:
			attack.progress = 1.0
			attack.completed = true
			
			# Show impact at target position
			create_damage_indicator(attack.end, attack.damage)
			
			# Emit completion signal
			emit_signal("attack_animation_completed", attack.start, attack.end)
			
			# Remove completed attack
			active_attacks.remove_at(i)
		else:
			i += 1
	
	# Update damage indicators
	i = 0
	while i < damage_indicators.size():
		var indicator = damage_indicators[i]
		
		# Update lifetime
		indicator.lifetime -= delta
		indicator.offset += delta * damage_float_speed  # Float upward
		
		# Update visual if present
		if visual_manager and visual_manager.has_method("update_damage_number"):
			var indicator_id = str(indicator.position.x) + "_" + str(indicator.position.y) + "_" + str(indicator.damage)
			visual_manager.update_damage_number(indicator_id, indicator.offset)
		
		# Remove expired indicators
		if indicator.lifetime <= 0:
			if visual_manager and visual_manager.has_method("remove_damage_number"):
				var indicator_id = str(indicator.position.x) + "_" + str(indicator.position.y) + "_" + str(indicator.damage)
				visual_manager.remove_damage_number(indicator_id)
			
			damage_indicators.remove_at(i)
		else:
			i += 1

# Get current attack animation progress
func get_animation_progress():
	if active_attacks.size() == 0:
		return 1.0  # All animations complete
	
	var total_progress = 0.0
	for attack in active_attacks:
		total_progress += attack.progress
	
	return total_progress / active_attacks.size()

# Clear all active animations
func clear_animations():
	active_attacks.clear()
	damage_indicators.clear()
