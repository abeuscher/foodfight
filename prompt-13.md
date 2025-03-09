# Session Prompt: Implementing Attack Visualization and Damage System

## Goals for Next Session
1. Implement attack visualization directly on the game board
2. Create a damage calculation system for weapons
3. Add visual feedback to show weapon health/damage
4. Complete the attack phase of the game loop

## Starting Points
We'll continue using the approach of integrating visualization directly into the game_board.gd rather than as separate components. This will ensure better coordinate alignment and simplify the code.

## Key Requirements
- Visualizing attack trajectories from attacker to target on the board
- Calculating and applying damage to weapons when they're hit
- Providing visual feedback when weapons take damage
- Handling weapon destruction when health reaches zero
- Checking for game end condition (all bases destroyed)

## Important Files
- board_core.gd - For attack visualization
- attack_state.gd - For attack execution and damage calculations
- weapon_manager.gd - For weapon health management
- game_state_machine.gd - For game flow and victory conditions

## Development Guidelines

**IMPORTANT INSTRUCTIONS:**
1. Do not give any code partials that are longer than 5 lines. If your rewrite is longer than 5 lines, provide the whole file.
2. Never ever try to rewrite code that you have not seen the most recent version of. When in doubt, do NOT write code. Ask questions.
3. Maintain consistent coordinate systems and use the game board for visualization.
4. Use a phased approach for implementation, verifying each step works before proceeding.

Let's approach this methodically, first understanding the current state of the attack phase, then determining what needs to be added to implement visual attack trajectories and damage calculations, and finally connecting everything to complete the game loop.