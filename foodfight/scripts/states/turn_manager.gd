extends Node

signal player_changed(new_player_index)

# Player tracking
var current_player_index = 0
var player_manager
var phase_manager

func initialize(p_player_manager):
    player_manager = p_player_manager
    current_player_index = player_manager.current_player_index
    
    # Try to get phase manager reference
    if Engine.has_singleton("GameManager"):
        var game_manager = Engine.get_singleton("GameManager")
        phase_manager = game_manager.get_service("PhaseManager")
        
    return self

# Get current player name
func get_current_player_name():
    return player_manager.get_current_player_name()

# Switch to next player
func next_player():
    player_manager.next_player()
    current_player_index = player_manager.current_player_index
    emit_signal("player_changed", current_player_index)
    return current_player_index

# Reset to player 1
func reset_current_player():
    player_manager.reset_current_player()
    current_player_index = player_manager.current_player_index
    emit_signal("player_changed", current_player_index)
    return current_player_index

# Award ingredients to a player
func award_ingredients(player_id, amount):
    player_manager.add_ingredients(player_id, amount)

# Set winner player
func set_winner(player_id):
    if player_manager.has_method("set_winner"):
        player_manager.set_winner(player_id)
    return player_id