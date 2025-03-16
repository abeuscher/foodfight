extends Node

# Player types
enum PlayerType {HUMAN, AI}

# Player information
var player1_name = ""
var player2_name = ""
var current_player = 1  # 1 or 2 for display purposes
var current_player_index = 0  # 0 or 1 for array indexing
var player_types = [PlayerType.HUMAN, PlayerType.AI]  # Default: player 1 is human, player 2 is AI

# Player ingredients (consolidated from separate score and resources)
var player1_ingredients = 25  # Starting ingredients
var player2_ingredients = 25  # Starting ingredients

# Game result
var winning_player = -1  # -1 = no winner yet, 0 = player 1, 1 = player 2

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
			
		if GameData.has_method("get_player2_name") and player_types[1] == PlayerType.HUMAN:
			player2_name = GameData.get_player2_name()
		else:
			player2_name = "AI Opponent"
	else:
		# Default names if GameData isn't available
		player1_name = "Player 1"
		player2_name = "AI Opponent"
	
	# Initialize with player 1 as current
	current_player = 1
	current_player_index = 0
	
	print("Player manager initialized with players: ", player1_name, " and ", player2_name)

# Switch to the next player
func next_player():
	current_player = 2 if current_player == 1 else 1
	current_player_index = 1 if current_player == 2 else 0
	print("Current player: " + get_current_player_name())

# Reset to player 1
func reset_current_player():
	current_player = 1
	current_player_index = 0

# Get the name of the current player
func get_current_player_name():
	return player1_name if current_player == 1 else player2_name

# Get player name by index
func get_player_name(player_idx):
	return player1_name if player_idx == 0 else player2_name

# Set player type
func set_player_type(player_idx, type):
	player_types[player_idx] = type
	# If setting player 2 to AI, update the name
	if player_idx == 1 and type == PlayerType.AI:
		player2_name = "AI Opponent"

# Check if player is AI
func is_ai_player(player_idx):
	return player_types[player_idx] == PlayerType.AI

# Check if current player is AI
func is_current_player_ai():
	return is_ai_player(current_player_index)

# Set player name
func set_player_name(player_idx, name):
	if player_idx == 0:
		player1_name = name
	else:
		player2_name = name

# Add ingredients to a player
func add_ingredients(player_id, amount):
	if player_id == 0:
		player1_ingredients += amount
		print("Added ", amount, " ingredients to Player 1. New total: ", player1_ingredients)
	else:
		player2_ingredients += amount
		print("Added ", amount, " ingredients to Player 2. New total: ", player2_ingredients)

# Get player ingredients
func get_player_ingredients(player_id):
	return player1_ingredients if player_id == 0 else player2_ingredients

# Legacy methods mapped to new ingredients system
func add_points(player_id, points):
	add_ingredients(player_id, points)

func add_resources(player_id, resources):
	# No separate action needed - already handled by add_ingredients
	pass

func get_player_resources(player_id):
	return get_player_ingredients(player_id)

# Set the winning player
func set_winner(player_id):
	winning_player = player_id
	var winner_name = get_player_name(player_id)
	print("Game over! ", winner_name, " wins with ", 
		player1_ingredients if player_id == 0 else player2_ingredients, " ingredients")

# Reset the game state
func reset_game():
	# Reset ingredients
	player1_ingredients = 25  # Starting ingredients
	player2_ingredients = 25  # Starting ingredients
	
	# Reset player turn
	reset_current_player()
	
	# Reset game result
	winning_player = -1
	
	print("Game reset. Starting fresh game between ", player1_name, " and ", player2_name)