extends Node

# Reference to the board core
@onready var board_core

func _ready():
	# Get reference to the board core
	board_core = get_parent()

# Mark cells as occupied by a weapon
func occupy_cells(grid_position, weapon_data, player_id):
	var pos = Vector2(int(grid_position.x), int(grid_position.y))
	
	# Mark cells as occupied
	for x in range(weapon_data.size.x):
		for y in range(weapon_data.size.y):
			var cell_pos = Vector2(pos.x + x, pos.y + y)
			if is_valid_cell(cell_pos):
				board_core.grid[int(cell_pos.x)][int(cell_pos.y)]["occupied_by"] = {
					"weapon_id": weapon_data.id,
					"weapon_data": weapon_data,
					"player_id": player_id,
					"root_position": pos
				}

# Check if a cell is within grid bounds
func is_valid_cell(grid_position):
	var x = int(grid_position.x)
	var y = int(grid_position.y)
	
	return x >= 0 and x < board_core.grid_size.x and y >= 0 and y < board_core.grid_size.y

# Check if a cell is occupied
func is_cell_occupied(grid_position):
	var x = int(grid_position.x)
	var y = int(grid_position.y)
	
	if is_valid_cell(grid_position):
		return board_core.grid[x][y]["occupied_by"] != null
	
	return false

# Check if a cell is land terrain
func is_land_cell(grid_position):
	var x = int(grid_position.x)
	var y = int(grid_position.y)
	
	if is_valid_cell(grid_position):
		return board_core.grid[x][y]["terrain"] == board_core.TERRAIN.LAND
	
	return false

# Check if a cell belongs to a specific player's island
func is_player_territory(grid_position, player_id):
	var x = int(grid_position.x)
	
	if player_id == 0:
		# Player 1's territory (left island)
		return x < board_core.island_size.x
	else:
		# Player 2's territory (right island)
		return x >= (board_core.grid_size.x - board_core.island_size.x)
