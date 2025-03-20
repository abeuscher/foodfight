# Prompt 31: Service Singleton Refactoring - Comprehensive Plan

## Goal
Refactor the Food Fight game to properly implement the service singleton pattern, eliminate duplicate service instances, fix the recursive event loop, and ensure correct phase transitions.

## Current Issues

1. **Multiple Service Instances**: Both `service_initializer.gd` and `recovery_helper.gd` create redundant `PhaseUIManager` instances
2. **Recursive Event Loop**: Causes stack overflow when UI components update each other in cycles
3. **Inconsistent Service Access**: Unclear which component owns service creation responsibility
4. **Excessive Defensive Programming**: Too many redundant checks and debug statements
5. **Phase Transition Errors**: Game doesn't properly transition from base placement to weapon placement

## Refactoring Approach

This refactoring will:
1. Establish a clear ownership model for services
2. Fix the event recursion issues
3. Clean up initialization code
4. Consolidate duplicate functionality
5. Establish clear guidelines for future development

## Files to Modify

### 1. Service Management

#### a. `scripts/states/game_manager.gd`
- Enhance the `register_service` method to properly handle service upgrades
- Add clear rules for when to replace existing services
- Implement a unified service access API

#### b. `scripts/service_initializer.gd`
- Make it check for existing services in BaseUIManager before creating new ones
- Remove redundant debug output
- Make it the authoritative source for service initialization

#### c. `scripts/recovery_helper.gd`
- Either remove it completely, or
- Turn it into a diagnostic-only tool that reports issues without creating new services

### 2. Event System Fixes

#### a. `scripts/ui/phase_ui_manager.gd`
- Remove the recursive event emission in `on_state_changed`
- Implement proper state tracking to avoid redundant updates
- Add clear recursion guards for all event handlers

#### b. `scripts/ui/base_ui_manager.gd`
- Fix the recursion tracking system for `_safe_ui_call`
- Implement proper delegation pattern for UI update requests
- Remove cyclical update paths

#### c. `scripts/core/event_bus.gd`
- Add optional cycle detection for development
- Add method to dump event listener graph

### 3. UI Management

#### a. `scripts/ui/base_ui_manager.gd`
- Make it the single source of truth for UI managers
- Add proper getter method for `phase_ui_manager`
- Fix initialization sequence with clear stages

#### b. Create new file: `scripts/core/service_registry.gd`
- Implement a centralized service registry
- Add validation for required methods
- Add dependency tracking for services

### 4. Documentation and Tests

#### a. Create new file: `scripts/tests/service_test.gd`
- Add test methods to verify service initialization
- Verify no duplicate services exist
- Test event flow doesn't contain cycles

#### b. Create new file: `docs/architecture.md`
- Document the service pattern and event system
- Provide examples of correct usage
- Establish clear ownership boundaries

## Implementation Plan

Follow this sequence to refactoring the system:

### Phase 1: Break Circular References (30 min)
1. Fix `phase_ui_manager.gd` - remove the UI_UPDATE_REQUIRED event emission in `on_state_changed`
2. Add proper recursion guards to all event handlers in `phase_ui_manager.gd`
3. Update `base_ui_manager.gd` to use class-level recursion tracking
4. Test for stack overflow issues after these changes

### Phase 2: Establish Service Ownership (30 min)
1. Create `service_registry.gd` with proper service validation
2. Update `game_manager.gd` to use the new registry pattern
3. Add `get_phase_ui_manager()` method to `base_ui_manager.gd`
4. Fix registration of `PhaseUIManager` in `base_ui_manager.gd`

### Phase 3: Fix Service Creation (30 min)
1. Update `service_initializer.gd` to check for existing managers before creating new ones
2. Modify `recovery_helper.gd` to use existing services or convert it to diagnostic-only
3. Fix the initialization sequence in `base_ui_manager.gd`

### Phase 4: Clean Up Redundancy (30 min)
1. Remove duplicate debug output throughout the codebase
2. Consolidate event handling code in managers
3. Clean up `recursion_guards` implementation
4. Add clear documentation in key files

### Phase 5: Test Progression (30 min)
1. Test initialization sequence
2. Test phase transitions (base placement → weapon placement)
3. Verify no stack overflow occurs
4. Check that all UI components update properly

## Success Criteria

1. Game progresses from base placement to weapon placement phase
2. No stack overflow errors occur during phase transitions
3. Only a single instance of each service exists
4. Debug output is clear and minimal
5. Event system properly updates UI without recursion

## Fallback Plan

If the refactoring cannot be completed in one session:

1. Focus only on fixing the stack overflow issue by removing the circular event dependency
2. Add temporary logging to track service creation and usage
3. Document the remaining issues for the next session

## Future Improvements

After this refactoring:

1. Consider replacing the global service locator with proper dependency injection
2. Implement automated tests for service integrity
3. Replace event bus with a more type-safe implementation
4. Simplify the manager hierarchy further

This plan should allow us to complete the refactoring in a single focused session while properly addressing the root causes of the current issues.