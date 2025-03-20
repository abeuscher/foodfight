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
├─ Uses → EventBus (for event communication)
├─ Depends on → InitializationController (for ordered initialization)
├─ Registers & References → GameBoard
├─ Registers & References → GameStateMachine
├─ Registers & References → BaseUIManager
├─ Registers & References → PlayerManager
├─ Registers & References → PlacementState
├─ Registers & References → TargetingState
├─ Registers & References → AttackState
├─ Registers & References → WeaponTypes
├─ Registers & References → WeaponPlacement
├─ Registers & References → AIOpponent
├─ Registers & References → PhaseManager (added from scene hierarchy)
├─ References → WeaponManager (via AttackState)
├─ References → TargetingManager (via AttackState)
├─ References → TurnManager (via GameStateMachine)
└─ References → AIController (via GameStateMachine)

PhaseManager (Added based on main.tscn)
├─ Depends on → GameBoard
├─ Depends on → WeaponTypes
├─ Depends on → WeaponPlacement
├─ Depends on → TargetingState
├─ Depends on → AttackState
├─ Depends on → BaseUIManager
└─ Depends on → PlayerManager

Main (Scene Root)
├─ Contains → GameStateMachine (direct child node)
├─ Contains → PhaseManager (direct child node)
├─ Contains → BaseUIManager (direct child node)
├─ Contains → PlayerManager (direct child node)
├─ Contains → PlacementState (direct child node)
├─ Contains → TargetingState (direct child node)
├─ Contains → AttackState (direct child node)
├─ Contains → WeaponTypes (direct child node)
├─ Contains → WeaponPlacement (direct child node)
├─ Contains → AIOpponent (direct child node)
├─ Contains → GameBoard (direct child node)
├─ Contains → UI (Canvas Layer)
│   ├─ Contains → TopBar
│   ├─ Contains → BottomBar
│   └─ Contains → TitleScreen (from title_screen.tscn)
├─ Calls → GameManager.initialize_game()
├─ Updates UI based on → GameStateMachine.current_state
└─ Forwards Input to → TargetingState, PlacementState

GameBoard (From game_board.tscn)
├─ Contains → CellManager (direct child node)
├─ Contains → VisualManager (direct child node)
└─ Handles → Attack Visualization

AttackState
├─ Contains → WeaponManager (direct child node)
├─ Contains → TargetingManager (direct child node)
├─ Depends on → GameBoard
├─ Depends on → WeaponTypes
└─ Uses → WeaponAttack (for attack animations)

WeaponPlacement
├─ Contains → WeaponVisualization (direct child node)
├─ Depends on → GameBoard
└─ Depends on → WeaponTypes

StartScreen (From start_screen.tscn)
├─ Contains → Player name input
├─ Contains → AI difficulty settings
└─ Transitions to → Main scene
```

## Directory Structure

```
FoodFight/
├── addons/
│   └── test_runner/
│       └── plugin.cfg
├── assets/
│   └── icon.svg
├── resources/
│   └── theme.tres
├── scenes/
│   ├── game_board.tscn
│   ├── main.tscn
│   ├── start_screen.tscn
│   └── title_screen.tscn
├── scripts/
│   ├── ai/
│   │   ├── ai_controller.gd
│   │   ├── ai_opponent.gd
│   │   └── ai_ui_manager.gd
│   ├── core/
│   │   ├── event_bus.gd
│   │   ├── game_events.gd
│   │   ├── initialization_controller.gd
│   │   ├── null_service.gd
│   │   └── service_registry.gd
│   ├── game_board/
│   │   ├── board_core.gd
│   │   ├── cell_manager.gd
│   │   └── visual_manager.gd
│   ├── states/
│   │   ├── attack_state.gd
│   │   ├── game_manager.gd
│   │   ├── game_state_machine.gd
│   │   ├── phase_manager.gd
│   │   ├── placement_state.gd
│   │   ├── player_manager.gd
│   │   ├── targeting_manager.gd
│   │   ├── targeting_state.gd
│   │   ├── turn_manager.gd
│   │   └── weapon_manager.gd
│   ├── ui/
│   │   ├── base_ui_listener.gd
│   │   ├── base_ui_manager.gd
│   │   ├── debug_ui_manager.gd
│   │   ├── phase_ui_manager.gd
│   │   ├── placement_ui_manager.gd
│   │   ├── player_ui_manager.gd
│   │   ├── targeting_ui_manager.gd
│   │   └── title_screen.gd
│   ├── weapons/
│   │   ├── weapon_attack.gd
│   │   ├── weapon_placement.gd
│   │   ├── weapon_types.gd
│   │   └── weapon_visualization.gd
│   ├── game_data.gd
│   ├── main.gd
│   ├── recovery_helper.gd
│   ├── service_initializer.gd
│   └── start_screen.gd
└── tests/
    ├── mock_game_manager.gd
    ├── run_tests.gd
    ├── test_game_state_machine.gd
    ├── test_result_viewer.gd
    ├── test_result_viewer.tscn
    ├── test_runner.tscn
    └── test_suite.gd
