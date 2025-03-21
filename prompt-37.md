# Sprint 2 | Phase 2: Implementing Modal Waiting State for AI Turns

## Current Progress Summary

We've made significant progress understanding the root cause of our AI turn issues:

1. We identified that we're stuck in a cycle where:
   - Player completes their turn
   - AI turn begins
   - PhaseManager tries to call AI controller
   - But before the AI can act, other events are processed that switch back to the player
   - This loop repeats indefinitely

2. Our attempts to fix this with stronger guards have helped identify the issue but haven't fully resolved it. We added:
   - Recursion guards in methods
   - Event timestamp comparison to ignore duplicate events
   - A `game_waiting_for_ai` flag with player tracking 
   - Input blocking in the main input handler

3. We now understand that the fundamental issue is:
   - There's no true "modal" waiting state that blocks all game event processing
   - Events are being processed in parallel with AI processing
   - We need a more fundamental approach to event handling during AI turns

## Solution Design: Modal Waiting State System

What we need is a comprehensive waiting state system for AI turns that:

1. **Blocks all game state changes** during AI processing
2. **Prevents all input** while AI is thinking
3. **Queues or filters events** that occur during AI turns
4. **Uses synchronous callbacks** rather than events for AI turn completion

## Key Files to Modify

1. **`e:\FoodFightGodot\foodfight\scripts\core\event_bus.gd`**:
   - Add a modal waiting state system
   - Add ability to queue events instead of processing them immediately
   - Add methods to enter/exit blocking mode

2. **`e:\FoodFightGodot\foodfight\scripts\states\phase_manager.gd`**:
   - Modify `_process_ai_turn()` to use the new modal waiting system
   - Update event handlers to respect waiting state
   - Improve debugging output to track waiting state

3. **`e:\FoodFightGodot\foodfight\scripts\ai\ai_controller.gd`**:
   - Update to use callbacks instead of events for turn completion
   - Add support for truly blocking AI processing

4. **`e:\FoodFightGodot\foodfight\scripts\main.gd`**:
   - Enhance the input blocker to be more robust
   - Add visual feedback when input is blocked

## Specific Implementation Instructions

### 1. EventBus Modal Waiting System

First, modify the EventBus to support a blocking mode:

```gdscript
// In event_bus.gd:
# Blocking mode properties
var blocking_mode_active = false
var queued_events = []
var allowed_events_during_blocking = ["AI_THINKING_COMPLETED", "AI_ACTION_COMPLETED"]

# Enter blocking mode - queue events instead of processing them
func enter_blocking_mode():
    print("EventBus: Entering blocking mode - events will be queued")
    blocking_mode_active = true
    
# Exit blocking mode and process any queued events
func exit_blocking_mode():
    print("EventBus: Exiting blocking mode - processing queued events")
    blocking_mode_active = false
    
    # Process queued events
    var events_to_process = queued_events.duplicate()
    queued_events.clear()
    
    for event in events_to_process:
        emit_event(event.name, event.data)
        
# Override emit_event to respect blocking mode
func emit_event(event_name: String, event_data = null) -> void:
    # Always allow certain events even in blocking mode
    if blocking_mode_active and not event_name in allowed_events_during_blocking:
        print("EventBus: Event " + event_name + " queued (blocking mode active)")
        queued_events.append({"name": event_name, "data": event_data})
        return
        
    # Proceed with normal event emission
    # [existing emission code]
```

### 2. PhaseManager Updates

Update PhaseManager to use the blocking mode system:

```gdscript
// In phase_manager.gd:
# Process AI turn with proper blocking
func _process_ai_turn():
    if _active_method_calls.get("_process_ai_turn", false):
        print("PhaseManager: Recursive call to _process_ai_turn detected and blocked")
        return false
    
    _active_method_calls["_process_ai_turn"] = true
    
    # DEBUG OUTPUT
    print("PhaseManager: _process_ai_turn called - player_index=" + str(player_manager.current_player_index))
    
    # If not AI's turn, exit immediately
    if !player_manager.is_current_player_ai():
        print("PhaseManager: Not AI turn - current player is " + player_manager.get_current_player_name())
        _active_method_calls["_process_ai_turn"] = false
        return false
    
    # Set waiting state
    game_waiting_for_ai = true
    ai_action_in_progress = true
    current_ai_action_player = player_manager.current_player_index
    
    # Block all events during AI turn - this is the key change
    var event_bus = get_service("EventBus")
    if event_bus and event_bus.has_method("enter_blocking_mode"):
        event_bus.enter_blocking_mode()
    
    # Show UI feedback
    emit_event("GAME_WAITING_STATE_CHANGED", {"waiting": true, "reason": "ai_thinking"})
    emit_event("AI_THINKING_STARTED")
    
    # Process AI turn
    var ai_controller = get_service("AIController")
    if ai_controller:
        # Use callback approach instead of deferred call
        print("PhaseManager: Using AIController to process turn with callback")
        ai_controller.process_ai_turn_with_callback(func():
            # This code runs AFTER AI completes its turn
            _on_ai_turn_completed()
        )
    else:
        # Fallback
        _handle_ai_fallback()
        # Still need to complete
        _on_ai_turn_completed()
    
    _active_method_calls["_process_ai_turn"] = false
    return true
    
# New callback method when AI completes its turn
func _on_ai_turn_completed():
    print("PhaseManager: AI turn completed callback")
    
    # Unblock events
    var event_bus = get_service("EventBus")
    if event_bus and event_bus.has_method("exit_blocking_mode"):
        event_bus.exit_blocking_mode()
    
    # Reset waiting state
    game_waiting_for_ai = false
    ai_action_in_progress = false
    current_ai_action_player = -1
    
    # Signal completion
    emit_event("AI_THINKING_COMPLETED")
    emit_event("GAME_WAITING_STATE_CHANGED", {"waiting": false})
```

