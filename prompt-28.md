# Prompt-28: UI Component Integration

```markdown
# Session 28: UI Component Integration

## Phase 3 Recap

In Phase 3, we successfully implemented an event-based communication system:

1. Created a central EventBus to manage event publishing and subscription
2. Defined standard game events through the GameEvents class
3. Updated GameManager to register and use the event bus
4. Modified components to use events instead of direct method calls
5. Implemented basic event handlers in the UI components

These improvements laid the groundwork for decoupling our components, but we still need to fully integrate all UI managers with the event system.

## Phase 4 Goals

In this phase, we will:

1. Ensure all UI managers properly use the event system
2. Complete the decoupling of UI components
3. Create a consistent interface for UI updates
4. Implement safety mechanisms for missing components
5. Enhance debugging and error reporting for UI events

## Implementation Plan

### 1. Create a BaseUIListener Class

First, we'll create a base class that all UI managers can extend to easily handle events:

```gdscript
# New file: scripts/ui/base_ui_listener.gd
class_name BaseUIListener
extends Node

# Flag to check if we're registered with the event bus
var _events_registered = false

# Flag to control automatic event subscription
var auto_subscribe_events = true

func _ready():
    # Automatically subscribe to events if set
    if auto_subscribe_events:
        call_deferred("register_events")

# Register to all events this listener can handle
func register_events():
    if _events_registered:
        return
        
    var event_bus = _get_event_bus()
    if not event_bus:
        push_warning("Unable to register events: EventBus not found")
        return
        
    # Get all methods that start with "on_"
    var method_list = get_method_list()
    var event_handlers = []
    
    for method in method_list:
        var method_name = method["name"]
        if method_name.begins_with("on_"):
            var event_name = method_name.substr(3)
            event_handlers.append(event_name)
            event_bus.subscribe(event_name, self)
    
    if event_handlers.size() > 0:
        print(get_path_to(get_parent()) + ": Registered events: " + str(event_handlers))
        _events_registered = true
    else:
        push_warning(get_path_to(get_parent()) + ": No event handlers found")

# Unregister events when scene is exiting
func _exit_tree():
    unregister_events()
    
# Unregister all events
func unregister_events():
    if not _events_registered:
        return
        
    var event_bus = _get_event_bus()
    if event_bus:
        event_bus.unsubscribe_all(self)
        _events_registered = false

# Helper to get event bus
func _get_event_bus():
    if Engine.has_singleton("GameManager"):
        var game_manager = Engine.get_singleton("GameManager")
        return game_manager.get_service("EventBus")
    return null
    
# Helper to emit an event
func emit_event(event_name, args = null):
    if Engine.has_singleton("GameManager"):
        var game_manager = Engine.get_singleton("GameManager")
        game_manager.emit_event(event_name, args)
```

### 2. Update BaseUIManager

Next, we'll update the BaseUIManager to extend BaseUIListener and handle common UI events:

```gdscript
# Modified: scripts/ui/base_ui_manager.gd
extends BaseUIListener

# Child managers
var player_ui_manager
var phase_ui_manager
var placement_ui_manager
var targeting_ui_manager
var ai_ui_manager

# Signals
signal title_screen_completed

func _ready():
    super._ready()  # Call base class ready
    # Initialize child UI managers
    # ...existing code...

# Event handlers
func on_ui_update_required(event_data):
    update_ui(event_data.state, event_data.player_index)
    
func on_phase_changed(event_data):
    update_game_phase(event_data.phase_text)
    
func on_player_changed(event_data):
    update_player_ui(event_data.player_index)
    
# UI update methods
func update_ui(current_state, current_player_index):
    # Update all UI components based on state
    # ...existing code...
```

### 3. Update Specialized UI Managers

Update each specialized UI manager to extend BaseUIListener and handle specific events:

```gdscript
# Modified: scripts/ui/player_ui_manager.gd
extends BaseUIListener

# Event handlers specific to player UI
func on_player_changed(event_data):
    update_player_ui(event_data.player_index)

func on_player_stats_changed(event_data):
    update_player_resources(event_data.player_index, event_data.resources)
```

```gdscript
# Modified: scripts/ui/ai_ui_manager.gd
extends BaseUIListener

# Event handlers for AI UI
func on_ai_thinking_started(_event_data = null):
    show_ai_thinking()
    
func on_ai_thinking_completed(_event_data = null):
    hide_ai_thinking()
```

### 4. Update BaseUIManager with Improved Event Handling

Enhance the BaseUIManager to better delegate events to specialized managers:

```gdscript
# Modified: scripts/ui/base_ui_manager.gd
extends BaseUIListener

# Event delegation patterns
func on_state_changed(event_data):
    # Some logic specific to BaseUIManager
    # ...then delegate to child managers
    update_ui(event_data.new_state, event_data.player_index)

