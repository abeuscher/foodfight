extends BaseUIListener

# UI elements
var turn_label
var phase_label
var title_screen
var player_manager

# Initialization flag
var is_initialized = false
var actual_title_screen = null # Direct reference to actual title screen scene

# Signal for title screen animation completion
signal title_screen_completed

# Recursion guards
var _updating_phase_ui = false
var _showing_phase_title = false
var _last_state = -1
var _last_player = -1
var _active_method_calls = {}

# Local copy of GameState enum for safety
enum GameState {
	UNINITIALIZED = 0,
	START_SCREEN = 1,
	BASE_PLACEMENT = 2,
	WEAPON_PLACEMENT = 3,
	TARGETING = 4,
	ATTACK_RESOLUTION = 5,
	GAME_OVER = 6
}

func initialize(p_turn_label, p_phase_label, p_title_screen, p_player_manager):
	turn_label = p_turn_label
	phase_label = p_phase_label
	title_screen = p_title_screen
	player_manager = p_player_manager
	
	# Store direct reference to actual TitleScreen if it exists
	if p_title_screen and p_title_screen.has_method("show_title"):
		actual_title_screen = p_title_screen
		print("PhaseUIManager: Successfully connected to title screen")
	else:
		# Try to find title screen in the scene
		var main = get_tree().current_scene
		if main:
			var title_screen_node = main.get_node_or_null("UI/TitleScreen")
			if title_screen_node and title_screen_node.has_method("show_title"):
				actual_title_screen = title_screen_node
				print("PhaseUIManager: Found title screen in scene tree")
	
	is_initialized = true
	print("PhaseUIManager initialized")
	return self

# Handle the SHOW_PHASE_TITLE event
func on_show_phase_title(event_data = null):
	if !is_initialized:
		print("PhaseUIManager: Cannot show title - not initialized")
		return
		
	print("PhaseUIManager: Received SHOW_PHASE_TITLE event with phase name: " + event_data.phase_name)
	
	# Show the title screen with the phase name
	show_title(event_data.phase_name)

# Show the phase title
func show_title(title_text):
	print("PhaseUIManager: Attempting to show title: " + title_text)
	
	if actual_title_screen:
		actual_title_screen.show_title(title_text)
		print("PhaseUIManager: Title screen showing: " + title_text)
	else:
		print("PhaseUIManager ERROR: No title screen available to show: " + title_text)

# Update game phase text
func update_game_phase(phase_text):
	if _check_recursion("update_game_phase"):
		return
		
	_active_method_calls["update_game_phase"] = true
	
	if !is_initialized:
		_active_method_calls["update_game_phase"] = false
		return
		
	if phase_label:
		phase_label.text = phase_text
		
		# Emit event so others can respond to phase change
		emit_event("PHASE_DISPLAY_UPDATED", {"phase_text": phase_text})
		
	# Also show phase title - explicitly call show_title here
	show_title(phase_text)
	
	_active_method_calls["update_game_phase"] = false

# Update current turn text
func update_current_turn(player_name):
	if _check_recursion("update_current_turn"):
		return
		
	_active_method_calls["update_current_turn"] = true
	
	if !is_initialized:
		_active_method_calls["update_current_turn"] = false
		return
		
	if turn_label:
		turn_label.text = player_name + "'s Turn"
	
	_active_method_calls["update_current_turn"] = false

# Show game over screen
func show_game_over(winning_player):
	if _check_recursion("show_game_over"):
		return
		
	_active_method_calls["show_game_over"] = true
	
	if !is_initialized:
		_active_method_calls["show_game_over"] = false
		return
		
	# Show title screen with Game Over text
	if actual_title_screen:
		var winner_name = player_manager.get_player_name(winning_player)
		actual_title_screen.show_title("Game Over\n" + winner_name + " Wins!")
	
	# Update labels
	if phase_label:
		phase_label.text = "Game Over"
	if turn_label and player_manager:
		turn_label.text = player_manager.get_player_name(winning_player) + " Wins!"
	
	# Create game over message if not already present
	var ui_container = get_tree().get_root().get_node_or_null("Main/UI")
	if ui_container:
		var existing_message = ui_container.get_node_or_null("GameOverMessage")
		if existing_message:
			existing_message.queue_free()
			
		# Create game over message
		var game_over_message = Label.new()
		game_over_message.name = "GameOverMessage"
		game_over_message.text = "Someone wins!"
		game_over_message.add_theme_color_override("font_color", Color(1, 0.8, 0))
		game_over_message.add_theme_font_size_override("font_size", 36)
		game_over_message.position = Vector2(400, 300)
		
		# Add to UI
		ui_container.add_child(game_over_message)
	
	_active_method_calls["show_game_over"] = false

# Subscribe to events
func _subscribe_to_events():
	super._subscribe_to_events()
	
	# Explicitly subscribe to the SHOW_PHASE_TITLE event
	print("PhaseUIManager: Explicitly subscribing to SHOW_PHASE_TITLE event")
	add_event_subscription("SHOW_PHASE_TITLE", "on_show_phase_title")

