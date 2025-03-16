extends Node

# Reference to the board core
@onready var board_core
# Reference to weapon types system
var weapon_types

# Dictionaries to store weapon visuals
var weapon_sprites = {}
var health_bars = {}
var max_health = 10.0  # Default max health

# New member variables for damage indicators
var damage_indicators = []
var font # Will hold reference to the damage number font

# Add this function to visual_manager.gd
func initialize(weapon_types_ref):
	weapon_types = weapon_types_ref
	# Get reference to the board core
	board_core = get_parent()

# And update the _ready function
func _ready():
	# Get reference to the board core
	board_core = get_parent()
	
	# Create default font for damage numbers
	font = ThemeDB.fallback_font
	
	# Process indicators each frame
	set_process(true)

func _process(delta):
	# Update damage indicators
	process_damage_indicators(delta)

# Clear all weapon sprites
func clear_weapon_sprites():
	for sprite in weapon_sprites.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	weapon_sprites.clear()
	
	# Also clear health bars
	for bar in health_bars.values():
		if is_instance_valid(bar.container):
			bar.container.queue_free()
	health_bars.clear()

# Create a visual sprite for the weapon
func create_weapon_sprite(weapon_id, grid_position, player_id):
	# Create a unique ID for this weapon instance
	var instance_id = str(player_id) + "_" + weapon_id + "_" + str(grid_position.x) + "_" + str(grid_position.y)
	
	# Create a new sprite for the weapon
	var sprite = Sprite2D.new()
	board_core.add_child(sprite)
	
	# Get weapon data
	var weapon = weapon_types.get_weapon_by_id(weapon_id)
	
	# Set sprite position - top-left corner of the grid cell
	var world_pos = Vector2(
		grid_position.x * board_core.cell_size.x,
		grid_position.y * board_core.cell_size.y
	)
	
	# For multi-cell weapons, we want to place the sprite to cover all cells
	var texture_size = Vector2(weapon.size.x * board_core.cell_size.x, weapon.size.y * board_core.cell_size.y)
	
	# Position sprite at the center of the weapon's area
	sprite.position = world_pos + texture_size / 2
	
	# For now, create a colored rectangle as placeholder
	var image = Image.create(int(texture_size.x), int(texture_size.y), false, Image.FORMAT_RGBA8)
	
	# Fill with color based on player (red for player 1, blue for player 2)
	var color = Color(1, 0.3, 0.3, 0.8) if player_id == 0 else Color(0.3, 0.3, 1, 0.8)
	image.fill(color)
	
	# Create texture from image
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	# Store sprite for reference
	weapon_sprites[instance_id] = sprite
	
	# Create health bar for this weapon
	create_health_bar(instance_id, grid_position, weapon)
	
	return sprite

# Create a placement preview for when the player is placing weapons
func create_placement_preview(weapon_data, grid_position, is_valid):
	# Create preview rectangle
	var preview = ColorRect.new()
	preview.size = Vector2(
		weapon_data.size.x * board_core.cell_size.x,
		weapon_data.size.y * board_core.cell_size.y
	)
	preview.position = Vector2(
		grid_position.x * board_core.cell_size.x,
		grid_position.y * board_core.cell_size.y
	)
	
	# Set color based on validity
	if is_valid:
		preview.color = Color(0, 1, 0, 0.3)  # Green for valid placement
	else:
		preview.color = Color(1, 0, 0, 0.3)  # Red for invalid placement
	
	return preview

# Create a health bar for a weapon
func create_health_bar(instance_id, grid_position, weapon_data):
	# Create container for health bar
	var container = Control.new()
	board_core.add_child(container)
	
	# Position at the top of the weapon sprite
	var world_pos = board_core.grid_to_world(grid_position)
	
	# For multi-cell weapons, adjust position
	var weapon_width = weapon_data.size.x * board_core.cell_size.x
	
	container.position = Vector2(
		world_pos.x + (weapon_width - 20) / 2,  # Center the health bar
		world_pos.y - 10  # Position above the weapon
	)
	
	# Create health bar background
	var background = ColorRect.new()
	background.size = Vector2(20, 4)  # Small horizontal bar
	background.color = Color(0.2, 0.2, 0.2, 0.8)
	container.add_child(background)
	
	# Create health bar fill
	var fill = ColorRect.new()
	fill.size = Vector2(20, 4)
	fill.color = Color(0, 1, 0, 0.8)  # Green for full health
	container.add_child(fill)
	
	# Get health value from weapon data if available
	var health_value = max_health
	if weapon_data is Dictionary and "health" in weapon_data:
		health_value = weapon_data.health
	
	# Store health bar components
	health_bars[instance_id] = {
		"container": container,
		"background": background,
		"fill": fill,
		"current_health": health_value,
		"max_health": health_value
	}

# Update health bar for a specific weapon
func update_health_bar(instance_id, health):
	# First try with the exact ID
	if instance_id in health_bars:
		_update_health_bar_internal(instance_id, health)
		return true
	
	# If not found, try to find a matching health bar by position
	var parts = instance_id.split("_")
	if parts.size() >= 4:
		var player_id = parts[0]
		var x = parts[2]
		var y = parts[3]
		
		# Try to find any health bar with the same position and player
		for id in health_bars.keys():
			var bar_parts = id.split("_")
			if bar_parts.size() >= 4 and bar_parts[0] == player_id and bar_parts[2] == x and bar_parts[3] == y:
				_update_health_bar_internal(id, health)
				return true
	
	return false

