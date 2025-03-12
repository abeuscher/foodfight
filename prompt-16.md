# Session Prompt: Implementing Damage System for FoodFight Game

## Current Session Progress
In our current session, we've made UI improvements to enhance the game's visual presentation:
1. Refined the theme file with reduced border widths (from 3-4px to 2px)
2. Standardized font sizes to 14px across UI components
3. Adjusted corner radii for a more polished appearance
4. Improved content margins for better text alignment
5. Reduced shadow effects for a cleaner interface
6. These changes make the UI more compact and ensure better text fit within containers

## Summary of Previous Progress
We've successfully built the core game architecture with:
1. A robust game state machine with distinct phases from setup to resolution
2. Weapon placement and targeting mechanics
3. Attack execution framework
4. Unit testing capabilities to ensure game stability

The game currently allows players to:
- Place their bases
- Position offensive and defensive weapons on their islands
- Target enemy structures
- Execute basic attacks

However, the damage system remains underdeveloped. While attacks can be executed visually, the mechanics for damage calculation, structure health management, and destruction effects need to be implemented.

## Goals for Next Session
1. Design a comprehensive damage system
2. Implement health tracking for all structure types
3. Create damage calculation logic based on weapon types and defenses
4. Develop visual feedback for damage (health bars, damage numbers, destruction effects)
5. Integrate the damage system with the existing attack resolution phase

## Key Components to Develop
- **Structure Health System**: Track and display health for all structures
- **Damage Calculation**: Create formulas for different weapon types and defense interactions
- **Attack Resolution Logic**: Determine hit success, damage application, and structure destruction
- **Visual Damage Indicators**: Health bars, damage numbers, destruction animations
- **Game State Updates**: Update game state based on damage outcomes

## Implementation Approach
1. First plan the damage system architecture and how it integrates with existing components
2. Design structure health properties and management
3. Implement core damage calculation logic
4. Add visual feedback elements
5. Test and balance the system with different scenarios

## Development Guidelines
1. Keep damage calculations clean and well-documented
2. Ensure good separation between logic and visual effects
3. Consider player feedback during damage resolution
4. Design with extensibility in mind for future weapon and defense types
5. Add appropriate unit tests for damage calculations

This session will focus on designing and implementing a robust damage system that adds depth to the gameplay while providing clear feedback to players about the outcomes of their attacks.
