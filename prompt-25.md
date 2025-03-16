# Session 25: Service Locator Pattern Implementation

## Current Issues

Our game currently uses direct references between components, leading to several problems:

1. **Tight Coupling**: Components directly reference each other, making changes risky
2. **Initialization Order Dependencies**: Components must be initialized in a specific order
3. **Testing Difficulty**: Hard to isolate components for testing
4. **Error Handling**: Null references occur when components aren't available
5. **Maintenance Challenges**: Code changes in one component can break others

```gdscript
# Current approach with direct references
func some_function():
    if game_ui_manager:  # Always checking if null
        game_ui_manager.update_phase_display("Targeting")
    else:
        print("WARNING: UI Manager not available")
```

## Service Locator Pattern Solution

We'll implement a service locator pattern in the GameManager to:

1. Act as a central registry for all game services/components
2. Provide a standardized way to access services
3. Enable better error handling and fallbacks
4. Facilitate future testing with mock services
5. Reduce direct dependencies between components

## Implementation Steps

### 1. Enhance GameManager with Service Registry

Add a services dictionary and methods to register, retrieve, and check for services:

```gdscript
# In game_manager.gd
var services = {}

func register_service(service_name: String, service_instance: Object) -> void:
    services[service_name] = service_instance
    print("Service registered: " + service_name)

func get_service(service_name: String) -> Object:
    if has_service(service_name):
        return services[service_name]
    push_warning("Service not found: " + service_name)
    return null

func has_service(service_name: String) -> bool:
    return services.has(service_name)
```

### 2. Create a Null Service Base Class

Add a null service pattern for safer service access:

```gdscript
# New file: scripts/core/null_service.gd
class_name NullService
extends RefCounted

func _get(property):
    return null
    
func _call(method, args):
    return null
```

### 3. Update Initialization Process

Modify the initialization process to register services:

```gdscript
# In game_manager.gd's initialize_components method
func initialize_components():
    # Initialize components as before
    game_board.initialize_grid()
    
    # Register components as services
    register_service("GameBoard", game_board)
    register_service("GameStateMachine", game_state_machine)
    register_service("GameUIManager", game_ui_manager)
    # ... more service registrations
```

### 4. Begin Converting Direct References

Start updating existing code to use the service locator:

```gdscript
# Before:
if game_ui_manager:
    game_ui_manager.update_phase_display("Targeting")

# After:
var ui_manager = get_service("GameUIManager")
if ui_manager:
    ui_manager.update_phase_display("Targeting")
```

### 5. Add Error Handling with Safe Defaults

Enhance get_service to provide safe defaults:

```gdscript
# Enhanced get_service with type hints and default object creation
func get_service(service_name: String, create_default: bool = false) -> Object:
    if has_service(service_name):
        return services[service_name]
    
    if create_default:
        # Create appropriate default based on service name
        match service_name:
            "GameUIManager":
                var new_service = Node.new()
                new_service.name = "GameUIManager"
                new_service.set_script(load("res://scripts/ui/game_ui_manager.gd"))
                register_service(service_name, new_service)
                return new_service
                
    push_warning("Service not found: " + service_name)
    return null
```

## Files to Modify

1. **scripts/states/game_manager.gd**:
   - Add service registry implementation
   - Update initialization to register services
   - Add helper methods for service access

2. **Create scripts/core/null_service.gd**:
   - Implement the null object pattern

3. **Update accessor methods in GameManager**:
   - Convert get_weapon_manager() etc. to use service registry

## Testing Approaches

1. **Basic Registration Test**:
   - Register test services
   - Verify they can be retrieved

2. **Missing Service Test**:
   - Request non-existent service
   - Verify warning is logged and null/safe default returned

3. **Service Replacement Test**:
   - Register a service, then replace it
   - Verify updated reference is returned

## Expected Outcome

After this phase, the GameManager will:
- Have a functioning service registry
- Provide safer component access methods
- Begin to decouple direct component references
- Handle missing services gracefully

Components won't be fully converted to using the service locator yet, but the foundation will be in place to continue this process in subsequent phases.

## Next Steps Preview

In Phase 2, we'll:
- Improve the initialization sequence to use the service locator
- Implement formal dependency checking between components
- Create a stage-based initialization process
