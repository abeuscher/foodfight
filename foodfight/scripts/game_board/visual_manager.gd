extends Node

# Reference to the board core
@onready var board_core
# Reference to weapon types system
var weapon_types

# Dictionaries to store weapon visuals
var weapon_sprites = {}
var health_bars = {}
var max_health = 10.0  # Default max health

# Add this function to visual_manager.gd
func initialize(weapon_types_ref):
	weapon_types = weapon_types_ref
	# Get reference to the board core
	board_core = get_parent()
	print("VisualManager initialized with weapon types reference")

# And update the _ready function
func _ready():
	# Get reference to the board core
	board_core = get_parent()
	
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
	
	# Debug info
	print("Health bar created for " + instance_id + " with max health: " + str(health_value))

# Update health bar for a specific weapon
func update_health_bar(instance_id, health):
	if instance_id in health_bars:
		var bar = health_bars[instance_id]
		
		# Debug info
		print("Updating health bar for " + instance_id + " to " + str(health) + "/" + str(bar.max_health))
		
		# Update health value
		bar.current_health = health
		
		# Calculate health percentage
		var health_percent = clamp(health / bar.max_health, 0.0, 1.0)
		
		# Update health bar fill
		bar.fill.size.x = 20 * health_percent
		
		# Set color based on health percentage
		if health_percent > 0.6:
			bar.fill.color = Color(0, 1, 0, 0.8)  # Green for high health
		elif health_percent > 0.3:
			bar.fill.color = Color(1, 1, 0, 0.8)  # Yellow for medium health
		else:
			bar.fill.color = Color(1, 0, 0, 0.8)  # Red for low health
		
		# Make health bar visible
		bar.container.visible = true
	else:
		print("Warning: Health bar not found for ID: " + instance_id)

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
	# This function is called after changes to weapons on the board
	if !board_core or !board_core.is_initialized:
		return
	
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
	# Add debug info
	print("Creating attack animation from " + str(attacker_position) + " to " + str(target_position) + " with damage " + str(damage))
	board_core.visualize_attack(attacker_position, target_position, damage)

# Show damage on a weapon
func show_weapon_damage(weapon, damage):
	if !weapon or !("data" in weapon) or !("position" in weapon) or !("player_id" in weapon):
		print("Warning: Invalid weapon object provided to show_weapon_damage")
		return
	
	# Add debug info
	print("Showing damage on weapon at " + str(weapon.position) + ": " + str(damage) + " damage")
	
	# Create instance ID to find the health bar
	var weapon_id = "unknown"
	
	# Handle different ways to get the weapon ID
	if weapon.data is Object:
		if weapon.data.has_method("get_id"):
			weapon_id = weapon.data.get_id()
		elif "id" in weapon.data:
			weapon_id = weapon.data.id
	elif weapon.data is Dictionary and "id" in weapon.data:
		weapon_id = weapon.data.id
	
	var instance_id = str(weapon.player_id) + "_" + str(weapon_id) + "_" + str(weapon.position.x) + "_" + str(weapon.position.y)
	
	print("Updating health bar with ID: " + instance_id)
	
	# Update health bar
	update_health_bar(instance_id, weapon.health)
	
	# Show damage indicator on the grid
	board_core.show_impact(weapon.position, damage)