# FoodFight Project: Attack Phase Implementation

I'm working on a 2-player turn-based strategy game called FoodFight, built in Godot. The game features a grid-based board with two islands where players place food-themed weapons. I've implemented the placement phase and now need help implementing the basic attack phase mechanics.

## Current Implementation:
- Grid-based game board with two islands separated by water
- Placement phase where players can position weapons on their islands
- State machine to handle game flow (setup → placement → attack → resolution)
- UI with top bar showing player info and bottom bar for actions

## Attack Phase Goals for this Session:
1. Implement a basic targeting system for weapons
2. Create two weapon types: one with direct damage and one with splash damage
3. Implement the 10-tick combat resolution system
4. Allow weapons to attack based on their cooldown values
5. Calculate and apply damage to targeted weapons/structures

## Weapon System Specifications:
- Each attack phase consists of 10 "ticks"
- Weapons follow pattern: cooldown → attack → cooldown
- Damage calculation: (Damage / Splash Radius) * Target's Footprint Size
- Victory condition: A player loses when they cannot build new weapons

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

## Important Instructions for Implementation:
1. **DO NOT** try to rewrite files that you haven't seen yet. Always ask to see the current version of a file before suggesting changes.
2. **DO NOT** guess what might be in a file - ask to see it first.
3. Only provide partial code snippets if they are under 5 lines long and only need to be pasted into one specific location. For anything more complex, provide the complete file.
4. Focus specifically on implementing the targeting system and attack resolution for two basic weapons.

I'd like to focus specifically on getting two weapons working (one direct, one splash) and implementing the targeting and attack resolution systems. By the end of this session, I want to be able to place weapons for both players, target the enemy board, and see the attack results.