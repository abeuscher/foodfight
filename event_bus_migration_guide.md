# EventBus Migration Guide

## Communication Pattern Rules

1. **ONLY USE EventBus for cross-component communication**
   - Component A → EventBus → Component B

2. **ALLOWED Direct Method Calls**:
   - Parent → Child (direct hierarchy only)
   - Within the same component
   - Callbacks registered with EventBus

3. **BANNED Communication Patterns**:
   - Godot signals between non-hierarchical components
   - GameManager direct property access
   - Child → Parent method calls
   - Direct reference to remote components

## Migration Process

For each file:
1. Delete all custom signals
2. Replace all emit_signal calls with EventBus.emit_event
3. Replace all signal connections with EventBus.subscribe
4. Remove direct references to other components except parents/children

## Standard Event Types

```gdscript
# Player events
const PLAYER_CHANGED = "PLAYER_CHANGED"
const PLAYER_TURN_STARTED = "PLAYER_TURN_STARTED"

# Phase events
const PHASE_CHANGED = "PHASE_CHANGED"
const PHASE_STARTED = "PHASE_STARTED"
const PHASE_ACTION_COMPLETED = "PHASE_ACTION_COMPLETED"

# AI events
const AI_THINKING_STARTED = "AI_THINKING_STARTED"
const AI_THINKING_COMPLETED = "AI_THINKING_COMPLETED"
```

## Standard Event Handler Format

```gdscript
# Always use this naming convention
func on_EVENT_NAME(event_data):
    # Always include recursion guard
    if _active_method_calls.get("on_EVENT_NAME", false):
        return
    _active_method_calls["on_EVENT_NAME"] = true
    
    # Handle event
    
    _active_method_calls["on_EVENT_NAME"] = false
```
