# Prompt-29: Visualization and Flow Fixes

## Phase 4 Recap

In Phase 4, we successfully implemented an event-based communication system for the UI components:

1. Created a `BaseUIListener` class that all UI managers extend to easily handle events
2. Updated UI managers to properly use the event system
3. Completed the decoupling of UI components
4. Implemented safety mechanisms for missing components
5. Added debugging tools for UI events

These improvements have created a more maintainable, decoupled architecture, but we're still experiencing issues with phase transitions and visualizations. The gameplay flow sometimes breaks after the base placement phase, and there are inconsistencies in the visual feedback for weapon placements and targeting.

## Phase 5 Goals

In this phase, we will:

1. Fix weapon preview rendering issues
2. Improve phase transitions and game flow
3. Enhance attack visualizations
4. Improve AI turn reliability
5. Implement comprehensive testing

## Implementation Plan

### 1. Fix Weapon Preview Rendering

First, we need to address the issues with weapon previews during placement:

```gdscript
# Modifications to scripts/weapons/weapon_visualization.gd
class_name WeaponVisualization
extends Node2D

signal preview_updated(is_valid)

# Properties for tracking the current preview state
var current_preview = null
var current_weapon_type = null
var is_valid_placement = false
var grid_size = 32 # Default grid size

# Materials for valid/invalid states
var invalid_material = null
var valid_material = null

func _ready():
    # Create shader materials for displaying valid/invalid states
    _initialize_materials()
    
    # Connect to event bus to receive global events
    if Engine.has_singleton("GameManager"):
        var game_manager = Engine.get_singleton("GameManager")
        var event_bus = game_manager.get_service("EventBus")
        if event_bus:
            # Subscribe to events that might affect visualization
            event_bus.subscribe(GameEvents.PLACEMENT_CANCELLED, self)
            event_bus.subscribe(GameEvents.PHASE_CHANGED, self)

# Initialize shader materials for valid/invalid placement indicators
func _initialize_materials():
    # Create material for invalid placement (red tint)
    invalid_material = ShaderMaterial.new()
    var invalid_shader = load("res://shaders/invalid_placement.gdshader")
    if invalid_shader:
        invalid_material.shader = invalid_shader
        invalid_material.set_shader_parameter("outline_color", Color(1, 0, 0, 0.8))
    else:
        # Fallback if shader not found
        invalid_material = null
    
    # Create material for valid placement (green tint)
    valid_material = ShaderMaterial.new()
    var valid_shader = load("res://shaders/valid_placement.gdshader")
    if valid_shader:
        valid_material.shader = valid_shader
        valid_material.set_shader_parameter("outline_color", Color(0, 1, 0, 0.8))
    else:
        # Fallback if shader not found
        valid_material = null

# Update the weapon preview at the specified grid position
func update_preview(weapon_type, grid_position, is_valid):
    # Check if weapon type has changed
    if current_weapon_type != weapon_type:
        clear_preview()
        current_weapon_type = weapon_type
        current_preview = _create_weapon_preview(weapon_type)
        add_child(current_preview)
    
    # Update position and visual state
    if current_preview:
        current_preview.position = Vector2(grid_position.x * grid_size, grid_position.y * grid_size)
        
        # Update visualization based on validity
        is_valid_placement = is_valid
        _update_preview_appearance(is_valid)
        
        # Emit signal for other components to react
        emit_signal("preview_updated", is_valid)

# Clear any existing preview
func clear_preview():
    if current_preview:
        current_preview.queue_free()
        current_preview = null
    current_weapon_type = null
    is_valid_placement = false

# Create visual representation of the weapon
func _create_weapon_preview(weapon_type):
    var preview = Node2D.new()
    preview.name = "WeaponPreview"
    
    # Create sprite based on weapon type
    var sprite = Sprite2D.new()
    sprite.name = "Sprite2D"
    var texture = _get_weapon_texture(weapon_type)
    if texture:
        sprite.texture = texture
    
    # Make semi-transparent initially
    sprite.modulate = Color(1, 1, 1, 0.7)
    preview.add_child(sprite)
    
    return preview

# Update the appearance based on placement validity
func _update_preview_appearance(is_valid):
    if not current_preview:
        return
        
    var sprite = current_preview.get_node_or_null("Sprite2D")
    if not sprite:
        return
    
    # Apply appropriate visual treatment based on validity
    if is_valid:
        sprite.material = valid_material
        sprite.modulate = Color(1, 1, 1, 0.7)
    else:
        sprite.material = invalid_material
        sprite.modulate = Color(1, 0.5, 0.5, 0.7)

# Get the appropriate texture for the weapon type
func _get_weapon_texture(weapon_type):
    # This should be implemented based on your weapon types
    # For now, return a placeholder texture
    var texture_path = "res://textures/weapons/" + str(weapon_type) + ".png"
    return load(texture_path)

# Event handlers
func on_placement_cancelled(_event_data):
    clear_preview()
    
func on_phase_changed(_event_data):
    clear_preview()
```

