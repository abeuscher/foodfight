# Phase Management System Refactoring Brief (prompt-32.md)

## Problem Statement

The Food Fight game suffers from inconsistent phase transitions due to multiple components attempting to manage game phases independently. This results in:

1. Race conditions where the AI base placement completes after the weapon placement phase already begins
2. Non-functional weapon placement buttons despite UI correctly showing
3. Desynchronized game state and UI
4. Redundant and conflicting phase management code across multiple files

## Current Implementation Issues

- **Distributed Responsibility**: Phase management logic is scattered across:
  - game_state_machine.gd (main controller)
  - phase_ui_manager.gd (visual system)
  - turn_manager.gd (player turn management)
  - player_manager.gd (player state)

- **Event Ordering Problems**: Log analysis shows AI base placement is finalized after weapon placement phase begins, indicating timing issues in phase transitions

- **UI/State Desynchronization**: Weapon buttons are created correctly but non-functional, suggesting state inconsistencies

- **Excessive Logging**: Debug output is overwhelming, making issue diagnosis difficult

## Proposed Solution

Create a dedicated `phase_manager.gd` in the states subfolder to:

1. Centralize all phase transition logic in one place
2. Remove phase management code from other components
3. Establish clear ownership of the phase state
4. Ensure proper sequencing of transitions and events

## Implementation Guidelines

1. **Centralize State Management**:
   - Create PhaseManager class with clear phase transition methods
   - Ensure transitions happen atomically and in the correct sequence
   - Ensure AI actions complete before phase transitions occur

2. **Event System**:
   - Implement proper event emission sequencing
   - Ensure event subscribers receive notifications in the correct order
   - Use explicit state transitions rather than relying on event propagation

3. **UI Coordination**:
   - Coordinate UI updates only after state changes are complete
   - Ensure weapon buttons are properly connected and functional

4. **Logging Improvements**:
   - Implement log levels to reduce console output
   - Add targeted diagnostic logging for phase transitions

## Components to Modify

1. **game_state_machine.gd**: Remove direct phase transition logic, delegate to phase_manager
2. **phase_ui_manager.gd**: Focus only on UI updates, not state management
3. **turn_manager.gd**: Restrict to player turn logic only
4. **weapon_placement.gd**: Ensure preview and placement systems are responsive
5. **placement_state.gd**: Fix button connections using direct binding

## Expected Outcome

A robust phase management system with:
- Clear ownership of phase transitions
- Properly sequenced events
- Synchronized UI and game state
- Functional weapon placement during the weapon placement phase
- Readable and targeted logging

Implement this as a complete refactoring of the phase transition system with the new phase_manager.gd as the authoritative source for all phase-related operations.