# Method to safely call a function on a UI manager with fallbacks
func _safe_ui_call(manager_name, method_name, args = []):
    var manager = get(manager_name)
    
    if manager and manager.has_method(method_name):
        match args.size():
            0: return manager.call(method_name)
            1: return manager.call(method_name, args[0])
            2: return manager.call(method_name, args[0], args[1])
            _: push_warning("Unsupported argument count")
    else:
        # Fall back to base_ui_manager if specialized manager is missing
        if base_ui_manager and base_ui_manager.has_method(method_name):
            match args.size():
                0: return base_ui_manager.call(method_name)
                1: return base_ui_manager.call(method_name, args[0])
                2: return base_ui_manager.call(method_name, args[0], args[1])
                _: push_warning("Unsupported argument count")
        else:
            push_warning("Missing UI capability: " + manager_name + "." + method_name)
            # Log the issue but don't crash
```

### 5. Add Debug UI Manager

To help with debugging, create a DebugUIManager:

```gdscript
# New file: scripts/ui/debug_ui_manager.gd
class_name DebugUIManager
extends BaseUIListener

var debug_logs_enabled = true

func _ready():
    super._ready()

# Log all events when in debug mode
func _notification(what):
    if what == NOTIFICATION_POSTINITIALIZE:
        # Override default methods to intercept all events
        for event_name in GameEvents.get_script().get_script_property_list():
            if event_name["type"] == TYPE_STRING:
                var event_value = GameEvents.get(event_name["name"])
                self.set("on_" + event_value, Callable(self, "_log_event").bind(event_value))

func _log_event(event_data, event_name):
    if debug_logs_enabled:
        print("EVENT: " + event_name + " - " + str(event_data))
```

### 6. Enhance Event Bus with Debugging

Add debugging capabilities to the EventBus:

```gdscript
# Modified: scripts/core/event_bus.gd
class_name EventBus
extends Node

# Add debug properties
var debug_mode = false
var debug_event_history = []
var max_history_size = 50

# Modified emit_event to include debugging
func emit_event(event_name: String, args = null) -> void:
    if debug_mode:
        _log_event(event_name, args)
        
    # ...existing code...

func _log_event(event_name, args):
    var log_entry = {
        "timestamp": Time.get_unix_time_from_system(),
        "event": event_name,
        "args": args
    }
    
    debug_event_history.append(log_entry)
    if debug_event_history.size() > max_history_size:
        debug_event_history.pop_front()
    
    print("EventBus: " + event_name + " - " + str(args))

# Get event history for debugging
func get_event_history():
    return debug_event_history
```

## Files to Modify

1. **New: scripts/ui/base_ui_listener.gd**:
   - Base class for all UI components that listen to events

2. **Modified: scripts/ui/base_ui_manager.gd**:
   - Update to extend BaseUIListener
   - Add event handlers for common UI events

3. **Modified: scripts/ui/base_ui_manager.gd**:
   - Enhance event delegation to child managers
   - Add safety mechanisms for missing components

4. **Modified: scripts/ui/player_ui_manager.gd**:
   - Update to extend BaseUIListener
   - Add event handlers specific to player UI

5. **Modified: scripts/ui/phase_ui_manager.gd**:
   - Update to extend BaseUIListener
   - Add event handlers specific to game phases

6. **Modified: scripts/ui/ai_ui_manager.gd**:
   - Update to extend BaseUIListener
   - Add event handlers for AI actions

7. **New: scripts/ui/debug_ui_manager.gd**:
   - Add debugging support for UI events

8. **Modified: scripts/core/event_bus.gd**:
   - Add debugging capabilities
   - Add event history tracking

## Testing Approaches

1. **End-to-End UI Flow Test**:
   - Test complete game flow through all phases
   - Verify UI updates correctly in each state

2. **Missing Component Test**:
   - Intentionally remove a UI component
   - Verify fallback mechanisms work correctly
   - Check error reporting is helpful

3. **Event Propagation Test**:
   - Emit events and verify they reach all relevant listeners
   - Check for any missed event handlers

4. **UI Performance Test**:
   - Ensure event system doesn't cause performance issues
   - Test with rapid event sequences

## Expected Outcome

After this phase, the UI system will:
- Have consistent event-based communication
- Gracefully handle missing or incomplete components
- Provide better debugging and error reporting
- Be more maintainable and extensible
- Have clearer component responsibilities

UI updates will flow through a consistent interface, and components will be more decoupled, making it easier to modify, extend, or replace individual UI elements.

## Next Phase Preview

In Phase 5, we'll address visualization and flow issues:
- Fix weapon preview rendering
- Improve phase transitions
- Enhance attack visualizations
- Address any remaining UI bugs
- Perform comprehensive testing
```