### 2. Fixing Phase Transitions

One of the main issues is that after the base placement phase, sometimes the game doesn't properly transition to the next phase. Let's ensure the game state machine properly handles transitions and emits the right events:

```gdscript
# Modifications to scripts/states/game_state_machine.gd

# Add this method to ensure consistent state transitions
func ensure_phase_transition(from_state, to_state, player_index = null):
    if current_state == from_state:
        var success = change_state(to_state, player_index)
        return success
    else:
        push_warning("GameStateMachine: Cannot transition from " + 
                    str(GameState.keys()[from_state]) + " to " + 
                    str(GameState.keys()[to_state]) + 
                    " because current state is " + 
                    str(GameState.keys()[current_state]))
        return false

# Make change_state more robust
func change_state(new_state, player_index = null):
    if !is_initialized:
        push_error("GameStateMachine not initialized")
        return false

    # If player index not specified, keep the current player
    var updated_player_index = player_index if player_index != null else current_player_index
    
    # Handle specific pre-transition logic
    match current_state:
        GameState.BASE_PLACEMENT:
            if new_state == GameState.WEAPON_PLACEMENT:
                # Validate that bases are actually placed
                if !_validate_base_placement(updated_player_index):
                    push_warning("Cannot transition: Base placement incomplete")
                    return false
        
        GameState.WEAPON_PLACEMENT:
            if new_state == GameState.TARGETING:
                # Validate that required weapons are placed
                if !_validate_weapon_placement(updated_player_index):
                    push_warning("Cannot transition: Weapon placement incomplete")
                    return false
    
    # Store previous state for reference
    var previous_state = current_state
    
    # Update state and player index
    current_state = new_state
    current_player_index = updated_player_index
    
    # Log the state change
    print("GameStateMachine: " + GameState.keys()[previous_state] + 
         " -> " + GameState.keys()[current_state] + 
         " for Player " + str(current_player_index + 1))
    
    # Emit events for the state change
    if event_bus:
        event_bus.emit_event(GameEvents.STATE_CHANGED, {
            "previous_state": previous_state,
            "new_state": current_state,
            "player_index": current_player_index
        })
        
        # Also emit phase changed event with readable phase name for UI
        var phase_text = GameState.keys()[current_state].capitalize().replace("_", " ") + " Phase"
        event_bus.emit_event(GameEvents.PHASE_CHANGED, {
            "phase_text": phase_text,
            "state": current_state
        })
        
        # Emit player changed event if player index was updated
        if player_index != null:
            event_bus.emit_event(GameEvents.PLAYER_CHANGED, {
                "player_index": current_player_index
            })
    
    # Request UI update
    request_ui_update()
    
    return true

# Validate base placement before transitioning
func _validate_base_placement(player_index):
    # Implementation depends on your game's requirements
    # This is a placeholder that always returns true
    return true

# Validate weapon placement before transitioning
func _validate_weapon_placement(player_index):
    # Implementation depends on your game's requirements
    # This is a placeholder that always returns true
    return true
```

### 3. Enhancing Attack Visualizations

The attack visuals need improvement to clearly show attack paths, impacts, and outcomes:

```gdscript
# Modifications to scripts/states/attack_state.gd

# Add new visualization methods
func visualize_attack(weapon, target_position):
    # Emit event for visualization
    if event_bus:
        event_bus.emit_event(GameEvents.ATTACK_STARTED, {
            "weapon_id": weapon.id,
            "weapon_type": weapon.type,
            "source_position": weapon.position,
            "target_position": target_position
        })
    
    # Create visual attack path
    var attack_path = _create_attack_path(weapon.position, target_position)
    add_child(attack_path)
    
    # Animate the attack
    var tween = create_tween()
    tween.tween_method(func(value): _update_attack_progress(attack_path, value), 
                      0.0, 1.0, 1.0)
    tween.tween_callback(func(): _on_attack_completed(weapon, target_position, attack_path))
    
    return tween

# Create visual representation of attack path
func _create_attack_path(from_pos, to_pos):
    var path = Line2D.new()
    path.width = 3.0
    path.default_color = Color(1, 0.7, 0.2, 0.8)
    path.add_point(from_pos)
    path.add_point(from_pos) # Second point will be animated
    return path

# Update the attack visualization progress
func _update_attack_progress(path, progress):
    if path and path.get_point_count() >= 2:
        var from_pos = path.get_point_position(0)
        var to_pos = path.get_point_position(1)
        var current_pos = from_pos.lerp(to_pos, progress)
        path.set_point_position(1, current_pos)

# Handle attack completion
func _on_attack_completed(weapon, target_position, path):
    # Create impact effect
    _create_impact_effect(target_position, weapon.type)
    
    # Clean up path after short delay
    await get_tree().create_timer(0.5).timeout
    if path:
        path.queue_free()
    
    # Emit attack completed event
    if event_bus:
        event_bus.emit_event(GameEvents.ATTACK_COMPLETED, {
            "weapon_id": weapon.id,
            "target_position": target_position
        })

# Create visual impact effect
func _create_impact_effect(position, weapon_type):
    var impact = Sprite2D.new()
    impact.texture = load("res://textures/effects/impact.png")
    impact.position = position
    add_child(impact)
    
    # Scale up and fade out
    var tween = create_tween()
    tween.tween_property(impact, "scale", Vector2(2, 2), 0.3)
    tween.parallel().tween_property(impact, "modulate", Color(1, 1, 1, 0), 0.3)
    tween.tween_callback(func(): impact.queue_free())
```

