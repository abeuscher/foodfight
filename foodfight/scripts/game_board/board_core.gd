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

# Reference to cell manager and visual manager
@onready var cell_manager
@onready var visual_manager

func _ready():
	# Wait for child nodes to be ready
	await get_tree().process_frame
	
	# Initialize the grid with default values
	initialize_grid()
	# Get reference to WeaponTypes
	var main = get_node("/root/Main")
	if main and main.has_node("WeaponTypes"):
		var weapon_types_ref = main.get_node("WeaponTypes")
	
		# Initialize VisualManager with the WeaponTypes reference
		var visual_manager = get_node("VisualManager")
		if visual_manager:
			visual_manager.initialize(weapon_types_ref)
	# Draw the grid
	queue_redraw()

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
	
	# If visual manager exists, initialize it
	if visual_manager:
		visual_manager.clear_weapon_sprites()

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
