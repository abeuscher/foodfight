# FoodFight Project: Targeting System Implementation

## Project Overview
FoodFight is a 2-player turn-based strategy game built in Godot where players place food-themed weapons on their respective islands and attack the enemy's forces. The game has a grid-based board with two islands separated by water.

## Game Modes
- Single-player: Player vs. AI opponent
- Two-player: Two human players (local)

## Fundamental Game Loop

### 1. Setup Phase
- Both islands are initialized with 3 Base structures per player
- Players receive starting resources

### 2. Resource & Build Phase (Placement Phase)
- Players collect resources based on their production structures
- Players place new structures or upgrade existing ones on their island
- Building options limited by available resources and grid space
- AI makes strategic decisions in single-player mode

### 3. Targeting Phase
- Player selects up to 3 offensive weapons to deploy
- Player assigns targets on the enemy island
- Targeting interface shows weapon range, damage patterns, and valid cells
- In two-player mode, players take turns planning attacks
- In single-player mode, AI determines its targets while player is targeting

### 4. Attack Resolution Phase
- Attacks are visualized with appropriate effects
- Defensive structures attempt to intercept incoming attacks
- Damage is calculated and applied to structures
- Destroyed structures are removed from the board

### 5. Turn Transition
- Victory check: If all enemy Bases are destroyed, current player wins
- Otherwise, return to Resource & Build Phase

## Core Mechanics

### Structure Categories
- **Bases**: Primary objective structures (game ends when all are destroyed)
- **Offensive**: Various attack options with different ranges, damage patterns, and costs
- **Defensive**: Intercept incoming attacks or damage attacking units
- **Production**: Generate resources each turn
- **Support**: Enhance effectiveness of other structures

### Resource System
- **Building Resources**: For constructing and upgrading structures
- **Energy**: Required for launching attacks and activating special abilities

### Targeting System
- Line-of-sight calculations for valid targets
- Range limitations based on weapon type
- Preview damage areas before confirming attack
- Limited attacks per turn (maximum 3)

### Defensive System
- Chance-based interception system
- Interception chance affected by defensive upgrades
- Strategic placement of defenses to protect critical structures

### AI Framework (Single-player)
- Difficulty levels affecting AI decision-making
- Strategic evaluation of player's island to determine optimal targets
- Adaptive defense placement based on player's attack patterns
- Resource management prioritizing critical structures

### Visual Feedback
- Clear indication of current game phase
- Highlighting of selected weapons and valid target areas
- Attack trajectories and impact visualization
- Damage indicators and structure health status

## Project Progress

### Completed So Far:
1. **Core Game Structure**: Implemented state machine, game board, resource systems
2. **Placement Phase**: Working correctly - players can place weapons on their island
3. **Basic Framework**: Game state transitions, UI components, input handling
4. **New Targeting Phase**: Added between placement and attack phases
   - Targeting buttons appear but interaction isn't working properly
   - Visual indicators for targeting are partially implemented but need improvement

### Current Issues:
1. Player turn order in targeting phase starts with Player 2 instead of Player 1
2. Targeting visualization shows some elements (green square, blue circle) but they aren't interactive
3. The targeting mode isn't clearly communicating to the player what's happening
4. No visual feedback when a weapon is successfully targeted

## Directory Structure
```
FoodFight/
├── assets/
│   └── icon.svg
├── resources/
│   └── food_theme.tres
├── scenes/
│   ├── game_board.tscn
│   ├── main.tscn
│   └── start_screen.tscn
└── scripts/
    ├── game_board/
    │   ├── board_core.gd
    │   ├── cell_manager.gd
    │   └── visual_manager.gd
    ├── states/
    │   ├── attack_state.gd
    │   ├── game_manager.gd
    │   ├── game_state_machine.gd
    │   ├── game_ui_manager.gd
    │   ├── placement_state.gd
    │   ├── player_manager.gd
    │   ├── targeting_manager.gd
    │   ├── targeting_state.gd
    │   └── weapon_manager.gd
    ├── weapons/
    │   ├── weapon_attack.gd
    │   ├── weapon_placement.gd
    │   ├── weapon_types.gd
    │   └── weapon_visualization.gd
    ├── game_data.gd
    ├── main.gd
    ├── start_screen.gd
    └── targeting_visualization.gd
```

## Next Steps

The key task is to improve the targeting phase to make it more intuitive and interactive. Specifically:

1. **Fix Player Turn Order**: Ensure Player 1 goes first in the targeting phase
2. **Improve Targeting Visualization**:
   - When a weapon is selected, clearly show its range
   - When the mouse moves over valid targets, highlight the cell
   - Show a visual indicator for the targeting mode (cursor change or other indicator)
   - Provide clear feedback when a target is selected

3. **Enhance Targeting UI**:
   - Update weapon buttons to show which weapons have been targeted
   - Provide clear UI feedback for targeting actions

## Technical Approach

To fix these issues, we need to focus on:

1. **Targeting State Logic**:
   - Review the player turn order in the targeting_state.gd
   - Ensure current_player_idx is properly initialized and updated

2. **Targeting Visualization**:
   - Enhance targeting_visualization.gd to properly show:
     - Weapon range (circle or highlighted cells)
     - Target selection indicators
     - Visual feedback for successful targeting

3. **Input Handling**:
   - Improve the coordination between targeting_manager and targeting_state
   - Ensure cursor position is properly translated to grid coordinates
   - Handle click events to select targets

4. **UI Feedback**:
   - Update the UI to clearly show which weapons have been targeted
   - Add visual cues for the current targeting state

The most complex part is getting the targeting visualization to work properly with the mouse input and grid coordinates. This will require careful coordination between targeting_manager.gd, targeting_visualization.gd, and targeting_state.gd.

When implemented correctly, the player should be able to select a weapon, see valid target areas, click to select a target, and get clear feedback about their selection before moving to the next weapon or ending their turn.