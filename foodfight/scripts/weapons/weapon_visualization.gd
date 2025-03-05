extends Node

# Reference to the game board
@onready var game_board
@onready var visual_manager

# Placement preview
var placement_preview: ColorRect

func _ready():
	# Create placement preview rectangle
	placement_preview = ColorRect.new()
	placement_preview.color = Color(0, 1, 0, 0.3)  # Semi-transparent green
	placement_preview.visible = false
	add_child(placement_preview)

func initialize(board, visual_mgr):
	game_board = board
	visual_manager = visual_mgr
	
	# Add placement preview as child of the board
	if placement_preview.get_parent() == self:
		remove_child(placement_preview)
		game_board.add_child(placement_preview)

# Update preview size based on weapon data
func update_preview_size(weapon_data):
	if weapon_data != null:
		placement_preview.size = Vector2(
			weapon_data.size.x * game_board.cell_size.x,
			weapon_data.size.y * game_board.cell_size.y
		)

# Update preview position and validity display
func update_preview_position(grid_pos, is_valid):
	# Set preview position based on grid position - align to top-left of grid cell
	placement_preview.position = Vector2(
		grid_pos.x * game_board.cell_size.x,
		grid_pos.y * game_board.cell_size.y
	)
	
	# Update preview color based on validity
	if is_valid:
		placement_preview.color = Color(0, 1, 0, 0.3)  # Semi-transparent green
	else:
		placement_preview.color = Color(1, 0, 0, 0.3)  # Semi-transparent red
	
	placement_preview.visible = true

# Hide the preview
func hide_preview():
	placement_preview.visible = false

# Create a weapon sprite on the board
func place_weapon_visual(weapon_data, grid_position, player_id):
	return visual_manager.create_weapon_sprite(weapon_data.id, grid_position, player_id)