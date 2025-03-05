# FoodFight Project Progress Update

## Game Concept
- A 2-player turn-based strategy game (with plans for player vs. computer)
- Grid-based board featuring two islands separated by water
- Food-themed weapons and defenses (ice cream catapults, cream puff bombs, etc.)
- Non-violent, lighthearted approach to combat
- Turn structure: placement phase → simultaneous attack phase → scoring
- Win condition: opponent loses ability to attack

## Current Implementation Progress
- **Start Screen**: Players can enter names and start the game
- **Game Board**: 22×12 grid with two 10×10 islands separated by water
- **Weapon System**: Defined various food-themed weapons with different properties
- **Placement Phase**: Players can select and place weapons on their islands
- **State Machine**: Basic game states (setup, placement, attack, resolution) implemented
- **UI Framework**: Top bar with player info and bottom bar for weapon selection
- **Resource System**: Players have limited resources for placing weapons
- **Visual Feedback**: Preview shows valid/invalid placements with color coding

## Refactored Directory Structure
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
    │   ├── game_state_machine.gd # State transitions
    │   ├── placement_state.gd    # Placement phase logic
    │   └── attack_state.gd       # Attack phase logic (stub)
    ├── weapons/
    │   ├── weapon_types.gd       # Weapon definitions
    │   ├── weapon_placement.gd   # Placement logic
    │   └── weapon_visualization.gd # Visual representation of weapons
    ├── game_data.gd     # Singleton for game-wide data
    ├── main.gd          # Script for game state management
    └── start_screen.gd  # Script for start screen
```

## Technical Details
- Grid system: 22×12 cells (64×64 pixels each)
- Island layout: Two 10×10 land masses with a 2-cell wide water canal between them
- Visual styling: Custom theme with food-themed colors (orange/gold buttons, teal backgrounds)
- Game state management: State machine pattern with separate scripts for each state
- Weapon system: Different weapons with varying properties (size, range, damage, cost)
- Resource system: Players have limited resources for weapon placement

## Next Steps
The next phase of development will focus on implementing the turn-based attack phase:

1. Adding UI elements for turn control (buttons for ending turns, etc.)
2. Implementing weapon selection for attacks
3. Visualizing weapon attack ranges
4. Allowing target selection
5. Calculating and resolving attacks
6. Managing cooldowns for weapons
7. Implementing scoring system

This modular approach to the code structure has improved maintainability and will make it easier to add the attack phase functionality while keeping the code organized.