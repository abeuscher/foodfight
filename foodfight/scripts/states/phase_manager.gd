extends Node

# Phase management system to centralize all phase transition logic
# and ensure proper sequencing of phase transitions

# Game phases - matching GameState enum in game_state_machine.gd
enum Phase { 
    UNINITIALIZED,
    START_SCREEN,
    BASE_PLACEMENT,
    WEAPON_PLACEMENT,
    TARGETING,
    ATTACK_RESOLUTION,
    GAME_OVER
}

# Signals for phase transitions
signal phase_started(phase, player_index)
signal phase_completed(phase, player_index)
signal player_phase_completed(phase, player_index)

# Component references
var game_board
var weapon_types
var weapon_placement
var targeting_state
var attack_state
var ui_manager
var player_manager
var event_bus

# Phase state tracking
var current_phase = Phase.UNINITIALIZED
var phase_transition_in_progress = false
var player_action_in_progress = false
var ai_action_in_progress = false
var is_initialized = false

# Track base placement to prevent multiple calls for same player
var base_placement_done = [false, false]

# Add recursion guards like in our other files
var _active_method_calls = {}

# Initialize the phase manager with dependencies
func initialize(p_game_board, p_weapon_types, p_weapon_placement, 
               p_targeting_state, p_attack_state, p_ui_manager, p_player_manager):
    # Guard against multiple initializations
    if is_initialized:
        print("PhaseManager: Already initialized, skipping")
        return self
        
    print("Init phase manager")
    
    # Store component references
    game_board = p_game_board
    weapon_types = p_weapon_types
    weapon_placement = p_weapon_placement
    targeting_state = p_targeting_state
    attack_state = p_attack_state
    ui_manager = p_ui_manager
    player_manager = p_player_manager
    
    # Get event bus reference if available
    if Engine.has_singleton("GameManager"):
        var game_manager = Engine.get_singleton("GameManager")
        event_bus = game_manager.get_service("EventBus")
    
    # Register phase completion callbacks
    if weapon_placement:
        # Avoid connecting multiple times
        if !weapon_placement.is_connected("weapon_placed", Callable(self, "_on_weapon_placed")):
            weapon_placement.weapon_placed.connect(_on_weapon_placed)
    
    is_initialized = true
    print("PhaseManager: Initialized")
    return self

# Start the game (initial entry point)
func start_game():
    print("PhaseManager: Starting game")
    # Reset base placement tracking
    base_placement_done = [false, false]
    transition_to_phase(Phase.BASE_PLACEMENT)

# Central method to handle all phase transitions
func transition_to_phase(new_phase, force_player_index = -1):
    # Prevent recursive or overlapping transitions
    if _active_method_calls.get("transition_to_phase", false):
        print("PhaseManager: Breaking recursive transition_to_phase call")
        return false
        
    _active_method_calls["transition_to_phase"] = true
    
    # Prevent overlapping transitions
    if phase_transition_in_progress:
        print("PhaseManager: Phase transition already in progress, ignoring request")
        _active_method_calls["transition_to_phase"] = false
        return false
        
    phase_transition_in_progress = true
    
    var old_phase = current_phase
    current_phase = new_phase
    
    # Determine player for this phase
    var player_index
    if force_player_index >= 0:
        player_index = force_player_index
    else:
        # Reset to player 1 when starting a new main phase
        if new_phase in [Phase.BASE_PLACEMENT, Phase.WEAPON_PLACEMENT, Phase.TARGETING] and old_phase != new_phase:
            player_manager.reset_current_player()
        player_index = player_manager.current_player_index
    
    print("PhaseManager: Transitioning from " + str(Phase.keys()[old_phase]) + 
          " to " + str(Phase.keys()[new_phase]) + 
          " for player " + str(player_index + 1))
    
    # When transitioning to BASE_PLACEMENT, reset base placement tracking
    if new_phase == Phase.BASE_PLACEMENT and old_phase != Phase.BASE_PLACEMENT:
        base_placement_done = [false, false]
    
    # Emit phase started signal
    emit_signal("phase_started", new_phase, player_index)
    
    # Emit event for external listeners
    emit_event("STATE_CHANGED", {
        "old_state": old_phase,
        "new_state": new_phase,
        "player_index": player_index
    })
    
    # Update UI with phase text
    emit_event("PHASE_CHANGED", {
        "phase_text": get_phase_display_name(new_phase),
        "state": new_phase
    })
    
    # Ensure player is updated in UI
    emit_event("PLAYER_CHANGED", {
        "player_index": player_index,
        "player_name": player_manager.get_current_player_name()
    })
    
    # Perform phase-specific initialization
    _initialize_phase(new_phase, player_index)
    
    # Transition complete
    phase_transition_in_progress = false
    
    # Process AI turn if needed (after transition is complete)
    if player_manager.is_current_player_ai():
        call_deferred("_process_ai_turn")
    
    _active_method_calls["transition_to_phase"] = false
    return true

