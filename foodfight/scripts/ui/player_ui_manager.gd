extends BaseUIListener

# Player UI elements
var player1_name_label
var player2_name_label
var player1_score_label
var player2_score_label

# Dependencies
var player_manager

# Initialization flag
var is_initialized = false

# Recursion guards
var _active_method_calls = {}

# Initialize with UI elements
func initialize(p1_name, p2_name, p1_score, p2_score, p_player_manager):
	player1_name_label = p1_name
	player2_name_label = p2_name
	player1_score_label = p1_score
	player2_score_label = p2_score
	player_manager = p_player_manager
	
	is_initialized = true
	print("Player UI Manager initialized")
	
	# Initialize labels with starting values
	if is_initialized:
		update_player_ui(0) # Default to player 1
	
	return self

# Check for recursive calls
func _check_recursion(method_name: String) -> bool:
	if _active_method_calls.has(method_name) and _active_method_calls[method_name]:
		push_warning("PlayerUIManager: Breaking recursive call to " + method_name)
		return true
	return false

# Event handlers
func on_player_changed(event_data):
	if _check_recursion("on_player_changed"):
		return
		
	_active_method_calls["on_player_changed"] = true
	update_player_ui(event_data.player_index)
	_active_method_calls["on_player_changed"] = false

func on_ingredients_updated(event_data):
	if _check_recursion("on_ingredients_updated"):
		return
		
	_active_method_calls["on_ingredients_updated"] = true
	update_ingredients_display(event_data.player_id, event_data.ingredients)
	_active_method_calls["on_ingredients_updated"] = false

# Update player UI elements
func update_player_ui(player_index):
	if _check_recursion("update_player_ui"):
		return
		
	_active_method_calls["update_player_ui"] = true
	
	if !is_initialized:
		print("PlayerUIManager: Not initialized, can't update player UI")
		_active_method_calls["update_player_ui"] = false
		return
		
	print("PlayerUIManager: Updating UI for player " + str(player_index + 1))
	
	# Update player name labels
	if player1_name_label and player2_name_label and player_manager:
		player1_name_label.text = player_manager.get_player_name(0)
		player2_name_label.text = player_manager.get_player_name(1)
		
		# Highlight the current player
		var inactive_color = Color(0.7, 0.7, 0.7)
		var active_color = Color(1.0, 1.0, 0.0)
		
		if player_index == 0:
			player1_name_label.add_theme_color_override("font_color", active_color)
			player2_name_label.add_theme_color_override("font_color", inactive_color)
		else:
			player1_name_label.add_theme_color_override("font_color", inactive_color)
			player2_name_label.add_theme_color_override("font_color", active_color)
	
	# Update ingredients display for both players
	if player_manager:
		update_ingredients_display(0, player_manager.get_player_ingredients(0))
		update_ingredients_display(1, player_manager.get_player_ingredients(1))
	
	_active_method_calls["update_player_ui"] = false

# Update ingredients display for a specific player
func update_ingredients_display(player_id, ingredients):
	if _check_recursion("update_ingredients_display"):
		return
		
	_active_method_calls["update_ingredients_display"] = true
	
	if !is_initialized:
		_active_method_calls["update_ingredients_display"] = false
		return
		
	print("PlayerUIManager: Updating ingredients for player " + str(player_id + 1) + ": " + str(ingredients))
	
	# Update score labels based on player ID
	if player_id == 0 and player1_score_label:
		player1_score_label.text = str(ingredients) + " Ingredients"
	elif player_id == 1 and player2_score_label:
		player2_score_label.text = str(ingredients) + " Ingredients"
	
	_active_method_calls["update_ingredients_display"] = false

# Explicitly update the ingredient display for both players
func refresh_ingredients_display():
	if !player_manager:
		return
		
	update_ingredients_display(0, player_manager.get_player_ingredients(0))
	update_ingredients_display(1, player_manager.get_player_ingredients(1))