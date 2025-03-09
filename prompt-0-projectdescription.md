#  FoodFight Framework and Roadmap:

## Game Modes
- Single-player: Player vs. AI opponent
- Two-player: Two human players (local)

## Fundamental Game Loop

### 1. Setup Phase
- Both islands are initialized with 3 Base structures per player
- Players receive starting resources

### 2. Resource & Build Phase
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

## AI Framework (Single-player)
- Difficulty levels affecting AI decision-making
- Strategic evaluation of player's island to determine optimal targets
- Adaptive defense placement based on player's attack patterns
- Resource management prioritizing critical structures

## Visual Feedback
- Clear indication of current game phase
- Highlighting of selected weapons and valid target areas
- Attack trajectories and impact visualization
- Damage indicators and structure health status

## Component Dependency Map

```
GameManager (Singleton)
├─ Initializes & References → GameBoard
├─ Initializes & References → GameStateMachine
├─ Initializes & References → GameUIManager
├─ Initializes & References → PlayerManager
├─ Initializes & References → PlacementState
├─ Initializes & References → TargetingState
├─ Initializes & References → AttackState
├─ Initializes & References → WeaponTypes
├─ Initializes & References → WeaponPlacement
├─ References → WeaponManager (via AttackState)
└─ References → TargetingManager (via AttackState)

Main (Scene Root)
├─ Calls → GameManager.initialize_game()
├─ Updates UI based on → GameStateMachine.current_state
├─ Forwards Input to → TargetingState, PlacementState

GameStateMachine
├─ Depends on → GameBoard
├─ Depends on → WeaponTypes
├─ Depends on → WeaponPlacement
├─ Depends on → TargetingState
├─ Depends on → AttackState
├─ Depends on → GameUIManager
└─ Depends on → PlayerManager

PlacementState
├─ Depends on → WeaponTypes
├─ Depends on → WeaponPlacement
└─ Depends on → UI Weapon Buttons Container

TargetingState
├─ Depends on → GameBoard
├─ Depends on → WeaponManager
├─ Depends on → TargetingManager
├─ Signals to → GameStateMachine

AttackState
├─ Contains → WeaponManager
├─ Contains → TargetingManager
├─ Depends on → GameBoard
├─ Depends on → WeaponTypes
└─ Signals to → GameBoard

GameBoard
├─ Contains → CellManager
├─ Contains → VisualManager
└─ Handles → Attack Visualization

WeaponManager
└─ Depends on → GameBoard

TargetingManager
└─ Depends on → GameBoard

WeaponPlacement
├─ Depends on → GameBoard
├─ Depends on → WeaponTypes
└─ Contains → WeaponVisualization
```

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
    └── start_screen.gd
```