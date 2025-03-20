# Session 27: Event System Implementation

## Phase 2 Recap

In Phase 2, we successfully implemented a robust staged initialization system:

1. Created an InitializationController to manage initialization stages
2. Implemented dependency checking between components
3. Enhanced error handling through the NullService class
4. Made component initialization more reliable with proper sequencing
5. Added better diagnostics for initialization failures

These improvements have provided a solid foundation for our UI system, but we still have tight coupling between components through direct method calls, which can make the codebase harder to maintain and extend.

## Phase 3 Goals

In this phase, we will implement an event-based communication system that will:

1. Decouple components through event-based messaging
2. Standardize communication between game systems
3. Make our UI system more resilient to changes
4. Reduce dependencies between components

## Implementation Plan

### 1. Create the Event Bus

First, we'll create a central event bus that will manage event publishing and subscription:

```gdscript
# New file: scripts/core/event_bus.gd
class_name EventBus
extends Node

# Dictionary to store signal connections
# Format: { "event_name": [array_of_listeners] }
var _listeners = {}

# Emit an event with optional arguments
func emit_event(event_name: String, args = null) -> void:
    if not _listeners.has(event_name):
        return
        
    for listener in _listeners[event_name]:
        if args is Dictionary:
            listener.callv("on_" + event_name, [args])
        else:
            listener.call("on_" + event_name)

# Subscribe to an event
func subscribe(event_name: String, listener: Object) -> bool:
    if not listener.has_method("on_" + event_name):
        push_warning("Listener does not implement method 'on_" + event_name + "'")
        return false
        
    if not _listeners.has(event_name):
        _listeners[event_name] = []
        
    if not _listeners[event_name].has(listener):
        _listeners[event_name].append(listener)
        
    return true

# Unsubscribe from an event
func unsubscribe(event_name: String, listener: Object) -> bool:
    if not _listeners.has(event_name):
        return false
        
    var idx = _listeners[event_name].find(listener)
    if idx >= 0:
        _listeners[event_name].remove_at(idx)
        return true
        
    return false

# Unsubscribe from all events
func unsubscribe_all(listener: Object) -> void:
    for event_name in _listeners.keys():
        unsubscribe(event_name, listener)
```

### 2. Define Standard Game Events

Next, we'll define a set of standard events for our game:

```gdscript
# New file: scripts/core/game_events.gd
class_name GameEvents
extends Object

# Game state events
const STATE_CHANGED = "state_changed"
const GAME_STARTED = "game_started"
const GAME_ENDED = "game_ended"
const TURN_CHANGED = "turn_changed"
const PLAYER_CHANGED = "player_changed"

# UI update events
const UI_UPDATE_REQUIRED = "ui_update_required"
const PHASE_CHANGED = "phase_changed" 
const PLAYER_STATS_CHANGED = "player_stats_changed"
const SHOW_MESSAGE = "show_message"

# Weapon events
const WEAPON_SELECTED = "weapon_selected"
const WEAPON_PLACED = "weapon_placed"
const WEAPON_REMOVED = "weapon_removed"

# Targeting events
const TARGET_SELECTED = "target_selected"
const TARGET_CONFIRMED = "target_confirmed"
const TARGETING_STARTED = "targeting_started"
const TARGETING_COMPLETED = "targeting_completed"

# AI events
const AI_THINKING_STARTED = "ai_thinking_started"
const AI_THINKING_COMPLETED = "ai_thinking_completed"
const AI_MOVE_EXECUTED = "ai_move_executed"

# Board events
const CELL_SELECTED = "cell_selected"
const CELL_STATE_CHANGED = "cell_state_changed"
const ATTACK_VISUALIZED = "attack_visualized"
```

### 3. Register the Event Bus in GameManager

Update GameManager to create and register the event bus:

```gdscript
# Modified: game_manager.gd
# Add event bus
var event_bus

func _ready():
    # Existing code...
    
    # Create and register event bus
    event_bus = EventBus.new()
    add_child(event_bus)
    register_service("EventBus", event_bus)

# Add helper method to emit events
func emit_event(event_name: String, args = null) -> void:
    var bus = get_service("EventBus")
    if bus:
        bus.emit_event(event_name, args)
```

