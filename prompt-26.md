# Session 26: Initialization Sequence Improvement

## Phase 1 Recap

In Phase 1, we successfully implemented the Service Locator pattern in the GameManager:

1. Created a service registry with registration and retrieval methods
2. Implemented a NullService class for safer error handling
3. Updated component initialization to register services
4. Modified some accessor methods to use service-based access

While services can now be registered and accessed more safely, we still have issues with:

1. The rigid initialization sequence
2. Lack of formal dependency checking
3. Inconsistent error handling during startup
4. No way to recover from initialization failures

## Phase 2 Goals

In this phase, we'll implement a robust, staged initialization system that:

1. Clearly defines initialization stages
2. Validates component dependencies
3. Provides better error recovery
4. Improves diagnostic information for initialization issues

## Implementation Plan

### 1. Create an Initialization Controller

First, we'll create a dedicated controller for managing the initialization process:

```gdscript
# New file: scripts/core/initialization_controller.gd
class_name InitializationController
extends Node

signal stage_completed(stage_name)
signal all_stages_completed
signal initialization_failed(stage_name, reason)

enum Stage {
    CORE_SYSTEMS,     # Game board, player manager
    WEAPON_SYSTEMS,   # Weapon types, placement
    STATE_SYSTEMS,    # Placement, targeting, attack states
    AI_SYSTEMS,       # AI opponent and controllers
    UI_SYSTEMS,       # UI managers
    SIGNAL_BINDING    # Connect all signals
}

var current_stage = -1
var stages_completed = []
var initialization_errors = {}
var required_dependencies = {
    "GameBoard": [],
    "PlayerManager": [],
    "WeaponTypes": [],
    "WeaponPlacement": ["GameBoard", "WeaponTypes"],
    "WeaponManager": ["GameBoard"],
    "TargetingManager": ["GameBoard"],
    "PlacementState": ["WeaponTypes", "WeaponPlacement"],
    "TargetingState": ["GameBoard", "WeaponManager", "TargetingManager"],
    "AttackState": ["GameBoard", "WeaponTypes"],
    "AIOpponent": ["GameBoard", "WeaponTypes", "WeaponPlacement", "PlayerManager", "TargetingManager"],
    "GameStateMachine": ["GameBoard", "WeaponTypes", "WeaponPlacement", "TargetingState", "AttackState", "BaseUIManager", "PlayerManager"]
}

var _game_manager = null

func _init(game_manager):
    _game_manager = game_manager

func start_initialization():
    current_stage = Stage.CORE_SYSTEMS
    return process_current_stage()

func process_current_stage() -> bool:
    match current_stage:
        Stage.CORE_SYSTEMS:
            return initialize_core_systems()
        Stage.WEAPON_SYSTEMS:
            return initialize_weapon_systems()
        Stage.STATE_SYSTEMS:
            return initialize_state_systems()
        Stage.AI_SYSTEMS:
            return initialize_ai_systems()
        Stage.UI_SYSTEMS:
            return initialize_ui_systems()
        Stage.SIGNAL_BINDING:
            return connect_signals()
        _:
            push_error("Unknown initialization stage: " + str(current_stage))
            emit_signal("initialization_failed", "Unknown", "Invalid stage index")
            return false

func advance_to_next_stage() -> bool:
    var current_stage_name = Stage.keys()[current_stage]
    stages_completed.append(current_stage_name)
    emit_signal("stage_completed", current_stage_name)
    
    current_stage += 1
    if current_stage >= Stage.size():
        emit_signal("all_stages_completed")
        return true
        
    return process_current_stage()

func check_dependencies(component_name: String) -> Dictionary:
    if not required_dependencies.has(component_name):
        return { "success": true, "missing": [] }
        
    var missing = []
    for dependency in required_dependencies[component_name]:
        if not _game_manager.has_service(dependency):
            missing.append(dependency)
    
    return {
        "success": missing.size() == 0,
        "missing": missing
    }

# Stage implementation methods...
func initialize_core_systems() -> bool:
    # Initialize core systems like game_board and player_manager
    # ...detailed implementation...
    return advance_to_next_stage()

func initialize_weapon_systems() -> bool:
    # Implement weapon systems initialization
    # ...
    return advance_to_next_stage()

# ... Other stage implementations ...

func connect_signals() -> bool:
    # Connect all signals between components
    # ...
    return advance_to_next_stage()
```

