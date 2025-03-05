extends Node2D

# Grid properties
var grid_size = Vector2(22, 12)  # 22 cells wide, 12 cells tall
var cell_size = Vector2(64, 64)  # Each cell is 64x64 pixels
var grid = []  # Will store our grid data

# Island properties
var island_size = Vector2(10, 10)  # Each island is 10x10
var canal_width = 2  # Canal is 2 cells wide

# Terrain types
enum TERRAIN {LAND, WATER}

# Dictionary to store weapon sprites
var weapon_sprites = {}

# Reference to weapon types
var weapon_types

func _ready():
	# Initialize the grid with default values
	initialize_grid()
	# Draw the grid
	queue_redraw()
	
	# Get reference to weapon types
	weapon_types = get_node("../WeaponTypes")

func initialize_grid():
	# Reset the grid
	grid = []
	
	# Create a 2D array to represent our grid
	for x in range(grid_size.x):
		var column = []
		for y in range(grid_size.y):
			# Default terrain is water
			var terrain_type = TERRAIN.WATER
			
			# Left island (Player 1)
			if x < island_size.x and y < island_size.y:
				terrain_type = TERRAIN.LAND
			
			# Right island (Player 2)
			if x >= grid_size.x - island_size.x and y < island_size.y:
				terrain_type = TERRAIN.LAND
			
			# Add cell data to the grid
			column.append({
				"position": Vector2(x, y),
				"terrain": terrain_type,
				"occupied_by": null,  # Will store weapon or defense later
			})
		grid.append(column)
	
	print("Grid initialized with size: ", grid_size)
	
	# Clear any existing weapon sprites
	for sprite in weapon_sprites.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	weapon_sprites.clear()

func _draw():
	# Draw the grid for visualization
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell = grid[x][y]
			var rect = Rect2(
				x * cell_size.x, 
				y * cell_size.y, 
				cell_size.x, 
				cell_size.y
			)
			
			# Draw cell with color based on terrain type
			var color = Color.FOREST_GREEN if cell["terrain"] == TERRAIN.LAND else Color.DODGER_BLUE
			draw_rect(rect, color)
			
			# Draw grid lines
			draw_rect(rect, Color.BLACK, false)

# Function to add a weapon to the grid
func place_weapon(player_id, weapon_data, grid_position):
	var pos = Vector2(int(grid_position.x), int(grid_position.y))
	
	# Mark cells as occupied
	for x in range(weapon_data.size.x):
		for y in range(weapon_data.size.y):
			var cell_pos = Vector2(pos.x + x, pos.y + y)
			if cell_pos.x >= 0 and cell_pos.x < grid_size.x and cell_pos.y >= 0 and cell_pos.y < grid_size.y:
				grid[int(cell_pos.x)][int(cell_pos.y)]["occupied_by"] = {
					"weapon_id": weapon_data.id,
					"player_id": player_id
				}
	
	# Create visual representation of the weapon
	create_weapon_sprite(weapon_data.id, pos, player_id)
	
	# Force redraw to show occupied cells
	queue_redraw()

# Create a visual sprite for the weapon
func create_weapon_sprite(weapon_id, grid_position, player_id):
	# Create a unique ID for this weapon instance
	var instance_id = str(player_id) + "_" + weapon_id + "_" + str(grid_position.x) + "_" + str(grid_position.y)
	
	# Create a new sprite for the weapon
	var sprite = Sprite2D.new()
	add_child(sprite)
	
	# Get weapon data
	var weapon = weapon_types.get_weapon_by_id(weapon_id)
	
	# Set sprite position - top-left corner of the grid cell
	var world_pos = Vector2(
		grid_position.x * cell_size.x,
		grid_position.y * cell_size.y
	)
	
	# For multi-cell weapons, we want to place the sprite to cover all cells
	var texture_size = Vector2(weapon.size.x * cell_size.x, weapon.size.y * cell_size.y)
	
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

# Function to get cell at world position
func get_cell_at_position(world_position):
	# Adjust position for grid offset
	var adjusted_position = world_position - global_position
	
	var x = int(adjusted_position.x / cell_size.x)
	var y = int(adjusted_position.y / cell_size.y)
	
	# Check if within bounds
	if x >= 0 and x < grid_size.x and y >= 0 and y < grid_size.y:
		return grid[x][y]
	return null

# Function to convert grid coordinates to world position
func grid_to_world(grid_position):
	return Vector2(
		grid_position.x * cell_size.x,
		grid_position.y * cell_size.y
	)

# Get board dimensions in pixels
func get_board_size_pixels():
	return Vector2(grid_size.x * cell_size.x, grid_size.y * cell_size.y)

# Check if a cell is occupied
func is_cell_occupied(grid_position):
	var x = int(grid_position.x)
	var y = int(grid_position.y)
	
	if x >= 0 and x < grid_size.x and y >= 0 and y < grid_size.y:
		return grid[x][y]["occupied_by"] != null
	
	return false
