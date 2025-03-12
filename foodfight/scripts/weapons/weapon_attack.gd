extends Node

# References
var game_board
var visual_manager

# Attack animation properties
var active_attacks = []
var damage_indicators = []

func initialize(p_game_board, p_visual_manager):
	game_board = p_game_board
	visual_manager = p_visual_manager

# Create an attack animation
func create_attack_animation(attacker_pos, target_pos, damage):
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
	if game_board:
		game_board.visualize_attack(attacker_pos, target_pos, damage)

# Create a damage indicator
func create_damage_indicator(position, damage):
	var indicator = {
		"position": position,
		"damage": damage,
		"lifetime": 1.5,  # Show for 1.5 seconds
		"offset": 0,      # Initial vertical offset
		"active": true
	}
	
	damage_indicators.append(indicator)

# Process attack animations
func process_animations(delta):
	var attack_speed = 3.0  # Cells per second
	
	# Update active attacks
	var i = 0
	while i < active_attacks.size():
		var attack = active_attacks[i]
		
		# Update progress
		attack.progress += delta * attack_speed
		
		# Check if attack completed
		if attack.progress >= 1.0:
			attack.progress = 1.0
			attack.completed = true
			
			# Show impact at target position
			create_damage_indicator(attack.end, attack.damage)
			
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
		indicator.offset += delta * 20  # Float upward
		
		# Remove expired indicators
		if indicator.lifetime <= 0:
			damage_indicators.remove_at(i)
		else:
			i += 1
