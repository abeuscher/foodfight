#  FoodFight Framework and Roadmap:

## Game Modes
- Single-player: Player vs. AI opponent

## Fundamental Game Loop

### 1. Setup Phase
- Both islands are initialized with 3 Base structures per player
- Players receive starting resources

### 2. Resource & Build Phase
- Players collect ingredients based on their production structures
- Players place new structures or upgrade existing ones on their island
- Building options limited by available ingredients and grid space
- AI makes strategic decisions in single-player mode

### 3. Targeting Phase
- Player selects up to 3 offensive weapons to deploy
- Player assigns targets on the enemy island
- Targeting interface shows weapon range, damage patterns, and valid cells
- AI determines its targets while player is targeting

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
- **Production**: Generate ingredients each turn
- **Support**: Enhance effectiveness of other structures

### Resource System
- **Ingredients**: For constructing and upgrading structures
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
├─ Initializes & References → AIOpponent
├─ References → WeaponManager (via AttackState)
├─ References → TargetingManager (via AttackState)
├─ References → TurnManager (via GameStateMachine)
└─ References → AIController (via GameStateMachine)

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
├─ Depends on → PlayerManager
├─ Contains → TurnManager
└─ Contains → AIController

GameUIManager
├─ Coordinates → BaseUIManager
├─ Delegates to → PlayerUIManager
├─ Delegates to → PhaseUIManager
├─ Delegates to → PlacementUIManager
├─ Delegates to → TargetingUIManager
└─ Delegates to → AIUIManager

BaseUIManager (Core UI Coordinator)
├─ Contains → PlayerUIManager
├─ Contains → PhaseUIManager
├─ Contains → PlacementUIManager
├─ Contains → TargetingUIManager
└─ Contains → AIUIManager

AIController
├─ Depends on → AIOpponent
├─ Depends on → GameStateMachine
├─ Depends on → PlayerManager
└─ Signals to → GameUIManager (via AIUIManager)

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

AIOpponent
├─ Depends on → GameBoard
├─ Depends on → WeaponTypes
├─ Depends on → WeaponPlacement
├─ Depends on → PlayerManager
└─ Depends on → TargetingManager
```

## Directory Structure

```
FoodFight/
├── assets/
│   └── icon.svg
├── resources/
│   └── theme.tres
├── scenes/
│   ├── game_board.tscn
│   ├── main.tscn
│   ├── start_screen.tscn
│   └── title_screen.tscn
└── scripts/
    ├── ai/
    │   ├── ai_controller.gd
    │   ├── ai_opponent.gd
    │   └── ai_ui_manager.gd
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
    │   ├── turn_manager.gd
    │   └── weapon_manager.gd
    ├── ui/
    │   ├── base_ui_manager.gd
    │   ├── game_ui_manager.gd
    │   ├── phase_ui_manager.gd
    │   ├── placement_ui_manager.gd
    │   ├── player_ui_manager.gd
    │   ├── targeting_ui_manager.gd
    │   └── title_screen.gd
    ├── weapons/
    │   ├── weapon_attack.gd
    │   ├── weapon_placement.gd
    │   ├── weapon_types.gd
    │   └── weapon_visualization.gd
    ├── game_data.gd
    ├── main.gd
    └── start_screen.gd
```