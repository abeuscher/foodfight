# Sprint Prompt 02: Completing the Game Loop with AI Opponent

## Sprint Goal
The goal of this sprint is to ensure that the game loop successfully completes with an AI opponent. This includes fixing any bugs, ensuring proper transitions between phases, and verifying that the AI behaves as expected. Additionally, we will clean up debug output statements from files after resolving issues to maintain clean and professional code.

---

## Sprint Structure

### 1. Phase Transitions and Game State Validation
**Objective:** Ensure that transitions between game phases (e.g., Base Placement, Weapon Placement, Targeting, Attack Resolution, Game Over) are smooth and error-free.

**Tasks:**
- Verify that the `PhaseManager` correctly handles transitions and emits appropriate signals.
- Ensure the `GameStateMachine` updates the game state accurately during phase transitions.
- Fix any bugs related to phase transitions, such as skipped phases or incorrect player turns.
- Remove debug output statements related to phase transitions after resolving issues.

**Files to Review:**
- `e:\FoodFightGodot\foodfight\scripts\states\phase_manager.gd`
- `e:\FoodFightGodot\foodfight\scripts\states\game_state_machine.gd`
- `e:\FoodFightGodot\foodfight\scripts\states\game_manager.gd`

**Notes:**
- Ensure that the `PhaseManager` and `GameStateMachine` are properly synchronized.
- Verify that the `PhaseManager` emits `phase_started` and `phase_completed` signals at the correct times.

---

### 2. AI Behavior and Turn Management
**Objective:** Ensure the AI opponent behaves as expected during its turn and interacts correctly with the game systems.

**Tasks:**
- Verify that the `AIController` processes AI turns correctly for each phase (Base Placement, Weapon Placement, Targeting).
- Ensure the AI respects game rules, such as resource limits and valid placement positions.
- Fix any bugs related to AI behavior, such as invalid placements or skipped actions.
- Remove debug output statements related to AI behavior after resolving issues.

**Files to Review:**
- `e:\FoodFightGodot\foodfight\scripts\ai\ai_controller.gd`
- `e:\FoodFightGodot\foodfight\scripts\ai\ai_opponent.gd`
- `e:\FoodFightGodot\foodfight\scripts\states\turn_manager.gd`

**Notes:**
- Ensure the `AIController` properly interacts with the `PhaseManager` and `GameStateMachine`.
- Verify that the AI's decision-making logic is consistent with the game's rules.

---

### 3. Attack Resolution and Game Over Logic
**Objective:** Ensure that attacks are resolved correctly and the game ends when a player loses all bases.

**Tasks:**
- Verify that the `AttackState` processes queued attacks correctly, including splash damage and health updates.
- Ensure the `PhaseManager` transitions to the Game Over phase when a player loses all bases.
- Fix any bugs related to attack resolution or game over conditions.
- Remove debug output statements related to attack resolution and game over logic after resolving issues.

**Files to Review:**
- `e:\FoodFightGodot\foodfight\scripts\states\attack_state.gd`
- `e:\FoodFightGodot\foodfight\scripts\game_board\board_core.gd`
- `e:\FoodFightGodot\foodfight\scripts\game_board\visual_manager.gd`

**Notes:**
- Ensure that the `AttackState` properly calculates damage and updates the game board.
- Verify that the `PhaseManager` correctly identifies the Game Over condition and transitions to the appropriate phase.

---

### 4. UI Updates and Player Feedback
**Objective:** Ensure the UI reflects the current game state and provides clear feedback to the player.

**Tasks:**
- Verify that the `BaseUIManager` and its child managers update the UI correctly during each phase.
- Ensure that the title screen displays the correct phase name and transitions smoothly.
- Fix any bugs related to UI updates, such as incorrect labels or missing elements.
- Remove debug output statements related to UI updates after resolving issues.

**Files to Review:**
- `e:\FoodFightGodot\foodfight\scripts\ui\base_ui_manager.gd`
- `e:\FoodFightGodot\foodfight\scripts\ui\placement_ui_manager.gd`
- `e:\FoodFightGodot\foodfight\scripts\ui\title_screen.gd`
- `e:\FoodFightGodot\foodfight\scenes\title_screen.tscn`

**Notes:**
- Ensure that the `BaseUIManager` properly delegates UI updates to its child managers.
- Verify that the title screen animations are correctly triggered by the `PhaseManager`.

---

### 5. Code Cleanup and Final Testing
**Objective:** Perform a final review of the codebase to ensure quality and readiness for the next sprint.

**Tasks:**
- Remove all unnecessary debug output statements from the codebase.
- Verify that all components are properly initialized and registered with the `GameManager`.
- Conduct a full playthrough of the game loop with an AI opponent to ensure everything works as expected.
- Document any remaining issues or areas for improvement for the next sprint.

**Files to Review:**
- All files modified during this sprint.

**Notes:**
- Pay special attention to debug output statements and ensure they are removed after resolving issues.
- Verify that all services are correctly registered and accessible through the `GameManager`.

---

## Guidelines
- **Emphasize Quality:** Take the time to implement solutions properly, even if it takes longer. Avoid quick fixes that could introduce technical debt.
- **Debug Output Cleanup:** After fixing a bug, remove any debug output statements related to the issue to maintain clean and professional code.
- **Collaboration:** Communicate with the team if you encounter blockers or need clarification on any task.

---

## Expected Deliverables
1. A fully functional game loop with an AI opponent.
2. Clean and professional code with no unnecessary debug output statements.
3. A list of any remaining issues or areas for improvement for the next sprint.