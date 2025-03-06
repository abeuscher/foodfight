extends Node2D

# References
var game_board
var attack_state

# Visual elements
var range_overlay
var target_indicator
var damage_indicators = []

func _ready():
	# Create visual elements
	range_overlay = RangeOverlayNode.new()
	range_overlay.name = "RangeOverlay"
	add_child(range_overlay)
	
	target_indicator = TargetIndicatorNode.new()
	target_indicator.name = "TargetIndicator"
	add_child(target_indicator)
	
	# Set initial visibility
	range_overlay.visible = false
	target_indicator.visible = false

func initialize(p_game_board, p_attack_state):
	game_board = p_game_board
	attack_state = p_attack_state
	
	# Connect to attack signals
	if attack_state and !attack_state.is_connected("attack_executed", Callable(self, "_on_attack_executed")):
		attack_state.connect("attack_executed", Callable(self, "_on_attack_executed"))

# Show the range overlay for a specific weapon
func show_weapon_range(weapon, valid_targets):
	range_overlay.set_data(weapon, valid_targets, game_board)
	range_overlay.visible = true

# Show targeting indicator at a position
func show_target_indicator(target_pos):
	target_indicator.set_target(target_pos, game_board)
	target_indicator.visible = true

# Show damage amount at position
func show_damage_indicator(position, damage):
	var label = Label.new()
	label.text = str(int(damage))
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_font_size_override("font_size", 18)
	
	var world_pos = game_board.grid_to_world(position) + game_board.cell_size / 2
	label.position = world_pos - Vector2(10, 10) # Center the label
	
	add_child(label)
	damage_indicators.append(label)
	
	# Animation
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	
	# Remove after animation
	await tween.finished
	label.queue_free()
	damage_indicators.erase(label)

# Handle attack execution visualization
func _on_attack_executed(weapon, target_position, damage):
	# Clear targeting visualizations
	range_overlay.visible = false
	target_indicator.visible = false
	
	# Show attack line
	var attack_line = Line2D.new()
	attack_line.width = 3.0
	attack_line.default_color = Color(1.0, 0.5, 0.0)
	
	var start_pos = game_board.grid_to_world(weapon.position) + game_board.cell_size / 2
	var end_pos = game_board.grid_to_world(target_position) + game_board.cell_size / 2
	
	attack_line.add_point(start_pos)
	attack_line.add_point(end_pos)
	
	add_child(attack_line)
	
	# Show weapon effect based on type (direct vs. splash)
	if weapon.data.splash_radius > 0:
		# Splash attack effect
		var splash_effect = CPUParticles2D.new()
		splash_effect.position = end_pos
		splash_effect.amount = 50
		splash_effect.lifetime = 0.8
		splash_effect.explosiveness = 1.0
		splash_effect.spread = 180.0
		splash_effect.initial_velocity = 60.0
		splash_effect.color = Color(1.0, 0.5, 0.0)  # Orange
		
		add_child(splash_effect)
		
		# Show splash radius
		var splash_circle = SplashRadiusNode.new()
		splash_circle.position = end_pos
		splash_circle.radius = weapon.data.splash_radius * game_board.cell_size.x
		add_child(splash_circle)
		
		# Show damage indicator
		show_damage_indicator(target_position, damage)
		
		# Cleanup
		await get_tree().create_timer(1.0).timeout
		splash_effect.queue_free()
		splash_circle.queue_free()
	else:
		# Direct attack effect
		var direct_effect = CPUParticles2D.new()
		direct_effect.position = end_pos
		direct_effect.amount = 20
		direct_effect.lifetime = 0.5
		direct_effect.explosiveness = 0.8
		direct_effect.spread = 90.0
		direct_effect.initial_velocity = 40.0
		direct_effect.color = Color(1.0, 0.0, 0.0)  # Red
		
		add_child(direct_effect)
		
		# Show damage indicator
		show_damage_indicator(target_position, damage)
		
		# Cleanup
		await get_tree().create_timer(0.8).timeout
		direct_effect.queue_free()
	
	# Remove attack line
	await get_tree().create_timer(0.3).timeout
	attack_line.queue_free()

# Clear all visualizations
func clear_all():
	range_overlay.visible = false
	target_indicator.visible = false
	
	# Clear any remaining damage indicators
	for indicator in damage_indicators:
		indicator.queue_free()
	damage_indicators.clear()

# Custom Node2D subclass for range overlay
class RangeOverlayNode extends Node2D:
	var weapon = null
	var valid_targets = []
	var board = null
	
	func set_data(p_weapon, p_valid_targets, p_board):
		weapon = p_weapon
		valid_targets = p_valid_targets
		board = p_board
		queue_redraw()
	
	func _draw():
		if not weapon or not board:
			return
		
		# Draw a circle showing maximum range
		var center_pos = board.grid_to_world(weapon.position) + board.cell_size / 2
		var range_radius = weapon.data.attack_range * board.cell_size.x
		
		# Draw range circle
		draw_circle(center_pos, range_radius, Color(0.2, 0.7, 1.0, 0.1))
		draw_arc(center_pos, range_radius, 0, TAU, 32, Color(0.2, 0.7, 1.0, 0.5), 2)
		
		# Highlight valid target cells
		for target in valid_targets:
			var cell_pos = board.grid_to_world(target.position)
			var rect = Rect2(cell_pos, board.cell_size)
			
			# Draw target cell
			draw_rect(rect, Color(0.3, 1.0, 0.3, 0.3))
			draw_rect(rect, Color(0.3, 1.0, 0.3, 0.7), false, 2)

# Custom Node2D subclass for target indicator
class TargetIndicatorNode extends Node2D:
	var target_pos = null
	var board = null
	
	func set_target(p_target_pos, p_board):
		target_pos = p_target_pos
		board = p_board
		queue_redraw()
	
	func _draw():
		if not target_pos or not board:
			return
		
		var cell_pos = board.grid_to_world(target_pos)
		var center = cell_pos + board.cell_size / 2
		
		# Draw target crosshair
		var size = board.cell_size.x * 0.7
		draw_line(center - Vector2(size, 0), center + Vector2(size, 0), Color.RED, 2)
		draw_line(center - Vector2(0, size), center + Vector2(0, size), Color.RED, 2)
		
		# Draw target circle
		draw_arc(center, size / 2, 0, TAU, 16, Color.RED, 2)

# Custom Node2D subclass for splash radius visualization
class SplashRadiusNode extends Node2D:
	var radius = 0
	
	func _draw():
		if radius <= 0:
			return
		
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.5, 0.0, 0.2))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.5, 0.0, 0.5), 2)