### 3. AIController Updates

Modify AIController to use callbacks:

```gdscript
// In ai_controller.gd:
# New method that takes a completion callback
func process_ai_turn_with_callback(completion_callback):
    print("AIController: process_ai_turn_with_callback called")
    
    if !player_manager.is_current_player_ai():
        print("AIController: Not AI's turn - player index: " + str(player_manager.current_player_index))
        completion_callback.call() # Still call callback to unblock
        return false
    
    if ai_turn_in_progress:
        print("AIController: AI turn already in progress")
        completion_callback.call() # Still call callback to unblock
        return true
    
    # Start AI processing
    ai_turn_in_progress = true
    _show_ai_thinking()
    
    print("AIController: Processing AI turn for phase " + str(phase_manager.current_phase))
    
    # Handle different phases with callback
    match phase_manager.current_phase:
        PhaseManager.Phase.BASE_PLACEMENT:
            _handle_base_placement_with_callback(completion_callback)
        PhaseManager.Phase.WEAPON_PLACEMENT:
            _handle_weapon_placement_with_callback(completion_callback) 
        PhaseManager.Phase.TARGETING:
            _handle_targeting_with_callback(completion_callback)
        _:
            print("AIController: No matching phase handler")
            ai_turn_in_progress = false
            _hide_ai_thinking()
            completion_callback.call() # Must call callback to unblock game
    
    return true
    
# Phase-specific methods with callbacks
func _handle_base_placement_with_callback(completion_callback):
    if !ai_opponent:
        ai_turn_in_progress = false
        _hide_ai_thinking()
        completion_callback.call()
        return
        
    # Run AI base placement with timeout to ensure completion
    var placement_result = ai_opponent.perform_base_placement()
    
    # Complete after a short delay
    get_tree().create_timer(0.5).timeout.connect(func():
        # Complete the phase
        ai_turn_in_progress = false
        _hide_ai_thinking()
        
        var player_idx = player_manager.current_player_index
        # Directly tell phase manager the action is complete
        if phase_manager:
            phase_manager.base_placement_completed(player_idx)
            
        # Call the callback to unblock the game
        completion_callback.call()
    )
```

### 4. Input Blocking in Main

Enhance the input blocking in main.gd:

```gdscript
// In main.gd:
# Handle input events
func _input(event):
    if !game_initialized:
        return
    
    # Check if game is waiting for AI before handling input
    var phase_manager = get_service("PhaseManager")
    if phase_manager and phase_manager.is_game_waiting():
        # Show visual feedback that input is blocked
        if ai_thinking_indicator and !ai_thinking_indicator.visible:
            ai_thinking_indicator.visible = true
        
        # Block ALL input while waiting
        get_viewport().set_input_as_handled()
        return
    
    # Hide visual feedback when input is not blocked
    if ai_thinking_indicator and ai_thinking_indicator.visible:
        ai_thinking_indicator.visible = false
    
    # Regular input handling
    # [existing input handling code]
```

## Important Implementation Notes

1. **No Backwards Compatibility**: These changes break compatibility with any previous code relying on the old event handling. Since this is a new app, we'll find and fix any regressions rather than maintaining backward compatibility.

2. **Complete Synchronous System**: The new implementation should be fully synchronous with proper callbacks, not relying on events for phase completion during AI turns.

3. **Debugging**: Add extensive debug output to track the waiting state and event queue, helping identify any remaining issues.

4. **Testing**: Focus testing on the transition from player to AI and back to make sure the game flow works correctly.

## Expected Outcome

After these changes, the game should:

1. Properly transition to AI turns
2. Block all inputs and event processing during AI turns
3. Process queued events after the AI turn completes
4. Never get stuck in a loop between player turns
5. Provide clear visual feedback when the game is waiting for AI

Let's implement this robust waiting state system to finally fix the AI turn issues!
