# Food Fight Game - Coding Guidelines

If you can provide me, the user, with a global find/replace string to fix an issue of renaming, this will be more accurate and save processing time. Consider as an option when a problem fits that description.

## Service Locator Pattern

1. **Single Creation Point**: Each service should be created EXACTLY ONCE and in a well-defined place.
   ```gdscript
   # GOOD: Clear ownership of service creation
   func initialize_game():
       create_and_register_base_ui_manager()
       create_and_register_player_manager()
   
   # BAD: Multiple components trying to create the same service
   if !get_service("UIManager"): create_ui_manager() # Don't do this everywhere!
   ```

2. **Service Registration Validation**: Before registering a service, verify it has the required methods.
   ```gdscript
   # Register only if the service has required method
   if new_service.has_method("required_method"):
       register_service("ServiceName", new_service)
   ```

3. **Service Upgrade Guidelines**: Only replace an existing service if the new one is demonstrably better.
   ```gdscript
   # Only upgrade if new service has methods the old one doesn't
   if !existing_service.has_method("critical_method") and new_service.has_method("critical_method"):
       services[name] = new_service
   ```

## Event System

1. **One-Way Event Flow**: Events should flow in ONE direction only to prevent cycles.
   ```gdscript
   # GOOD: Clear event flow
   # Component A emits events that Component B listens to
   # Component B emits different events that Component C listens to
   
   # BAD: Cyclical event flow
   # A emits event X, B listens to X and emits Y, A listens to Y and emits X again
   ```

2. **Event Handler Safety**: Always implement recursion guards in event handlers.
   ```gdscript
   var _handling_event = false
   
   func on_some_event(data):
       if _handling_event:
           return
           
       _handling_event = true
       # Handle event...
       _handling_event = false
   ```

3. **Event Naming Conventions**: Use consistent naming for events and handlers.
   ```gdscript
   # Event constants
   const PLAYER_CHANGED = "player_changed"
   
   # Matching handler methods
   func on_player_changed(data):
       # handle event
   ```

## Initialization Sequence

1. **Explicit Dependency Order**: Initialize components in a specific order based on dependencies.
   ```gdscript
   # 1. Core systems (no dependencies)
   # 2. Services depending only on core systems
   # 3. Services with complex dependencies
   ```

2. **Signal Connection After Initialization**: Connect signals only after all components are initialized.
   ```gdscript
   # Initialize all components first
   init_component_a()
   init_component_b()
   
   # Then connect signals
   connect_all_signals()
   ```

3. **Initialization Completion Signals**: Use signals to indicate when initialization is complete.
   ```gdscript
   signal initialization_completed
   
   func initialize():
       # Do initialization
       emit_signal("initialization_completed")
   ```

## Recursion Prevention

1. **Class-Level Guards**: Use class-level variables to track active method calls.
   ```gdscript
   var _active_methods = {}
   
   func some_method():
       if _active_methods.get("some_method", false):
           return
       
       _active_methods["some_method"] = true
       # Method implementation
       _active_methods["some_method"] = false
   ```

2. **State Tracking**: Track previous states to avoid redundant updates.
   ```gdscript
   var _last_state = -1
   var _last_player = -1
   
   func update_ui(state, player):
       if state == _last_state and player == _last_player:
           return
           
       _last_state = state
       _last_player = player
       # Update UI
   ```

3. **Limited Event Chain Length**: Design event chains with limited depth.
   ```gdscript
   # GOOD: A → B → C (end)
   # BAD: A → B → C → D → A (cycle)
   ```

## Defensive Programming

1. **Check Without Bloating**: Validate but don't excessively check everything.
   ```gdscript
   # GOOD: Check critical conditions
   if !is_initialized:
       return
       
   # BAD: Excessive nested checks
   if thing and thing.has_method("x") and thing.get_parent() and thing.get_parent().has_node("y"):
       # This is hard to read and maintain
   ```

2. **Meaningful Debug Output**: Provide contextual debug messages at appropriate levels.
   ```gdscript
   # GOOD: Clear context with moderate detail
   print("UIManager: Failed to update phase display - missing label reference")
   
   # BAD: Excessive noise
   print("DEBUG: Entering function")
   print("DEBUG: Checking variable x")
   print("DEBUG: x = " + str(x))
   ```

3. **Fail Early and Clearly**: If a critical condition fails, report it immediately.
   ```gdscript
   # GOOD: Early return with clear message
   if !dependency:
       push_error("Missing required dependency")
       return false
   
   # BAD: Continue with null checks everywhere
   if dependency and dependency.has_method("do_thing"):
       dependency.do_thing()
   else:
       # Silently fail
   ```

## Testing and Debugging

1. **State Visibility**: Make internal state visible for debugging.
   ```gdscript
   # Add debug-friendly property access
   func get_debug_info():
       return {
           "initialized": is_initialized,
           "active_services": services.keys(),
           "current_state": current_state
       }
   ```

2. **Clear Error Messages**: Use specific error messages that guide troubleshooting.
   ```gdscript
   # GOOD
   push_error("Failed to initialize UIManager - missing PhaseUI reference")
   
   # BAD
   push_error("Initialization error")
   ```

3. **Consistent Test Points**: Add consistent ways to verify system state.
   ```gdscript
   # Implement verification methods
   func verify_services():
       var issues = []
       for service_name in required_services:
           if !has_service(service_name):
               issues.append("Missing service: " + service_name)
       return issues
   ```

By following these guidelines, we can maintain a cleaner, more robust codebase with fewer subtle bugs and easier debugging.