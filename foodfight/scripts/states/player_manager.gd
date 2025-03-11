extends Node

# Player information
var player1_name = ""
var player2_name = ""
var current_player = 1  # 1 or 2 for display purposes
var current_player_index = 0  # 0 or 1 for array indexing

# Player scores
var player1_score = 0
var player2_score = 0

# Game result
var winning_player = -1  # -1 = no winner yet, 0 = player 1, 1 = player 2

# Initialization flag
var is_initialized = false

func _ready():
	# Wait for game data
	await get_tree().process_frame
	
	# Get player names from GameData singleton
	if Engine.has_singleton("GameData"):
		var GameData = Engine.get_singleton("GameData")
		if GameData.has_method("get_player1_name"):
			player1_name = GameData.get_player1_name()
		else:
			player1_name = "Player 1"
			
		if GameData.has_method("get_player2_name"):
			player2_name = GameData.get_player2_name()
		else:
			player2_name = "Player 2"
	else:
		# Default names if GameData isn't available
		player1_name = "Player 1"
		player2_name = "Player 2"
	
	# Initialize with player 1 as current
	current_player = 1
	current_player_index = 0
	
	is_initialized = true
	print("Player manager initialized with players: ", player1_name, " and ", player2_name)

# Switch to the next player
func next_player():
	if !is_initialized:
		return
		
	current_player = 2 if current_player == 1 else 1
	current_player_index = 1 if current_player == 2 else 0
	print("Current player: " + get_current_player_name())

# Reset to player 1
func reset_current_player():
	if !is_initialized:
		return
		
	current_player = 1
	current_player_index = 0

# Get the name of the current player
func get_current_player_name():
	if !is_initialized:
		return "Player"
		
	return player1_name if current_player == 1 else player2_name

# Get player name by index
func get_player_name(player_idx):
	if !is_initialized:
		return "Player " + str(player_idx + 1)
		
	return player1_name if player_idx == 0 else player2_name

# Update player score
func update_score(player, points):
	if !is_initialized:
		return
		
	if player == 1:
		player1_score += points
	else:
		player2_score += points

# Add points to a player's score
func add_points(player_id, points):
	if !is_initialized:
		return
	
	if player_id == 0:
		player1_score += points
		print("Added ", points, " points to Player 1. New score: ", player1_score)
	else:
		player2_score += points
		print("Added ", points, " points to Player 2. New score: ", player2_score)

# Set the winning player
func set_winner(player_id):
	if !is_initialized:
		return
	
	winning_player = player_id
	var winner_name = get_player_name(player_id)
	print("Game over! ", winner_name, " wins with a score of ", 
		player1_score if player_id == 0 else player2_score)

# Reset the game state
func reset_game():
	if !is_initialized:
		return
	
	# Reset scores
	player1_score = 0
	player2_score = 0
	
	# Reset player turn
	reset_current_player()
	
	# Reset game result
	winning_player = -1
	
	print("Game reset. Starting fresh game between ", player1_name, " and ", player2_name)