extends Node

# Player information
var player1_name = "Player 1"
var player2_name = "Player 2"

# Game settings
var grid_size = Vector2i(16, 8)
var cell_size = 64

# Function to set player names
func set_player_names(p1_name):
	player1_name = p1_name
	print("Global player names set - Player 1: ", player1_name)