# Get user-friendly phase name for display
func get_phase_display_name(phase):
    match phase:
        Phase.UNINITIALIZED:
            return "Initializing"
        Phase.START_SCREEN:
            return "Start Screen"
        Phase.BASE_PLACEMENT:
            return "Base Placement Phase"
        Phase.WEAPON_PLACEMENT:
            return "Weapon Placement Phase"
        Phase.TARGETING:
            return "Targeting Phase"
        Phase.ATTACK_RESOLUTION:
            return "Attack Resolution Phase"
        Phase.GAME_OVER:
            return "Game Over"
        _:
            return "Unknown Phase"

# Initialize a specific phase
func _initialize_phase(phase, player_index):
    match phase:
        Phase.BASE_PLACEMENT:
            _initialize_base_placement(player_index)
        Phase.WEAPON_PLACEMENT:
            _initialize_weapon_placement(player_index)
        Phase.TARGETING:
            _initialize_targeting(player_index)
        Phase.ATTACK_RESOLUTION:
            _initialize_attack_resolution()
        Phase.GAME_OVER:
            _initialize_game_over()

# Initialize base placement phase
func _initialize_base_placement(player_index):
    print("PhaseManager: Initializing base placement for player " + str(player_index + 1))
    
    if weapon_placement:
        weapon_placement.start_base_placement_phase(player_index)
    else:
        print("PhaseManager ERROR: Cannot initialize base placement - weapon_placement is null")

# Initialize weapon placement phase
func _initialize_weapon_placement(player_index):
    if _active_method_calls.get("_initialize_weapon_placement", false):
        print("PhaseManager: Breaking recursive _initialize_weapon_placement call")
        return
        
    _active_method_calls["_initialize_weapon_placement"] = true
    
    print("PhaseManager: Initializing weapon placement for player " + str(player_index + 1))
    
    if weapon_placement:
        # Explicitly update placement state UI first
        var placement_state = get_service("PlacementState")
        if placement_state and placement_state.has_method("create_weapon_buttons_for_current_state"):
            placement_state.create_weapon_buttons_for_current_state()
        
        # Then start placement phase
        weapon_placement.start_placement_phase(player_index)
    else:
        print("PhaseManager ERROR: Cannot initialize weapon placement - weapon_placement is null")
    
    _active_method_calls["_initialize_weapon_placement"] = false

# Initialize targeting phase
func _initialize_targeting(player_index):
    print("PhaseManager: Initializing targeting for player " + str(player_index + 1))
    
    if targeting_state:
        targeting_state.start_targeting(player_index)
    else:
        print("PhaseManager ERROR: Cannot initialize targeting - targeting_state is null")

# Initialize attack resolution phase
func _initialize_attack_resolution():
    print("PhaseManager: Initializing attack resolution")
    
    if attack_state:
        attack_state.execute_attacks()
    else:
        print("PhaseManager ERROR: Cannot initialize attack resolution - attack_state is null")

# Initialize game over phase
func _initialize_game_over():
    print("PhaseManager: Initializing game over")
    
    var winning_player = player_manager.get_winner_id()
    emit_event("GAME_OVER", {
        "winning_player": winning_player
    })

# Handle base placement completion
func base_placement_completed(player_index):
    if _active_method_calls.get("base_placement_completed", false):
        print("PhaseManager: Breaking recursive base_placement_completed call")
        return false
        
    _active_method_calls["base_placement_completed"] = true
    
    # Guard against duplicate completion calls
    if base_placement_done[player_index]:
        print("PhaseManager: Base placement already completed for player " + str(player_index + 1) + ", ignoring duplicate call")
        _active_method_calls["base_placement_completed"] = false
        return false
        
    if current_phase != Phase.BASE_PLACEMENT:
        print("PhaseManager WARNING: Ignoring base placement completion - not in BASE_PLACEMENT phase")
        _active_method_calls["base_placement_completed"] = false
        return false
    
    print("PhaseManager: Base placement completed for player " + str(player_index + 1))
    
    # Mark this player's base placement as done
    base_placement_done[player_index] = true
    
    emit_signal("player_phase_completed", Phase.BASE_PLACEMENT, player_index)
    
    # First player completed base placement
    if player_index == 0:
        # Switch to player 2
        player_manager.next_player()
        var next_player = player_manager.current_player_index
        
        print("PhaseManager: Switching to player " + str(next_player + 1) + " for base placement")
        
        # Update player without changing phase
        emit_event("PLAYER_CHANGED", {
            "player_index": next_player,
            "player_name": player_manager.get_player_name(next_player)
        })
        
        # Re-initialize base placement for next player
        weapon_placement.start_base_placement_phase(next_player)
        
        # Process AI turn if needed
        if player_manager.is_current_player_ai():
            call_deferred("_process_ai_turn")
    else:
        # Both players have completed base placement, move to weapon placement
        print("PhaseManager: All players completed base placement, moving to weapon placement")
        emit_signal("phase_completed", Phase.BASE_PLACEMENT, player_index)
        transition_to_phase(Phase.WEAPON_PLACEMENT)
    
    _active_method_calls["base_placement_completed"] = false
    return true

