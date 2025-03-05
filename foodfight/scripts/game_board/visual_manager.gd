extends Node

# Reference to the board core
@onready var board_core
# Reference to weapon types system
var weapon_types

# Dictionary to store weapon sprites
var weapon_sprites = {}

# Add this function to visual_manager.gd
func initialize(weapon_types_ref):
	weapon_types = weapon_types_ref

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