# Internal method to update the health bar's appearance
func _update_health_bar_internal(bar_id, health):
	var bar = health_bars[bar_id]
	
	# Update health value
	bar.current_health = health
	
	# Calculate health percentage
	var health_percent = clamp(health / bar.max_health, 0.0, 1.0)
	
	# Smoothly animate the health bar
	var tween = create_tween()
	tween.tween_property(bar.fill, "size:x", 20 * health_percent, 0.3)
	
	# Set color based on health percentage
	var target_color
	if health_percent > 0.6:
		target_color = Color(0, 1, 0, 0.8)  # Green for high health
	elif health_percent > 0.3:
		target_color = Color(1, 1, 0, 0.8)  # Yellow for medium health
	else:
		target_color = Color(1, 0, 0, 0.8)  # Red for low health
	
	# Animate color change
	tween.parallel().tween_property(bar.fill, "color", target_color, 0.3)
	
	# Make health bar visible
	bar.container.visible = true

# Get health bar for a weapon
func get_health_bar(instance_id):
	if instance_id in health_bars:
		return health_bars[instance_id]
	return null

# Remove a health bar
func remove_health_bar(instance_id):
	if instance_id in health_bars:
		var bar = health_bars[instance_id]
		if is_instance_valid(bar.container):
			bar.container.queue_free()
		health_bars.erase(instance_id)

# Update all weapon sprites and health bars on the board
func update_weapon_sprites():
	# Clear existing sprites
	clear_weapon_sprites()
	
	# Create sprites for all weapons on the board
	for x in range(board_core.grid_size.x):
		for y in range(board_core.grid_size.y):
			var cell = board_core.grid[x][y]
			
			if cell.occupied_by and "weapon_data" in cell.occupied_by:
				var weapon_entry = cell.occupied_by
				
				# Only create sprite for the root cell of the weapon
				if weapon_entry.root_position == cell.position:
					var weapon_id = weapon_entry.weapon_data.id
					var player_id = weapon_entry.player_id
					
					# Create sprite
					create_weapon_sprite(weapon_id, cell.position, player_id)

# Create attack animation
func create_attack_animation(attacker_position, target_position, damage):
	board_core.visualize_attack(attacker_position, target_position, damage)

# Show damage on a weapon
func show_weapon_damage(weapon, damage):
	# Create instance ID to find the health bar
	var weapon_id = weapon.data.id
	var instance_id = str(weapon.player_id) + "_" + str(weapon_id) + "_" + str(weapon.position.x) + "_" + str(weapon.position.y)
	
	# Update health bar
	update_health_bar(instance_id, weapon.health)
	
	# Show damage indicator on the grid
	board_core.show_impact(weapon.position, damage)

# Process floating damage indicators
func process_damage_indicators(delta):
	var i = 0
	while i < damage_indicators.size():
		var indicator = damage_indicators[i]
		
		# Move upward
		indicator.position.y -= 30 * delta
		
		# Fade out
		indicator.modulate.a -= delta * 0.8
		
		# Remove if fully transparent
		if indicator.modulate.a <= 0:
			indicator.queue_free()
			damage_indicators.remove_at(i)
		else:
			i += 1

# Show impact and damage number at a position
func show_impact(position, damage):
	# Check if impact is zero - don't show for misses
	if damage <= 0:
		return
	
	# Convert grid position to world position
	var world_pos = board_core.grid_to_world(position)
	world_pos += board_core.cell_size / 2  # Center in the cell
	
	# Create damage label
	var damage_label = Label.new()
	damage_label.text = str(int(damage))
	
	# Style the label
	damage_label.add_theme_font_override("font", font)
	damage_label.add_theme_font_size_override("font_size", 16)
	
	# Set color based on damage amount
	if damage >= 10:
		damage_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0)) # Red for high damage
	elif damage >= 5:
		damage_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0)) # Orange for medium
	else:
		damage_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0)) # Yellow for low
	
	# Set position
	damage_label.position = world_pos
	damage_label.position.y -= 10  # Start slightly above target
	
	# Center the label
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Add to the scene
	board_core.add_child(damage_label)
	
	# Add to indicators list for animation
	damage_indicators.append(damage_label)
	
	# Optional: Add a slight impact effect (like a flash)
	var impact_sprite = find_weapon_at_position(position)
	if impact_sprite:
		# Flash the sprite
		var original_modulate = impact_sprite.modulate
		impact_sprite.modulate = Color(1.5, 1.5, 1.5, 1)  # Bright flash
		
		# Create a timer to revert the flash
		get_tree().create_timer(0.15).timeout.connect(func():
			if is_instance_valid(impact_sprite):
				impact_sprite.modulate = original_modulate
		)

# Find weapon sprite at a grid position
func find_weapon_at_position(grid_pos):
	for id in weapon_sprites.keys():
		var parts = id.split("_")
		if parts.size() >= 4:
			var x = int(parts[2])
			var y = int(parts[3])
			if x == grid_pos.x and y == grid_pos.y:
				return weapon_sprites[id]
	return null