# Handle weapon placement completion
func weapon_placement_completed(player_index):
    if _active_method_calls.get("weapon_placement_completed", false):
        print("PhaseManager: Breaking recursive weapon_placement_completed call")
        return false
        
    _active_method_calls["weapon_placement_completed"] = true
    
    if current_phase != Phase.WEAPON_PLACEMENT:
        print("PhaseManager WARNING: Ignoring weapon placement completion - not in WEAPON_PLACEMENT phase")
        _active_method_calls["weapon_placement_completed"] = false
        return false
    
    print("PhaseManager: Weapon placement completed for player " + str(player_index + 1))
    emit_signal("player_phase_completed", Phase.WEAPON_PLACEMENT, player_index)
    
    # First player completed weapon placement
    if player_index == 0:
        # Switch to player 2
        player_manager.next_player()
        var next_player = player_manager.current_player_index
        
        print("PhaseManager: Switching to player " + str(next_player + 1) + " for weapon placement")
        
        # Update player without changing phase
        emit_event("PLAYER_CHANGED", {
            "player_index": next_player,
            "player_name": player_manager.get_player_name(next_player)
        })
        
        # Re-initialize weapon placement for next player
        weapon_placement.start_placement_phase(next_player)
        
        # Process AI turn if needed
        if player_manager.is_current_player_ai():
            call_deferred("_process_ai_turn")
    else:
        # Both players have completed weapon placement, move to targeting
        print("PhaseManager: All players completed weapon placement, moving to targeting")
        emit_signal("phase_completed", Phase.WEAPON_PLACEMENT, player_index)
        transition_to_phase(Phase.TARGETING)
    
    _active_method_calls["weapon_placement_completed"] = false
    return true

# Handle targeting completion
func targeting_completed(player_index):
    if _active_method_calls.get("targeting_completed", false):
        print("PhaseManager: Breaking recursive targeting_completed call")
        return false
        
    _active_method_calls["targeting_completed"] = true
    
    if current_phase != Phase.TARGETING:
        print("PhaseManager WARNING: Ignoring targeting completion - not in TARGETING phase")
        _active_method_calls["targeting_completed"] = false
        return false
    
    print("PhaseManager: Targeting completed for player " + str(player_index + 1))
    emit_signal("player_phase_completed", Phase.TARGETING, player_index)
    
    # First player completed targeting
    if player_index == 0:
        # Switch to player 2
        player_manager.next_player()
        var next_player = player_manager.current_player_index
        
        print("PhaseManager: Switching to player " + str(next_player + 1) + " for targeting")
        
        # Update player without changing phase
        emit_event("PLAYER_CHANGED", {
            "player_index": next_player,
            "player_name": player_manager.get_player_name(next_player)
        })
        
        # Re-initialize targeting for next player
        targeting_state.start_targeting(next_player)
        
        # Process AI turn if needed
        if player_manager.is_current_player_ai():
            call_deferred("_process_ai_turn")
    else:
        # Both players have completed targeting, move to attack resolution
        print("PhaseManager: All players completed targeting, moving to attack resolution")
        emit_signal("phase_completed", Phase.TARGETING, player_index)
        transition_to_phase(Phase.ATTACK_RESOLUTION)
    
    _active_method_calls["targeting_completed"] = false
    return true

# Handle attack resolution completion
func attack_resolution_completed():
    if _active_method_calls.get("attack_resolution_completed", false):
        print("PhaseManager: Breaking recursive attack_resolution_completed call")
        return false
        
    _active_method_calls["attack_resolution_completed"] = true
    
    if current_phase != Phase.ATTACK_RESOLUTION:
        print("PhaseManager WARNING: Ignoring attack resolution completion - not in ATTACK_RESOLUTION phase")
        _active_method_calls["attack_resolution_completed"] = false
        return false
    
    print("PhaseManager: Attack resolution completed")
    emit_signal("phase_completed", Phase.ATTACK_RESOLUTION, player_manager.current_player_index)
    
    # Check for game over condition
    var winner = _check_for_game_over()
    
    if winner >= 0:
        # Game is over, transition to game over phase
        player_manager.set_winner(winner)
        transition_to_phase(Phase.GAME_OVER)
    else:
        # Continue to next round with weapon placement
        transition_to_phase(Phase.WEAPON_PLACEMENT)
    
    _active_method_calls["attack_resolution_completed"] = false
    return true

