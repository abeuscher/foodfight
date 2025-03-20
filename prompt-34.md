# Prompt-34: Fixing Weapon Placement Buttons and Consolidating Control Flow

## Current Issue
After the base placement phase completes, the weapon placement buttons don't work properly. This breaks the game flow and prevents the player from continuing with the game.

## Root Causes to Investigate

### 1. Inconsistent Service Locator Usage
Many components aren't properly using the service registration pattern:
- Some are accessing objects directly instead of through the service locator
- Some are using fallbacks that bypass the intended architecture
- Service registration may be happening too late for some dependencies

### 2. Competing Phase Management
The phase manager should be the sole controller of phase transitions, but:
- Multiple components appear to be initiating phase changes
- Some components bypass the phase manager and call state changes directly
- Turn changes may be happening outside the turn manager's control

### 3. Chaotic AI Thinking Indicators
The "AI thinking" indication appears to be triggered from multiple places:
- Some calls happen in the AI controller
- Others in the BaseUIManager
- Still others in component-specific code
- These overlapping calls create race conditions and visual glitches

## Debugging Approach

1. First, audit every call to `show_ai_thinking` and `hide_ai_thinking`:
   - Which files contain these calls?
   - Are there competing or redundant calls?
   - Can we consolidate to a single mechanism?

2. Map the full flow of weapon button presses:
   - Where are the click handlers registered?
   - How is the weapon selection communicated to the placement system?
   - Where might this chain be breaking?

3. Verify service registration order:
   - When is each service registered?
   - Are there dependencies that need one service before another?
   - Is the placement UI properly connected to the services it needs?

4. Identify and eliminate redundant phase transitions:
   - The phase manager should be the sole authority
   - Any direct state changes should be removed
   - All phase transitions should use the service locator

## Specific Files to Examine

1. `base_ui_manager.gd` - Likely has competing AI thinking indicators
2. `placement_ui_manager.gd` - Contains weapon button creation and handling
3. `weapon_placement.gd` - Manages the actual placement of weapons
4. `placement_state.gd` - Controls the state during placement phases
5. `phase_manager.gd` - Should be the central controller of phase transitions
6. `game_state_machine.gd` - May have redundant state transition logic
7. `ai_controller.gd` and `ai_opponent.gd` - May trigger competing AI processes
8. `main.gd` - Current input handling and initialization sequence

## Goal
Each component should:
1. Have a single, clear responsibility
2. Access other components only through the service locator
3. Defer phase transitions to the phase manager
4. Have clear ownership of its processes (e.g., one component controlling AI thinking display)

By eliminating redundant processes and ensuring proper service usage, we should restore the weapon button functionality and make future debugging much simpler.