```

# FoodFight Project File Index

### Core Engine Files

| File | Description |
|------|-------------|
| `./foodfight/scripts/states/game_manager.gd` | Central singleton that coordinates all game systems and implements the service locator pattern |
| `./foodfight/scripts/core/initialization_controller.gd` | Manages the ordered initialization of game components with dependency checking |
| `./foodfight/scripts/core/event_bus.gd` | Event system for decoupled communication between components with cycle detection |
| `./foodfight/scripts/core/game_events.gd` | Defines standard game event types used throughout the event system |
| `./foodfight/scripts/core/null_service.gd` | Implements null object pattern for graceful handling of missing services |
| `./foodfight/scripts/core/service_registry.gd` | Service locator registry for component access and discovery |
| `./foodfight/scripts/service_initializer.gd` | Ensures critical services are properly registered and initialized |
| `./foodfight/scripts/recovery_helper.gd` | Provides emergency recovery mechanisms for game state consistency |

### Game State Management

| File | Description |
|------|-------------|
| `./foodfight/scripts/states/game_state_machine.gd` | Manages transitions between game states (phases) |
| `./foodfight/scripts/states/phase_manager.gd` | Centralizes phase transition logic and ensures proper sequencing |
| `./foodfight/scripts/states/turn_manager.gd` | Handles turn transitions and player switching |
| `./foodfight/scripts/states/player_manager.gd` | Manages player data, resources, and tracks current player |
| `./foodfight/scripts/states/placement_state.gd` | Handles base and weapon placement phases and logic |
| `./foodfight/scripts/states/targeting_state.gd` | Manages targeting phase, weapon selection and target assignment |
| `./foodfight/scripts/states/attack_state.gd` | Handles attack resolution, damage calculation and visual effects |

### Game Board

| File | Description |
|------|-------------|
| `./foodfight/scripts/game_board/board_core.gd` | Core game board implementation with grid, terrain and visualization |
| `./foodfight/scripts/game_board/cell_manager.gd` | Manages individual grid cells, their properties and states |
| `./foodfight/scripts/game_board/visual_manager.gd` | Handles visual representation of game elements on the board |

### Weapon Systems

| File | Description |
|------|-------------|
| `./foodfight/scripts/weapons/weapon_types.gd` | Defines all weapon types, properties and costs |
| `./foodfight/scripts/weapons/weapon_placement.gd` | Handles weapon placement logic and validation |
| `./foodfight/scripts/weapons/weapon_attack.gd` | Implements attack animations and damage visualization |
| `./foodfight/scripts/weapons/weapon_visualization.gd` | Creates and manages weapon sprites on the game board |
| `./foodfight/scripts/states/weapon_manager.gd` | Manages weapon instances, stats and state during gameplay |
| `./foodfight/scripts/states/targeting_manager.gd` | Validates targets and calculates attack trajectories |

### UI System

| File | Description |
|------|-------------|
| `./foodfight/scripts/ui/base_ui_listener.gd` | Base class for UI components to listen to game events |
| `./foodfight/scripts/ui/base_ui_manager.gd` | Core UI coordinator that manages all child UI components |
| `./foodfight/scripts/ui/phase_ui_manager.gd` | Handles phase-specific UI elements and transitions |
| `./foodfight/scripts/ui/placement_ui_manager.gd` | Manages UI components for placement phases |
| `./foodfight/scripts/ui/player_ui_manager.gd` | Updates player information in the UI |
| `./foodfight/scripts/ui/targeting_ui_manager.gd` | Handles targeting UI components and weapon selection |
| `./foodfight/scripts/ui/debug_ui_manager.gd` | Provides debug information and controls |
| `./foodfight/scripts/ui/title_screen.gd` | Controls title screen animations and phase announcements |

### AI System

| File | Description |
|------|-------------|
| `./foodfight/scripts/ai/ai_opponent.gd` | Implements AI decision-making for placements and targeting |
| `./foodfight/scripts/ai/ai_controller.gd` | Coordinates AI turns and integrates with game systems |
| `./foodfight/scripts/ai/ai_ui_manager.gd` | Manages UI elements related to AI actions |

### Scene Files

| File | Description |
|------|-------------|
| `./foodfight/scenes/main.tscn` | Main game scene containing all core game components and UI |
| `./foodfight/scenes/game_board.tscn` | The game board scene with grid and visualization systems |
| `./foodfight/scenes/start_screen.tscn` | Initial menu with player name input and AI difficulty options |
| `./foodfight/scenes/title_screen.tscn` | Overlay scene for displaying phase names and transitions |

### Test Framework

| File | Description |
|------|-------------|
| `./foodfight/tests/test_suite.gd` | Base class for test suites with common functionality |
| `./foodfight/tests/run_tests.gd` | Entry point script that executes all test suites |
| `./foodfight/tests/test_game_state_machine.gd` | Tests for the game state machine functionality |
| `./foodfight/tests/mock_game_manager.gd` | Mock implementation of GameManager for isolated testing |
| `./foodfight/tests/test_result_viewer.gd` | UI script for displaying test results |
| `./foodfight/tests/test_result_viewer.tscn` | Scene for visualizing test results |
| `./foodfight/tests/test_runner.tscn` | Main scene for running and displaying tests |
| `./foodfight/addons/test_runner/plugin.cfg` | Configuration for the test runner editor plugin |

### Miscellaneous

| File | Description |
|------|-------------|
| `./foodfight/scripts/main.gd` | Main scene script that bootstraps the game initialization |
| `./foodfight/scripts/start_screen.gd` | Handles start screen functionality and game setup |
| `./foodfight/scripts/game_data.gd` | Global game configuration data and constants |
| `./foodfight/resources/theme.tres` | UI theme resource for consistent styling |
| `./foodfight/assets/icon.svg` | Project icon file |

## Event Catalog

A comprehensive catalog of all system events would be extremely helpful:

| Event Name | Emitted By | Listened By | Purpose |
|------------|------------|-------------|---------|
| STATE_CHANGED | GameStateMachine, PhaseManager | BaseUIManager, PhaseUIManager, PlacementState | Notify when game state transitions |
| PHASE_CHANGED | PhaseManager | BaseUIManager, PhaseUIManager | Update UI with current phase info |
| PLAYER_CHANGED | TurnManager, PhaseManager | BaseUIManager, PlayerUIManager | Update UI with current player info |
| AI_THINKING_STARTED | AIController, BaseUIManager | AIUIManager | Show AI thinking indicator |
| AI_THINKING_COMPLETED | AIController, BaseUIManager | AIUIManager | Hide AI thinking indicator |
| GAME_OVER | PhaseManager | BaseUIManager, PhaseUIManager | Show game over screen |
| INGREDIENTS_UPDATED | AttackState, PlayerManager | PlayerUIManager | Update resource display |

## Component API Contracts

A reference of critical methods each component must implement:

| Component | Required Methods | Purpose |
|-----------|------------------|---------|
| BaseUIManager | update_ui(state, player_index) | Update UI based on game state |
| PhaseUIManager | update_phase_ui(state, player_index) | Update phase-specific UI elements |
| WeaponPlacement | start_placement_phase(player_index) | Initialize placement phase |
| PlayerManager | is_current_player_ai() | Check if current player is AI |
| AttackState | execute_attacks() | Process all attack actions |
| PhaseManager | transition_to_phase(new_phase, player_index) | Change game phase |

## Initialization Sequence Diagram

```
1. GameManager creates EventBus
2. Main initializes core components
3. GameManager registers services
4. InitializationController starts stage sequence:
   ├─ CORE_SYSTEMS (GameBoard, PlayerManager)
   ├─ WEAPON_SYSTEMS (WeaponTypes, WeaponPlacement)
   ├─ STATE_SYSTEMS (States, Managers)
   ├─ AI_SYSTEMS
   ├─ UI_SYSTEMS
   └─ SIGNAL_BINDING (Connect all events)
5. ServiceInitializer ensures critical services exist
6. Phase transitioning begins (BASE_PLACEMENT)
```

## State Transition Flow

```
START_SCREEN → BASE_PLACEMENT → WEAPON_PLACEMENT → TARGETING → ATTACK_RESOLUTION → 
               └─ If game over → GAME_OVER
               └─ Otherwise → WEAPON_PLACEMENT (next round)
```

## Common Implementation Patterns Reference

A quick reference for implementation patterns used throughout the codebase:

| Pattern | Usage | Example |
|---------|-------|---------|
| Service Locator | Finding components | `get_service("ServiceName")` |
| Event Emission | Component communication | `event_bus.emit_event("EVENT_NAME", {data})` |
| Deferred Actions | Safe state changes | `call_deferred("_after_scene_change")` |
| Factory Methods | Creating game objects | `create_weapon(weapon_type, position)` |
| State Machine | Managing game phases | `transition_to_phase(Phase.TARGETING)` |