extends Node

# Player UI elements
var player1_name_label
var player2_name_label
var player1_ingredients_label
var player2_ingredients_label

# Dependencies
var player_manager

# Ingredients animation properties
var player1_ingredients_tween
var player2_ingredients_tween
var last_player1_ingredients = 0
var last_player2_ingredients = 0

# Initialization flag
var is_initialized = false

# Initialize with UI elements
func initialize(p_player1_name_label, p_player2_name_label, 
               p_player1_ingredients_label, p_player2_ingredients_label,
               p_player_manager):
               
	player1_name_label = p_player1_name_label
	player2_name_label = p_player2_name_label
	player1_ingredients_label = p_player1_ingredients_label
	player2_ingredients_label = p_player2_ingredients_label
	player_manager = p_player_manager
	
	if player_manager:
		last_player1_ingredients = player_manager.player1_ingredients
		last_player2_ingredients = player_manager.player2_ingredients
	
	# Update ingredient labels to show "Ingredients" instead of "Score"
	if player1_ingredients_label:
		player1_ingredients_label.text = "Ingredients: 0"
	
	if player2_ingredients_label:
		player2_ingredients_label.text = "Ingredients: 0"
	
	# Update Player 2 as AI
	update_player2_as_ai()
	
	is_initialized = true
	print("Player UI Manager initialized")
	return self

# Update player UI for current player
func update_player_ui(current_player_index):
	if !is_initialized:
		return
		
	# Update player name labels with visual emphasis for current player
	if player1_name_label and player2_name_label:
		if current_player_index == 0:  # Player 1
			player1_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			player2_name_label.remove_theme_color_override("font_color")
		else:  # Player 2 (AI)
			player2_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			player1_name_label.remove_theme_color_override("font_color")

# Update ingredients display with animation
func update_ingredients_display():
	if !is_initialized or !player1_ingredients_label or !player2_ingredients_label or !player_manager:
		return
		
	# Only animate if the ingredients have changed
	if player_manager.player1_ingredients != last_player1_ingredients:
		animate_ingredients_change(player1_ingredients_label, last_player1_ingredients, player_manager.player1_ingredients)
		last_player1_ingredients = player_manager.player1_ingredients
	
	if player_manager.player2_ingredients != last_player2_ingredients:
		animate_ingredients_change(player2_ingredients_label, last_player2_ingredients, player_manager.player2_ingredients)
		last_player2_ingredients = player_manager.player2_ingredients

# Animate ingredients change with a tween
func animate_ingredients_change(label, from_value, to_value):
	# Cancel any existing tween
	if label.has_meta("active_tween") and is_instance_valid(label.get_meta("active_tween")):
		label.get_meta("active_tween").kill()
	
	# Create new tween
	var tween = create_tween()
	label.set_meta("active_tween", tween)
	
	# Store current ingredients for interpolation
	var current_value = from_value
	
	# Highlight label
	var original_color = label.get_theme_color("font_color")
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))  # Gold color for highlight
	
	# Animate the ingredients value over 0.5 seconds
	tween.tween_method(func(value):
		current_value = value
		label.text = "Ingredients: " + str(int(value))
	, float(from_value), float(to_value), 0.5)
	
	# Return to normal color after animation
	tween.tween_callback(func():
		label.remove_theme_color_override("font_color")
	)

# Update resource display - legacy method now updates ingredients
func update_resource_display(player_id, amount):
	if !is_initialized or !player_manager:
		return
	
	# Get the correct ingredients label for the player
	var ingredients_label = player1_ingredients_label if player_id == 0 else player2_ingredients_label
	
	# Update the label if we're displaying for the current player
	if ingredients_label:
		# Update directly without animation for immediate feedback
		ingredients_label.text = "Ingredients: " + str(amount)
		
		# Also update our cached value
		if player_id == 0:
			last_player1_ingredients = amount
		else:
			last_player2_ingredients = amount

# Update Player 2 label to show "AI Opponent"
func update_player2_as_ai():
	if player2_name_label:
		player2_name_label.text = "AI OPPONENT"
		player2_name_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))