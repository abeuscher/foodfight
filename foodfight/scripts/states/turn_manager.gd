extends Node

signal player_changed(new_player_index)

# Player tracking
var current_player_index = 0
var player_manager
var phase_manager
var total_players = 2 # Add missing variable that was referenced in the code

func initialize(p_player_manager):
    player_manager = p_player_manager
    current_player_index = player_manager.current_player_index
    
    # Try to get phase manager reference
    if Engine.has_singleton("GameManager"):
        var game_manager = Engine.get_singleton("GameManager")
        phase_manager = game_manager.get_service("PhaseManager")
        
    # Emit initial signal so UI can update
    emit_signal("player_changed", current_player_index)
    
    return self

# Get current player name
func get_current_player_name():
    return player_manager.get_current_player_name()

# Switch to next player
func next_player():
    player_manager.next_player()
    current_player_index = player_manager.current_player_index
    print("TurnManager: Changed to player " + str(current_player_index + 1) + " (" + get_current_player_name() + ")")
    emit_signal("player_changed", current_player_index)
    return current_player_index

# Reset to player 1
func reset_current_player():
    player_manager.reset_current_player()
    current_player_index = player_manager.current_player_index
    print("TurnManager: Reset to player " + str(current_player_index + 1) + " (" + get_current_player_name() + ")")
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

# Switch to the next turn
func next_turn():
    current_player_index = (current_player_index + 1) % total_players
    print("TurnManager: Advancing to player " + str(current_player_index + 1))
    
    # Notify PhaseManager of the new turn
    var phase_manager = get_service("PhaseManager")
    if phase_manager:
        phase_manager.on_turn_started(current_player_index)
    # Ensure dictionary elements are properly closed
    return {"current_player_index": current_player_index} # Correctly closed dictionary