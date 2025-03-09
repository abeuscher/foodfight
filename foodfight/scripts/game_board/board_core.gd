extends Node2D

# Grid properties
var grid_size = Vector2(32, 20)  # Increased but not too much
var cell_size = Vector2(24, 24)  # Smaller cells to fit on screen
var grid = []  # Will store our grid data

# Island properties
var island_size = Vector2(12, 12)  # Islands
var island_margin = Vector2(2, 2)  # Margin around islands (water border)
var canal_width = 6  # Canal width for separation

# Terrain types
enum TERRAIN {LAND, WATER}

# Visual state types - update to include hover states
enum VISUAL_STATE {NORMAL, HOVER_VALID, HOVER_INVALID, VALID_TARGET, INVALID_TARGET, SELECTED}

# Reference to cell manager and visual manager
@onready var cell_manager
@onready var visual_manager

# Initialization flag
var is_initialized = false

func _ready():
	# Wait for child nodes to be ready
	await get_tree().process_frame
	
	# Get references to child nodes
	if has_node("VisualManager"):
		visual_manager = get_node("VisualManager")
	else:
		print("Warning: VisualManager not found in board_core")
	
	# Initialize the grid with default values
	initialize_grid()
	
	# Get reference to WeaponTypes
	var main = get_node("/root/Main")
	if main and main.has_node("WeaponTypes"):
		var weapon_types_ref = main.get_node("WeaponTypes")
	
		# Initialize VisualManager with the WeaponTypes reference
		if visual_manager:
			visual_manager.initialize(weapon_types_ref)
	
	# Position the grid to be centered in the view
	position = Vector2(50, 80)  # Adjust based on your UI layout
	
	# Grid is initialized
	is_initialized = true
	
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
			if x >= island_margin.x and x < island_margin.x + island_size.x and \
			   y >= island_margin.y and y < island_margin.y + island_size.y:
				terrain_type = TERRAIN.LAND
			
			# Right island (Player 2)
			if x >= grid_size.x - island_size.x - island_margin.x and \
			   x < grid_size.x - island_margin.x and \
			   y >= island_margin.y and y < island_margin.y + island_size.y:
				terrain_type = TERRAIN.LAND
			
			# Add cell data to the grid
			column.append({
				"position": Vector2(x, y),
				"terrain": terrain_type,
				"occupied_by": null,  # Will store weapon or defense later
				"visual_state": VISUAL_STATE.NORMAL  # Add visual state tracking
			})
		grid.append(column)
	
	print("Grid initialized with size: ", grid_size)
	
	# If visual manager exists, initialize it
	if visual_manager:
		visual_manager.clear_weapon_sprites()

func _draw():
	# Draw the grid for visualization
	if grid.size() == 0:
		return
		
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
			
			# Draw visual state overlays
			match cell.get("visual_state", VISUAL_STATE.NORMAL):
				VISUAL_STATE.HOVER_VALID:
					# Green hover effect for valid targets
					draw_rect(rect, Color(0.0, 1.0, 0.3, 0.3))
					draw_rect(rect, Color(0.0, 1.0, 0.3, 0.8), false, 2)
				VISUAL_STATE.HOVER_INVALID:
					# Red hover effect for invalid targets
					draw_rect(rect, Color(1.0, 0.3, 0.3, 0.3))
					draw_rect(rect, Color(1.0, 0.3, 0.3, 0.8), false, 2)
				VISUAL_STATE.VALID_TARGET:
					# Subtle highlight for valid target cells
					draw_rect(rect, Color(0.0, 1.0, 0.3, 0.15))
				VISUAL_STATE.INVALID_TARGET:
					# Red highlight for invalid targets
					draw_rect(rect, Color(1, 0, 0, 0.4))
					draw_rect(rect, Color(1, 0, 0, 0.8), false, 2)
				VISUAL_STATE.SELECTED:
					# Yellow highlight for selected cells
					draw_rect(rect, Color(1, 1, 0, 0.4))
					draw_rect(rect, Color(1, 1, 0, 0.8), false, 2)
			
			# Draw grid lines
			draw_rect(rect, Color.BLACK, false)

# Function to get cell at world position
func get_cell_at_position(world_position):
	if grid.size() == 0:
		return null
		
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

# Add methods to set visual states
func set_cell_visual_state(grid_position, state):
	var x = int(grid_position.x)
	var y = int(grid_position.y)
	
	if x >= 0 and x < grid_size.x and y >= 0 and y < grid_size.y:
		grid[x][y]["visual_state"] = state
		queue_redraw()  # Request redraw to update visuals
		return true
	return false

# Utility method to reset all cells to normal state
func reset_all_visual_states():
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			grid[x][y]["visual_state"] = VISUAL_STATE.NORMAL
	queue_redraw()

# Add methods for common visual operations
func set_hover_cell(grid_position, is_valid=true):
	reset_all_visual_states()
	if is_valid:
		set_cell_visual_state(grid_position, VISUAL_STATE.HOVER_VALID)
	else:
		set_cell_visual_state(grid_position, VISUAL_STATE.HOVER_INVALID)

func highlight_valid_targets(valid_positions):
	for pos in valid_positions:
		set_cell_visual_state(pos, VISUAL_STATE.VALID_TARGET)

func highlight_cell_as_target(grid_position, is_valid):
	var state = VISUAL_STATE.VALID_TARGET if is_valid else VISUAL_STATE.INVALID_TARGET
	set_cell_visual_state(grid_position, state)

# Get cell center in world coordinates
func get_cell_center_world(grid_position):
	var top_left = grid_to_world(grid_position)
	return top_left + cell_size / 2

# Add a function to clear only hover effects
func reset_hover_effects():
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			# Only clear hover states, preserve other visual states
			if grid[x][y].get("visual_state", VISUAL_STATE.NORMAL) == VISUAL_STATE.HOVER_VALID or \
			   grid[x][y].get("visual_state", VISUAL_STATE.NORMAL) == VISUAL_STATE.HOVER_INVALID:
				grid[x][y]["visual_state"] = VISUAL_STATE.NORMAL
	queue_redraw()