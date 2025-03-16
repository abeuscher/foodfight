extends Node

# Child UI manager instances
var base_ui_manager
var player_ui_manager
var phase_ui_manager
var placement_ui_manager
var targeting_ui_manager
var ai_ui_manager

# Initialization flag
var is_initialized = false

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Create the base UI manager
	base_ui_manager = Node.new()
	base_ui_manager.name = "BaseUIManager"
	base_ui_manager.set_script(load("res://scripts/ui/base_ui_manager.gd"))
	add_child(base_ui_manager)
	
	# Wait for the base UI manager to initialize
	await get_tree().process_frame
	
	# Get references to child managers from the base manager
	player_ui_manager = base_ui_manager.player_ui_manager
	phase_ui_manager = base_ui_manager.phase_ui_manager
	placement_ui_manager = base_ui_manager.placement_ui_manager
	targeting_ui_manager = base_ui_manager.targeting_ui_manager
	ai_ui_manager = base_ui_manager.ai_ui_manager
	
	# Forward the title_screen_completed signal
	if base_ui_manager:
		base_ui_manager.connect("title_screen_completed", Callable(self, "_on_title_screen_completed"))
	
	is_initialized = true
	print("Game UI Manager initialized")

# Forward title screen animation completed signal
func _on_title_screen_completed():
	emit_signal("title_screen_completed")

# Show title screen for upcoming phase
func show_phase_title(phase_name):
	if !is_initialized:
		print("GameUIManager: Title screen not available")
		emit_signal("title_screen_completed")
		return
	
	base_ui_manager.show_phase_title(phase_name)

# Update UI based on game state - delegated to base UI manager
func update_ui(current_state, current_player_index):
	if !is_initialized:
		return
		
	base_ui_manager.update_ui(current_state, current_player_index)

# Handle player turn update - delegated to base UI manager
func handle_player_turn_update(player_index):
	if !is_initialized:
		return
		
	base_ui_manager.handle_player_turn_update(player_index)

# Show AI thinking indicator - delegated to AI UI manager
func show_ai_thinking():
	if !is_initialized:
		return
		
	ai_ui_manager.show_ai_thinking()

# Hide AI thinking indicator - delegated to AI UI manager
func hide_ai_thinking():
	if !is_initialized:
		return
		
	ai_ui_manager.hide_ai_thinking()

# Update game phase - delegated to phase UI manager
func update_game_phase(phase_text):
	if !is_initialized:
		return
		
	phase_ui_manager.update_game_phase(phase_text)

# Update current turn label - delegated to phase UI manager
func update_current_turn(player_name):
	if !is_initialized:
		return
		
	phase_ui_manager.update_current_turn(player_name)

# Update player UI - delegated to player UI manager
func update_player_ui(new_player_index):
	if !is_initialized:
		return
		
	player_ui_manager.update_player_ui(new_player_index)

# Show game over screen - delegated to phase UI manager
func show_game_over(winning_player):
	if !is_initialized:
		return
		
	phase_ui_manager.show_game_over(winning_player)

# Connect signals from AI opponent - delegated to AI UI manager
func connect_ai_signals(ai_opponent):
	if !is_initialized:
		return
		
	ai_ui_manager.connect_ai_signals(ai_opponent)