### 4. Convert Direct Method Calls to Events

Update key components to use events instead of direct method calls:

#### Game State Machine:

```gdscript
# Modified: game_state_machine.gd
func _set_state(new_state):
    var old_state = current_state
    current_state = new_state
    
    # Emit event instead of calling UI directly
    var event_data = {
        "old_state": old_state,
        "new_state": new_state,
        "player_index": player_manager.current_player_index
    }
    GameManager.emit_event(GameEvents.STATE_CHANGED, event_data)
```

#### Targeting State:

```gdscript
# Modified: targeting_state.gd
func start_player_turn(player_index):
    current_player = player_index
    # Replace direct signal with event
    GameManager.emit_event(GameEvents.TARGETING_STARTED, {"player_index": player_index})
```

#### AI Opponent:

```gdscript
# Modified: ai_opponent.gd
func start_thinking():
    # Replace direct signal with event
    GameManager.emit_event(GameEvents.AI_THINKING_STARTED)
    
    # Rest of the method...
    
func complete_thinking():
    # Replace direct signal with event
    GameManager.emit_event(GameEvents.AI_THINKING_COMPLETED)
    
    # Rest of the method...
```

### 5. Implement Event Handlers in UI Components

Update UI components to subscribe to and handle events:

```gdscript
# Modified: base_ui_manager.gd
func _ready():
    var event_bus = GameManager.get_service("EventBus")
    event_bus.subscribe(GameEvents.STATE_CHANGED, self)
    event_bus.subscribe(GameEvents.AI_THINKING_STARTED, self)
    event_bus.subscribe(GameEvents.AI_THINKING_COMPLETED, self)
    event_bus.subscribe(GameEvents.PHASE_CHANGED, self)
    event_bus.subscribe(GameEvents.PLAYER_CHANGED, self)

# Event handlers
func on_state_changed(event_data):
    update_ui(event_data.new_state, event_data.player_index)
    
func on_ai_thinking_started(_event_data = null):
    show_ai_thinking()
    
func on_ai_thinking_completed(_event_data = null):
    hide_ai_thinking()
    
func on_phase_changed(event_data):
    update_game_phase(event_data.phase_text)
    
func on_player_changed(event_data):
    update_player_ui(event_data.player_index)
```

## Files to Modify

1. **New: scripts/core/event_bus.gd**:
   - Central event manager for publishing and subscribing to events

2. **New: scripts/core/game_events.gd**:
   - Constants defining standard event names

3. **scripts/states/game_manager.gd**:
   - Register event bus as a service
   - Add helper methods for event operations

4. **scripts/states/game_state_machine.gd**:
   - Convert state changes to events
   - Update transitions to use event system

5. **scripts/states/targeting_state.gd**:
   - Use events for player turn management
   - Convert direct UI updates to events

6. **scripts/ai/ai_opponent.gd**:
   - Convert AI status signals to events

7. **scripts/ui/base_ui_manager.gd**:
   - Subscribe to events
   - Implement event handlers

## Testing Approaches

1. **Event Publishing Test**:
   - Verify events are properly emitted on state changes
   - Check that all components emit appropriate events

2. **Event Subscription Test**:
   - Verify UI components properly subscribe to events
   - Check that event handlers are correctly called

3. **Communication Flow Test**:
   - Test the complete flow from state change to UI update
   - Ensure all components interact correctly through events

4. **Error Handling Test**:
   - Test with non-existent events
   - Ensure robust handling of missing subscribers

## Expected Outcome

After this phase, the game components will:
- Communicate through standardized events
- Be more decoupled from each other
- Have cleaner and more maintainable code
- Be more resilient to changes in other components

The UI system will update properly in response to game state changes through event handling rather than direct method calls.

## Next Phase Preview

In Phase 4, we'll fully integrate all UI components with the event system:
- Ensure consistent event usage across all UI managers
- Create a unified interface for UI updates
- Implement safety mechanisms for missing UI components
- Add specialized event handlers for different UI components