# Track when a weapon is placed - to determine phase completion
func _on_weapon_placed(player_id, weapon_data, position):
    # For base placement, trigger completion when base is placed
    if current_phase == Phase.BASE_PLACEMENT and weapon_data.type == "base":
        print("PhaseManager: Base placed for player " + str(player_id + 1))
        call_deferred("base_placement_completed", player_id)

# Process AI turn if current player is AI
func _process_ai_turn():
    if _active_method_calls.get("_process_ai_turn", false):
        print("PhaseManager: Breaking recursive _process_ai_turn call")
        return false
    
    _active_method_calls["_process_ai_turn"] = true
    
    if !player_manager.is_current_player_ai():
        _active_method_calls["_process_ai_turn"] = false
        return false
    
    if ai_action_in_progress:
        print("PhaseManager: AI action already in progress")
        _active_method_calls["_process_ai_turn"] = false
        return false
    
    print("PhaseManager: Processing AI turn for phase " + str(Phase.keys()[current_phase]))
    ai_action_in_progress = true
    
    # Get the AI controller
    var ai_controller = get_service("AIController")
    
    if !ai_controller:
        print("PhaseManager ERROR: Cannot process AI turn - AIController not found")
        ai_action_in_progress = false
        _active_method_calls["_process_ai_turn"] = false
        return false
    
    # Signal that AI is thinking (for UI)
    emit_event("AI_THINKING_STARTED")
    
    # Process AI turn with timeout safety
    var ai_processed = ai_controller.process_ai_turn_if_needed()
    
    # If AI processing failed, use fallback mechanism
    if !ai_processed:
        print("PhaseManager WARNING: AI turn processing failed, using fallback")
        _handle_ai_fallback()
    
    # Signal that AI is done thinking
    emit_event("AI_THINKING_COMPLETED")
    
    ai_action_in_progress = false
    _active_method_calls["_process_ai_turn"] = false
    return ai_processed

# Handle AI fallback for various phases
func _handle_ai_fallback():
    match current_phase:
        Phase.BASE_PLACEMENT:
            _force_ai_base_placement()
        Phase.WEAPON_PLACEMENT:
            weapon_placement_completed(player_manager.current_player_index)
        Phase.TARGETING:
            targeting_completed(player_manager.current_player_index)

# Force AI base placement as fallback
func _force_ai_base_placement():
    # This is a backup method if the AI controller fails
    print("PhaseManager: Forcing AI base placement as fallback")
    
    # Get the AI opponent
    var ai_opponent = null
    if Engine.has_singleton("GameManager"):
        ai_opponent = Engine.get_singleton("GameManager").ai_opponent
    
    if ai_opponent:
        # Perform AI base placement directly
        var result = ai_opponent.perform_base_placement()
        print("PhaseManager: Forced AI base placement result: " + str(result))
        
        # Complete the base placement phase
        await get_tree().create_timer(0.5).timeout
        base_placement_completed(player_manager.current_player_index)
    else:
        print("PhaseManager ERROR: Cannot find AI opponent for fallback base placement")
        # Force completion anyway as last resort
        await get_tree().create_timer(0.5).timeout
        base_placement_completed(player_manager.current_player_index)

# Check for game over condition
func _check_for_game_over():
    # Count bases for each player
    var player1_bases = 0
    var player2_bases = 0
    
    for x in range(game_board.grid_size.x):
        for y in range(game_board.grid_size.y):
            var cell = game_board.grid[x][y]
            if cell.occupied_by and "weapon_data" in cell.occupied_by:
                if cell.occupied_by.weapon_data.type == "base":
                    if cell.occupied_by.player_id == 0:
                        player1_bases += 1
                    else:
                        player2_bases += 1
    
    # Check for winner
    if player1_bases == 0:
        return 1  # Player 2 (AI) wins
    elif player2_bases == 0:
        return 0  # Player 1 wins
    
    return -1  # No winner yet

# Emit an event through the event bus
func emit_event(event_name, event_data = null):
    if event_bus:
        print("PhaseManager: Emitting event: " + event_name)
        event_bus.emit_event(event_name, event_data)
    else:
        print("PhaseManager WARNING: No event bus available to emit event " + event_name)

# Helper method to get a service using service locator pattern
func get_service(service_name):
    if Engine.has_singleton("GameManager"):
        return Engine.get_singleton("GameManager").get_service(service_name)
    return null