# Event handlers - now focused only on UI updates, not game state management
func on_phase_changed(event_data):
	if _check_recursion("on_phase_changed"):
		return
		
	_active_method_calls["on_phase_changed"] = true
	update_game_phase(event_data.phase_text)
	
	# If we have state information, update the full UI
	if "state" in event_data:
		var player_index = event_data.player_index if "player_index" in event_data else 0
		update_phase_ui(event_data.state, player_index)
	
	_active_method_calls["on_phase_changed"] = false

func on_player_changed(event_data):
	if _check_recursion("on_player_changed"):
		return
		
	_active_method_calls["on_player_changed"] = true
	if player_manager:
		update_current_turn(player_manager.get_player_name(event_data.player_index))
	_active_method_calls["on_player_changed"] = false
		
func on_game_over(event_data):
	if _check_recursion("on_game_over"):
		return
		
	_active_method_calls["on_game_over"] = true
	show_game_over(event_data.winning_player)
	_active_method_calls["on_game_over"] = false

func on_state_changed(event_data):
	if _check_recursion("on_state_changed"):
		return
		
	_active_method_calls["on_state_changed"] = true
	update_phase_ui(event_data.new_state, event_data.player_index)
	
	_active_method_calls["on_state_changed"] = false

# Check for recursive calls
func _check_recursion(method_name: String) -> bool:
	if _active_method_calls.has(method_name) and _active_method_calls[method_name]:
		return true
	return false

# Handle title screen animation completed
func _on_title_screen_animation_completed():
	emit_signal("title_screen_completed")
	emit_event("TITLE_SCREEN_COMPLETED")

# Show title screen for upcoming phase - clean up redundancy
func show_phase_title(phase_name):
	# Only handle phase name formatting once
	if title_screen and is_initialized:
		title_screen.visible = true
		title_screen.show_title(phase_name)
	else:
		emit_signal("title_screen_completed")
		emit_event("TITLE_SCREEN_COMPLETED")

# Update phase UI - with improved safety checks and recursion guard
func update_phase_ui(current_state, current_player_index):
	# Skip redundant updates to the same state/player
	if current_state == _last_state and current_player_index == _last_player:
		return
		
	# Set last state/player to prevent duplicates
	_last_state = current_state
	_last_player = current_player_index
	
	# Recursion guard
	if _check_recursion("update_phase_ui"):
		return
	
	_active_method_calls["update_phase_ui"] = true
	
	if !is_initialized:
		_active_method_calls["update_phase_ui"] = false
		return
	
	# Update turn label with visual styling
	if turn_label and player_manager:
		var player_name = player_manager.get_current_player_name()
		turn_label.text = player_name + "'s Turn"
		
	# Update phase label with visual styling
	if phase_label:
		var state_name = ""
		
		# Use local enum for safety
		if current_state < GameState.size():
			state_name = GameState.keys()[current_state]
		else:
			state_name = str(current_state)
		
		var phase_text = state_name.capitalize().replace("_", " ") + " Phase"
		phase_label.text = phase_text
		
		# Highlight the phase label based on current state
		phase_label.remove_theme_color_override("font_color") # Clear previous override
		
		# Use our local enum if game_state_machine is unavailable
		var phase_title_shown = false
		match current_state:
			GameState.UNINITIALIZED:
				phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			GameState.START_SCREEN:
				phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0))
			GameState.BASE_PLACEMENT:
				phase_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8))
				# Only show base placement title at the very start
				if _last_state != current_state:
					show_phase_title("Base Placement Phase")
					phase_title_shown = true
			GameState.WEAPON_PLACEMENT:
				phase_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
				# Only show weapon phase title if state just changed
				if _last_state != current_state:
					show_phase_title("Weapon Placement Phase")
					phase_title_shown = true
			GameState.TARGETING:
				phase_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))
				# Only show targeting phase title if state just changed
				if _last_state != current_state:
					show_phase_title("Target Selection Phase")
					phase_title_shown = true
			GameState.ATTACK_RESOLUTION:
				phase_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
				# Only show attack phase title if state just changed
				if _last_state != current_state:
					show_phase_title("Attack Resolution Phase")
					phase_title_shown = true
			GameState.GAME_OVER:
				phase_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.8))
				# Game over doesn't need a phase title
		
		# Notify game UI manager that the phase display was updated
		if !phase_title_shown: # Only emit if we didn't just show a title (to avoid double events)
			emit_event("PHASE_DISPLAY_UPDATED", {"phase_text": phase_text})
	
	_active_method_calls["update_phase_ui"] = false

# Emit an event through the event bus
func emit_event(event_name, event_data = null):
	var event_bus = null
	if Engine.has_singleton("GameManager"):
		event_bus = Engine.get_singleton("GameManager").get_service("EventBus")
	
	if event_bus:
		event_bus.emit_event(event_name, event_data)
