# FoodFight Project Progress Update

## Game Concept
* A 2-player turn-based strategy game (with plans for player vs. computer)
* Grid-based board featuring two islands separated by water
* Food-themed weapons and defenses (ice cream catapults, cream puff bombs, etc.)
* Non-violent, lighthearted approach to combat
* Turn structure: placement phase → simultaneous attack phase → scoring
* Win condition: opponent loses ability to attack

## Current Implementation Progress
* **Start Screen**: Players can enter names and start the game
* **Game Board**: 22×12 grid with two 10×10 islands separated by water
* **Weapon System**: Defined various food-themed weapons with different properties
* **Placement Phase**: Players can select and place weapons on their islands
* **End Placement Button**: UI element added to allow players to manually end their placement phase
* **State Machine**: Game states (setup, placement, attack, resolution) implemented with transitions
* **UI Framework**: Top bar with player info and bottom bar for weapon selection
* **Resource System**: Players have limited resources for placing weapons
* **Visual Feedback**: Preview shows valid/invalid placements with color coding

## Directory Structure

```
FoodFight/
├── .godot/              # Godot configuration files
├── assets/              # For graphics, sounds, etc. (empty for now)
├── resources/           
│   └── food_theme.tres  # Game-wide UI theme with food-themed styling
├── scenes/ 
│   ├── game_board.tscn  # The game board scene
│   ├── main.tscn        # The main game scene with UI elements
│   └── start_screen.tscn # Player name input screen
└── scripts/
    ├── game_board/
    │   ├── board_core.gd      # Core grid representation and drawing
    │   ├── cell_manager.gd    # Cell state handling
    │   └── visual_manager.gd  # Visual representation of grid objects
    ├── states/
    │   ├── game_state_machine.gd # State transitions and game flow
    │   ├── placement_state.gd    # Placement phase logic
    │   └── attack_state.gd       # Attack phase logic (initial implementation)
    ├── weapons/
    │   ├── weapon_types.gd       # Weapon definitions
    │   ├── weapon_placement.gd   # Placement logic
    │   └── weapon_visualization.gd # Visual representation of weapons
    ├── game_data.gd     # Singleton for game-wide data
    ├── main.gd          # Script for main scene management
    └── start_screen.gd  # Script for start screen
```

## Technical Details
* Grid system: 22×12 cells (64×64 pixels each)
* Island layout: Two 10×10 land masses with a 2-cell wide water canal between them
* Visual styling: Custom theme with food-themed colors (orange/gold buttons, teal backgrounds)
* Game state management: State machine pattern with separate scripts for each state
* Weapon system: Different weapons with varying properties (size, range, damage, cost)
* Resource system: Players have limited resources for weapon placement
* Player transition: End placement button allows players to manually end their turn

## Next Steps
The next phase of development will focus on:

1. **Completing the End Placement Button Functionality**:
   - Ensure the button correctly transitions from player 1 to player 2
   - Fix the player transition logic in the state machine
   - Add visual feedback to indicate which player's turn it is

2. **Implementing the Attack Phase**:
   - Adding UI elements for turn control
   - Implementing weapon selection for attacks
   - Visualizing weapon attack ranges
   - Allowing target selection
   - Calculating and resolving attacks
   - Managing cooldowns for weapons
   - Implementing scoring system

3. **Resolution Phase Logic**:
   - Implement win/loss conditions
   - Add rebuild phase for continuing gameplay
   - Create game end screen and statistics

This modular approach to the code structure has improved maintainability and will make it easier to add new features while keeping the code organized.

## Encountered Issues & Solutions
* **Button Visibility**: Fixed issues with the End Placement button by ensuring proper node paths and removing comments in the scene file that were causing parsing issues
* **State Machine Transitions**: Improved state machine to properly transition between players and phases
* **UI Layout**: Adjusted layout to prevent elements from overlapping or being hidden