### 2. Enhance GameManager with Staged Initialization

We'll update GameManager to use the new InitializationController:

```gdscript
# Modified game_manager.gd
# Add initialization controller
var initialization_controller

# Replace initialize_components with staged initialization
func initialize_game(main_node):
    # Get references to all components
    get_component_references(main_node)
    
    # Create and start initialization controller
    initialization_controller = InitializationController.new(self)
    initialization_controller.stage_completed.connect(_on_initialization_stage_completed)
    initialization_controller.initialization_failed.connect(_on_initialization_failed)
    initialization_controller.all_stages_completed.connect(_on_all_stages_completed)
    
    var init_success = initialization_controller.start_initialization()
    if not init_success:
        push_error("Game initialization failed at setup")
        return false
    
    return true

func _on_initialization_stage_completed(stage_name):
    print("Initialization stage completed: " + stage_name)
    emit_signal("component_initialized", stage_name)

func _on_initialization_failed(stage_name, reason):
    push_error("Initialization failed at stage '" + stage_name + "': " + reason)
    # Attempt recovery if possible

func _on_all_stages_completed():
    initialization_complete = true
    emit_signal("game_initialized")
```

### 3. Improve Service Retrieval Error Handling

Enhance the service accessor to create and return NullService objects:

```gdscript
# Enhanced get_service in game_manager.gd
func get_service(service_name: String, create_default: bool = false) -> Object:
    if has_service(service_name):
        return services[service_name]
    
    if create_default:
        # Create appropriate default based on service name
        match service_name:
            "BaseUIManager":
                var new_service = Node.new()
                new_service.name = "BaseUIManager"
                new_service.set_script(load("res://scripts/ui/base_ui_manager.gd"))
                register_service(service_name, new_service)
                return new_service
            # Add cases for other services as needed
                
    push_warning("Service not found: " + service_name)
    
    # Return a NullService object instead of null
    var null_service = NullService.new()
    return null_service
```

### 4. Create Component Registration Helpers

Add helper methods to simplify component registration and validation:

```gdscript
# New methods in game_manager.gd
func register_component(component_name: String, component: Object) -> bool:
    if component == null:
        push_error("Cannot register null component: " + component_name)
        return false
        
    # Check dependencies
    var dependency_check = initialization_controller.check_dependencies(component_name)
    if not dependency_check.success:
        push_error("Cannot register " + component_name + " - missing dependencies: " + str(dependency_check.missing))
        return false
    
    # Register the service
    register_service(component_name, component)
    return true

func initialize_and_register(component_name: String, component: Object, init_args: Array = []) -> bool:
    if component == null:
        push_error("Cannot initialize null component: " + component_name)
        return false
    
    # Call initialize method with args if it exists
    if component.has_method("initialize"):
        var result = component.callv("initialize", init_args)
        if result is bool and result == false:
            push_error("Failed to initialize component: " + component_name)
            return false
    
    return register_component(component_name, component)
```

## Files to Modify

1. **scripts/states/game_manager.gd**:
   - Update to use staged initialization
   - Improve service registration and retrieval
   - Add dependency validation

2. **Create scripts/core/initialization_controller.gd**:
   - Implement the staged initialization system
   - Define dependency requirements
   - Handle initialization failures

3. **scripts/core/null_service.gd**:
   - Enhance with additional commonly used methods

## Testing Approaches

1. **Stage Progression Test**:
   - Verify each initialization stage completes
   - Check correct order of initialization

2. **Dependency Validation Test**:
   - Deliberately remove a dependency
   - Verify appropriate error handling

3. **Recovery Test**:
   - Simulate initialization failure
   - Test recovery mechanisms

4. **Service Null Safety Test**:
   - Request non-existent services
   - Verify NullService is returned and prevents crashes

## Expected Outcome

After this phase, the initialization sequence will be:
- More robust with clear stages
- Self-validating through dependency checks
- Better at handling failures
- More informative with detailed error reporting

The improved initialization will provide a solid foundation for the event system implementation in Phase 3.

## Next Phase Preview

In Phase 3, we'll implement an event-based communication system:
- Create a central event bus
- Define standard events for UI updates
- Convert direct method calls to event-based communications
- Implement event handlers in UI components
