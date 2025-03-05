# weapon_placement.gd
extends Node

# Signals
signal weapon_selected(weapon_data)
signal weapon_placed(player_id, weapon_data, position)
signal placement_canceled()
signal resource_updated(player_id, amount)

# References
var game_board: Node2D
var weapon_types: Node
var game_data: Node  # Reference to game data singleton

# State variables
var current_player_id: int = 0
var selected_weapon: Object = null  # Currently selected weapon (WeaponData)
var placing_weapon: bool = false
var placement_valid: bool = false
var player_resources: Dictionary = {
	0: 10,  # Player 1 starting resources
	1: 10   # Player 2 starting resources
}

# Visual elements
var placement_preview: ColorRect

func _ready():
	# Create placement preview rectangle
	placement_preview = ColorRect.new()
	placement_preview.color = Color(0, 1, 0, 0.3)  # Semi-transparent green
	placement_preview.visible = false
	add_child(placement_preview)
	
	# Get references
	game_data = get_node("/root/GameData")

func initialize(board: Node2D, types: Node):
	# Set references
	game_board = board
	weapon_types = types
	
	# Add placement preview as child of the board
	if placement_preview.get_parent() == self:
		remove_child(placement_preview)
		game_board.add_child(placement_preview)

func start_placement_phase(player_id: int):
	current_player_id = player_id
	cancel_placement()  # Reset any existing placement
	
	print("Starting placement phase for Player ", player_id + 1)
	print("Available resources: ", player_resources[player_id])
	
	# Emit initial resource signal
	emit_signal("resource_updated", player_id, player_resources[player_id])

func select_weapon(weapon_id: String) -> bool:
	# Get weapon data
	var weapon = weapon_types.get_weapon_by_id(weapon_id)
	
	if weapon == null:
		print("Weapon not found: ", weapon_id)
		return false
	
	# Check if player has enough resources
	if player_resources[current_player_id] < weapon.cost:
		print("Not enough resources to place this weapon")
		return false
	
	# Set as selected weapon
	selected_weapon = weapon
	placing_weapon = true
	placement_valid = false
	
	# Update preview size based on weapon size
	update_preview_size()
	
	print("Selected weapon: ", weapon.name)
	emit_signal("weapon_selected", weapon)
	
	return true

func update_preview_size():
	if selected_weapon != null:
		placement_preview.size = Vector2(
			selected_weapon.size.x * game_board.cell_size.x,
			selected_weapon.size.y * game_board.cell_size.y
		)

func update_preview_position(grid_pos: Vector2):
	if !placing_weapon or selected_weapon == null:
		placement_preview.visible = false
		return
	
	# Set preview position based on grid position - align to top-left of grid cell
	placement_preview.position = Vector2(
		grid_pos.x * game_board.cell_size.x,
		grid_pos.y * game_board.cell_size.y
	)
	
	# Check if placement is valid
	placement_valid = is_placement_valid(grid_pos)
	
	# Update preview color based on validity
	if placement_valid:
		placement_preview.color = Color(0, 1, 0, 0.3)  # Semi-transparent green
	else:
		placement_preview.color = Color(1, 0, 0, 0.3)  # Semi-transparent red
	
	placement_preview.visible = true

func is_placement_valid(grid_pos: Vector2) -> bool:
	if selected_weapon == null:
		return false
	
	# Check if all cells are valid for placement
	for x in range(selected_weapon.size.x):
		for y in range(selected_weapon.size.y):
			var check_pos = Vector2(grid_pos.x + x, grid_pos.y + y)
			
			# Check if within grid bounds
			if check_pos.x < 0 or check_pos.x >= game_board.grid_size.x or \
			   check_pos.y < 0 or check_pos.y >= game_board.grid_size.y:
				return false
			
			# Get the cell data
			var cell = game_board.grid[int(check_pos.x)][int(check_pos.y)]
			
			# Check if it's land and belongs to the current player
			if cell["terrain"] != game_board.TERRAIN.LAND:
				return false
			
			# Check if it's on the correct island (Player 1: left, Player 2: right)
			if current_player_id == 0 and check_pos.x >= game_board.island_size.x:
				return false
			if current_player_id == 1 and check_pos.x < (game_board.grid_size.x - game_board.island_size.x):
				return false
			
			# Check if already occupied
			if cell["occupied_by"] != null:
				return false
	
	return true

func place_weapon(grid_pos: Vector2) -> bool:
	if !placing_weapon or selected_weapon == null:
		return false
	
	if !is_placement_valid(grid_pos):
		return false
	
	# Deduct cost
	player_resources[current_player_id] -= selected_weapon.cost
	
	# Place the weapon on the game board
	game_board.place_weapon(current_player_id, selected_weapon, grid_pos)
	
	# Emit signals
	emit_signal("weapon_placed", current_player_id, selected_weapon, grid_pos)
	emit_signal("resource_updated", current_player_id, player_resources[current_player_id])
	
	print("Placed ", selected_weapon.name, " at ", grid_pos)
	print("Remaining resources: ", player_resources[current_player_id])
	
	# Reset placement state
	cancel_placement()
	
	return true

func cancel_placement():
	placing_weapon = false
	selected_weapon = null
	placement_valid = false
	placement_preview.visible = false
	
	emit_signal("placement_canceled")

func process_input(event):
	# Handle mouse movement for placement preview
	if event is InputEventMouseMotion and placing_weapon:
		# Convert global mouse position to local position relative to game board
		var local_pos = event.position - game_board.global_position
		
		# Convert to grid position
		var grid_pos = Vector2(
			int(local_pos.x / game_board.cell_size.x),
			int(local_pos.y / game_board.cell_size.y)
		)
		
		update_preview_position(grid_pos)
	
	# Handle mouse click for placement
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and placing_weapon:
		# Convert global mouse position to local position relative to game board
		var local_pos = event.position - game_board.global_position
		
		# Convert to grid position
		var grid_pos = Vector2(
			int(local_pos.x / game_board.cell_size.x),
			int(local_pos.y / game_board.cell_size.y)
		)
		
		place_weapon(grid_pos)

func get_player_resources(player_id: int) -> int:
	return player_resources[player_id]

func end_placement_phase():
	cancel_placement()
	print("Ended placement phase")