### 4. Improving AI Turn Reliability

The AI opponent needs to be more reliable and provide better visual feedback:

```gdscript
# Modifications to scripts/ai/ai_controller.gd

# Enhance the AI turn handling
func execute_ai_turn():
    emit_event(GameEvents.AI_THINKING_STARTED)
    
    # Use a timer to simulate AI "thinking" and make it more visible to the player
    await get_tree().create_timer(1.0).timeout
    
    var success = false
    
    # Execute the appropriate AI behavior based on game state
    match game_state_machine.current_state:
        game_state_machine.GameState.BASE_PLACEMENT:
            success = execute_ai_base_placement()
            
        game_state_machine.GameState.WEAPON_PLACEMENT:
            success = execute_ai_weapon_placement()
            
        game_state_machine.GameState.TARGETING:
            success = execute_ai_targeting()
            
        _:
            push_warning("AI Controller: Unsupported state for AI turn: " + 
                        str(game_state_machine.GameState.keys()[game_state_machine.current_state]))
    
    # Notify when AI has finished thinking
    emit_event(GameEvents.AI_THINKING_COMPLETED)
    
    # Emit event about AI move result
    emit_event(GameEvents.AI_MOVE_EXECUTED, {
        "success": success,
        "state": game_state_machine.current_state
    })
    
    return success

# Execute AI base placement with better error handling
func execute_ai_base_placement():
    if !ai_opponent or !player_manager:
        push_error("AI Controller: Missing dependencies for base placement")
        return false
    
    print("AI Controller: Executing AI base placement")
    
    # Get valid positions for bases
    var valid_positions = ai_opponent.get_base_placement_positions()
    if valid_positions.size() < 3:
        push_warning("AI Controller: Not enough valid positions for bases")
        return false
    
    # Place the bases
    for i in range(min(3, valid_positions.size())):
        var position = valid_positions[i]
        
        # Emit event for visualization
        emit_event(GameEvents.AI_PLACEMENT_SELECTED, {
            "position": position,
            "type": "base"
        })
        
        # Short delay for visual feedback
        await get_tree().create_timer(0.3).timeout
        
        # Place the base
        var success = player_manager.place_base(1, position)
        if !success:
            push_warning("AI Controller: Failed to place base at " + str(position))
    
    # End placement phase
    await get_tree().create_timer(0.5).timeout
    return _complete_current_phase()

# Execute AI weapon placement with better error handling
func execute_ai_weapon_placement():
    if !ai_opponent or !player_manager or !weapon_types:
        push_error("AI Controller: Missing dependencies for weapon placement")
        return false
    
    print("AI Controller: Executing AI weapon placement")
    
    # Get strategic weapon placements from AI opponent
    var weapon_placements = ai_opponent.get_weapon_placements()
    if weapon_placements.size() == 0:
        push_warning("AI Controller: No weapon placements determined")
        return false
    
    # Place each weapon with visual feedback
    for placement in weapon_placements:
        var weapon_type = placement.type
        var position = placement.position
        
        # Check if we can afford this weapon
        if !player_manager.can_afford_weapon(1, weapon_type):
            continue
        
        # Emit event for visualization
        emit_event(GameEvents.AI_PLACEMENT_SELECTED, {
            "position": position,
            "type": weapon_type
        })
        
        # Short delay for visual feedback
        await get_tree().create_timer(0.3).timeout
        
        # Place the weapon
        var success = player_manager.place_weapon(1, weapon_type, position)
        if !success:
            push_warning("AI Controller: Failed to place weapon " + 
                        str(weapon_type) + " at " + str(position))
    
    # End placement phase
    await get_tree().create_timer(0.5).timeout
    return _complete_current_phase()

# Complete the current game phase and move to the next
func _complete_current_phase():
    var current_state = game_state_machine.current_state
    var next_state = current_state + 1
    
    # Ensure we stay within valid game states
    if next_state < game_state_machine.GameState.size():
        return game_state_machine.ensure_phase_transition(current_state, next_state, 0) # Back to player 1
    else:
        push_warning("AI Controller: No next state available after " + 
                    str(game_state_machine.GameState.keys()[current_state]))
        return false
```

