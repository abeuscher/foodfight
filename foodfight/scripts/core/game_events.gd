extends Node
class_name GameEvents

# Core game state events
const STATE_CHANGED = "state_changed"
const PHASE_CHANGED = "phase_changed"
const PLAYER_CHANGED = "player_changed"
const GAME_OVER = "game_over"
const TURN_STARTED = "turn_started"
const TURN_ENDED = "turn_ended"

# UI update events
const UI_UPDATE_REQUIRED = "ui_update_required"
const PHASE_DISPLAY_UPDATED = "phase_display_updated"
const TITLE_SCREEN_COMPLETED = "title_screen_completed"

# Player-related events
const PLAYER_STATS_CHANGED = "player_stats_changed"
const INGREDIENTS_UPDATED = "ingredients_updated"
const INGREDIENTS_AWARDED = "ingredients_awarded" # Added missing constant
const WEAPON_SELECTED = "weapon_selected"
const WEAPON_DESELECTED = "weapon_deselected"

# Placement-related events
const PLACEMENT_STARTED = "placement_started"
const PLACEMENT_COMPLETED = "placement_completed"
const PLACEMENT_CANCELLED = "placement_cancelled"
const PLACEMENT_INVALID = "placement_invalid"
const PLACEMENT_PREVIEW_UPDATED = "placement_preview_updated"

# Targeting-related events
const TARGETING_STARTED = "targeting_started"
const TARGETING_COMPLETED = "targeting_completed"
const TARGETING_CANCELLED = "targeting_cancelled"
const TARGETING_INVALID = "targeting_invalid"
const TARGETING_PREVIEW_UPDATED = "targeting_preview_updated"
const TARGET_SELECTED = "target_selected"

# Attack-related events
const ATTACK_STARTED = "attack_started"
const ATTACK_COMPLETED = "attack_completed"
const ATTACK_HIT = "attack_hit"
const ATTACK_MISS = "attack_miss"
const ATTACK_INTERCEPTED = "attack_intercepted"
const STRUCTURE_DAMAGED = "structure_damaged"
const STRUCTURE_DESTROYED = "structure_destroyed"

# AI-related events
const AI_THINKING_STARTED = "ai_thinking_started"
const AI_THINKING_COMPLETED = "ai_thinking_completed"
const AI_PLACEMENT_SELECTED = "ai_placement_selected"
const AI_TARGET_SELECTED = "ai_target_selected"
const AI_ERROR = "ai_error"
const AI_MOVE_EXECUTED = "ai_move_executed"

# System events
const ERROR_OCCURRED = "error_occurred"
const WARNING_OCCURRED = "warning_occurred"
const DEBUG_MESSAGE = "debug_message"

# New events
const PHASE_ACTION_COMPLETED = "phase_action_completed" # Player completed phase action
const NEXT_PLAYER_TURN = "next_player_turn" # Signal next player's turn
const PLAYER_TURN_STARTED = "player_turn_started" # Player turn has started

# System waiting state
const GAME_WAITING_STATE_CHANGED = "game_waiting_state_changed" # System is waiting (e.g., for AI or animation)

# Get all event constants defined in this class
static func get_all_events() -> Array:
	var events = []
	var constants = {}
	
	# We need to use reflection to get the constants, but can't call get_script()
	# on the class itself, so we'll enumerate them manually
	constants = {
		"STATE_CHANGED": STATE_CHANGED,
		"PHASE_CHANGED": PHASE_CHANGED,
		"PLAYER_CHANGED": PLAYER_CHANGED,
		"GAME_OVER": GAME_OVER,
		"TURN_STARTED": TURN_STARTED,
		"TURN_ENDED": TURN_ENDED,
		"UI_UPDATE_REQUIRED": UI_UPDATE_REQUIRED,
		"PHASE_DISPLAY_UPDATED": PHASE_DISPLAY_UPDATED,
		"TITLE_SCREEN_COMPLETED": TITLE_SCREEN_COMPLETED,
		"PLAYER_STATS_CHANGED": PLAYER_STATS_CHANGED,
		"INGREDIENTS_UPDATED": INGREDIENTS_UPDATED,
		 "INGREDIENTS_AWARDED": INGREDIENTS_AWARDED, # Added missing constant
		"WEAPON_SELECTED": WEAPON_SELECTED,
		"WEAPON_DESELECTED": WEAPON_DESELECTED,
		"PLACEMENT_STARTED": PLACEMENT_STARTED,
		"PLACEMENT_COMPLETED": PLACEMENT_COMPLETED,
		"PLACEMENT_CANCELLED": PLACEMENT_CANCELLED,
		"PLACEMENT_INVALID": PLACEMENT_INVALID,
		"PLACEMENT_PREVIEW_UPDATED": PLACEMENT_PREVIEW_UPDATED,
		"TARGETING_STARTED": TARGETING_STARTED,
		"TARGETING_COMPLETED": TARGETING_COMPLETED,
		"TARGETING_CANCELLED": TARGETING_CANCELLED,
		"TARGETING_INVALID": TARGETING_INVALID,
		"TARGETING_PREVIEW_UPDATED": TARGETING_PREVIEW_UPDATED,
		"TARGET_SELECTED": TARGET_SELECTED,
		"ATTACK_STARTED": ATTACK_STARTED,
		"ATTACK_COMPLETED": ATTACK_COMPLETED,
		"ATTACK_HIT": ATTACK_HIT,
		"ATTACK_MISS": ATTACK_MISS,
		"ATTACK_INTERCEPTED": ATTACK_INTERCEPTED,
		"STRUCTURE_DAMAGED": STRUCTURE_DAMAGED,
		"STRUCTURE_DESTROYED": STRUCTURE_DESTROYED,
		"AI_THINKING_STARTED": AI_THINKING_STARTED,
		"AI_THINKING_COMPLETED": AI_THINKING_COMPLETED,
		"AI_PLACEMENT_SELECTED": AI_PLACEMENT_SELECTED,
		"AI_TARGET_SELECTED": AI_TARGET_SELECTED,
		"AI_ERROR": AI_ERROR,
		"AI_MOVE_EXECUTED": AI_MOVE_EXECUTED,
		"ERROR_OCCURRED": ERROR_OCCURRED,
		"WARNING_OCCURRED": WARNING_OCCURRED,
		"DEBUG_MESSAGE": DEBUG_MESSAGE,
		"PHASE_ACTION_COMPLETED": PHASE_ACTION_COMPLETED,
		"NEXT_PLAYER_TURN": NEXT_PLAYER_TURN,
		"PLAYER_TURN_STARTED": PLAYER_TURN_STARTED,
		"GAME_WAITING_STATE_CHANGED": GAME_WAITING_STATE_CHANGED
	}
	
	# Add all the values to our events array
	for value in constants.values():
		events.append(value)
			
	return events