### 5. Comprehensive Testing and Debugging

We need a mechanism to easily test all aspects of the game flow:

```gdscript
# New file: scripts/debug/game_test_harness.gd
class_name GameTestHarness
extends Node

# Reference to game components
var game_manager
var game_state_machine
var player_manager
var event_bus

# Test scenarios
var test_scenarios = {
    "full_game_flow": func(): test_full_game_flow(),
    "phase_transitions": func(): test_phase_transitions(),
    "ai_opponent": func(): test_ai_opponent(),
    "weapon_placement": func(): test_weapon_placement(),
    "attack_resolution": func(): test_attack_resolution()
}

func _ready():
    # Get references to game components
    if Engine.has_singleton("GameManager"):
        game_manager = Engine.get_singleton("GameManager")
        game_state_machine = game_manager.get_service("GameStateMachine")
        player_manager = game_manager.get_service("PlayerManager")
        event_bus = game_manager.get_service("EventBus")
        
        # Add keyboard shortcuts for testing
        # F1 = Run full game flow test
        # F2 = Test phase transitions
        # F3 = Test AI opponent
        # F4 = Test weapon placement
        # F5 = Test attack resolution
        
    print("Game Test Harness initialized")

# Test the full game flow from start to finish
func test_full_game_flow():
    print("=== TESTING FULL GAME FLOW ===")
    # Reset game to initial state
    game_manager.reset_game()
    
    # Test each phase in sequence
    await test_base_placement()
    await test_weapon_placement()
    await test_targeting()
    await test_attack_resolution()
    
    print("=== FULL GAME FLOW TEST COMPLETED ===")

# Test base placement phase
func test_base_placement():
    print("Testing base placement phase...")
    
    # Ensure we're in the correct state
    game_state_machine.change_state(game_state_machine.GameState.BASE_PLACEMENT, 0)
    
    # Place player 1 bases
    for i in range(3):
        var position = Vector2(i + 1, 1)
        player_manager.place_base(0, position)
        await get_tree().create_timer(0.3).timeout
    
    # Transition to player 2 (AI)
    game_state_machine.change_state(game_state_machine.GameState.BASE_PLACEMENT, 1)
    await get_tree().create_timer(1.0).timeout
    
    # AI controller should handle player 2 base placement automatically
    # Wait for it to complete
    await get_tree().create_timer(2.0).timeout
    
    print("Base placement phase test completed")

# Test weapon placement phase
func test_weapon_placement():
    print("Testing weapon placement phase...")
    
    # More test implementations...
```

## Files to Modify

1. **scripts/weapons/weapon_visualization.gd**:
   - Fix preview rendering and update appearance based on placement validity
   - Add visual feedback for invalid placements

2. **scripts/states/game_state_machine.gd**:
   - Enhance state transitions
   - Add validation to ensure prerequisites are met before state changes
   - Improve event emitting for better UI coordination

3. **scripts/states/attack_state.gd**:
   - Improve attack path visualization
   - Add impact effects
   - Enhance feedback for hits and misses

4. **scripts/ai/ai_controller.gd**:
   - Make AI turns more reliable
   - Add better visual feedback and timing for AI actions
   - Enhance error handling for AI actions

5. **New: scripts/debug/game_test_harness.gd**:
   - Add comprehensive testing capabilities
   - Implement test scenarios for different game aspects
   - Add keyboard shortcuts for easy testing

## Testing Approaches

1. **Manual Phase Testing**:
   - Manually test each game phase transition
   - Verify that the UI updates correctly
   - Check that the correct player is active

2. **AI Opponent Testing**:
   - Observe AI behavior through multiple game phases
   - Verify that AI actions are visible to the player
   - Ensure AI properly completes its turns

3. **Visual Effect Testing**:
   - Check weapon placement previews
   - Verify attack visualizations
   - Ensure impact effects display correctly

4. **Edge Case Testing**:
   - Test with incomplete base/weapon placements
   - Try invalid placements and attacks
   - Attempt to bypass phase requirements

## Expected Outcome

After this phase, the game should:
- Provide clear visual feedback for weapon placement
- Transition smoothly between game phases
- Display attack paths and impacts clearly
- Feature more reliable AI turns with appropriate feedback
- Be thoroughly testable through the test harness

The improvements will create a more polished and reliable gameplay experience while maintaining the decoupled, event-based architecture established in previous phases.

## Next Steps

After completing this phase, we'll conduct a comprehensive sprint review to:
1. Evaluate the success of the UI refactoring process
2. Identify any remaining issues or technical debt
3. Plan the next sprint focusing on game balance, additional features, or further polish