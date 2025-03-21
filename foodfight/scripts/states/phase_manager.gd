extends Node

# Phase management system to centralize all phase transition logic
# and ensure proper sequencing of phase transitions

# Game phases - matching GameState enum in game_state_machine.gd
enum Phase {
	UNINITIALIZED,
	START_SCREEN,
	BASE_PLACEMENT,
	WEAPON_PLACEMENT,
	TARGETING,
	ATTACK_RESOLUTION,
	GAME_OVER
}

# Define signals
signal phase_started(phase, player_index)
signal phase_completed(phase, player_index)

# Component references
var game_board
var weapon_types
@onready var weapon_placement = get_service("WeaponPlacement") as Node
var targeting_state
var attack_state
var ui_manager
var player_manager
var event_bus

# Phase state tracking
var current_phase = Phase.UNINITIALIZED
var phase_transition_in_progress = false
var player_action_in_progress = false
var ai_action_in_progress = false
var is_initialized = false

# Track base placement to prevent multiple calls for same player
var base_placement_done = [false, false]

# Add recursion guards like in our other files
var _active_method_calls = {}

# Track last handled events to prevent duplicate processing
var _last_handled_event = {
	"phase": - 1,
	"player_index": - 1,
	"timestamp": 0
}

# Add waiting state variable
var game_waiting_for_ai = false

# Add this to the top with other state tracking variables
var current_ai_action_player = -1 # Track which player AI is currently acting for (-1 means none)

# Initialize the phase manager with dependencies
func initialize(p_game_board, p_weapon_types, p_weapon_placement,
			   p_targeting_state, p_attack_state, p_ui_manager, p_player_manager):
	# Guard against multiple initializations
	if is_initialized:
		return self
		
	# Store component references
	game_board = p_game_board
	weapon_types = p_weapon_types
	weapon_placement = p_weapon_placement
	targeting_state = p_targeting_state
	attack_state = p_attack_state
	ui_manager = p_ui_manager
	player_manager = p_player_manager
	
	# Get event bus reference if available
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		event_bus = game_manager.get_service("EventBus")
	
	# Register phase completion callbacks
	if weapon_placement and weapon_placement.has_signal("weapon_placed"):
		# Avoid connecting multiple times
		if !weapon_placement.is_connected("weapon_placed", Callable(self, "_on_weapon_placed")):
			weapon_placement.weapon_placed.connect(Callable(self, "_on_weapon_placed"))
	else:
		push_error("PhaseManager ERROR: weapon_placement is not properly initialized or missing 'weapon_placed' signal")
	
	is_initialized = true
	return self

# This hook ensures we register for events when the node enters the scene tree
func _ready():
	_subscribe_to_events()

# Subscribe to events
func _subscribe_to_events():
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		var event_bus = game_manager.get_service("EventBus")
		if event_bus:
			# Unsubscribe first to avoid duplicates
			event_bus.unsubscribe("PHASE_ACTION_COMPLETED", self)
			# Then subscribe
			event_bus.subscribe("PHASE_ACTION_COMPLETED", self)
			print("PhaseManager: Subscribed to PHASE_ACTION_COMPLETED event")

# Change the method name to match what EventBus expects
# The EventBus uses lowercase for the method name regardless of event name case
func on_PHASE_ACTION_COMPLETED(event_data):
	# Guard against reentrant calls
	if _active_method_calls.get("on_PHASE_ACTION_COMPLETED", false):
		print("PhaseManager: Preventing recursive PHASE_ACTION_COMPLETED handling")
		return
	
	# STRONGER GUARD: Check if we've recently handled the same event
	var current_time = Time.get_ticks_msec()
	if event_data.phase == _last_handled_event.phase and \
	   event_data.player_index == _last_handled_event.player_index and \
	   (current_time - _last_handled_event.timestamp) < 1000: # 1 second guard
		print("PhaseManager: Ignoring duplicate event for phase " + str(event_data.phase) +
			  " and player " + str(event_data.player_index) +
			  " (received " + str(current_time - _last_handled_event.timestamp) + "ms after previous)")
		return
		
	# Record this event to prevent duplicates
	_last_handled_event = {
		"phase": event_data.phase,
		"player_index": event_data.player_index,
		"timestamp": current_time
	}
		
	_active_method_calls["on_PHASE_ACTION_COMPLETED"] = true

	# EVEN STRONGER GUARD: Prevent ANY phase action completion during AI processing
	if game_waiting_for_ai and event_data.player_index != current_ai_action_player:
		print("PhaseManager: BLOCKING phase action for player " + str(event_data.player_index) +
			  " during AI processing for player " + str(current_ai_action_player))
		return
	
	if event_data.phase == Phase.BASE_PLACEMENT:
		# Get the player_index from the event data
		var player_index = event_data.player_index
		
		print("PhaseManager: Handling base placement completion for player " + str(player_index))
		
		# Mark this player's base placement as done
		base_placement_done[player_index] = true
		
		# Emit the phase completed signal for this player
		emit_signal("phase_completed", Phase.BASE_PLACEMENT, player_index)
		
		# First player completed base placement
		if player_index == 0:
			# Add null check before calling next_player
			if player_manager == null:
				push_error("PhaseManager: player_manager is null! Cannot switch to next player.")
				return
				
			# Switch to player 2
			player_manager.next_player()
			var next_player = player_manager.current_player_index
			
			print("Switching to next player: " + str(next_player) + " (" + player_manager.get_player_name(next_player) + ")")
			
			# Update player without changing phase
			emit_event("PLAYER_CHANGED", {
				"player_index": next_player,
				"player_name": player_manager.get_player_name(next_player)
			})
			
			# Re-initialize base placement for next player
			_initialize_base_placement(next_player)
			
			# Process AI turn if needed
			if player_manager.is_current_player_ai():
				print("Current player is AI, scheduling AI turn")
				# Don't use call_deferred, call directly
				_process_ai_turn()
		else:
			# Both players have completed base placement, move to weapon placement
			print("Both players completed base placement, transitioning to weapon placement")
			transition_to_phase(Phase.WEAPON_PLACEMENT)
	
	# Add similar logic for WEAPON_PLACEMENT if needed
	elif event_data.phase == Phase.WEAPON_PLACEMENT:
		var player_index = event_data.player_index
		print("PhaseManager: Handling weapon placement completion for player " + str(player_index))
		weapon_placement_completed(player_index)
		
	_active_method_calls["on_PHASE_ACTION_COMPLETED"] = false

# Central method to handle all phase transitions
func transition_to_phase(new_phase, force_player_index = -1):
	# Prevent recursive or overlapping transitions
	if _active_method_calls.get("transition_to_phase", false):
		return false
		
	_active_method_calls["transition_to_phase"] = true
	
	# Prevent overlapping transitions
	if phase_transition_in_progress:
		_active_method_calls["transition_to_phase"] = false
		return false
		
	phase_transition_in_progress = true
	
	var old_phase = current_phase
	current_phase = new_phase
	
	# Determine player for this phase
	var player_index
	if force_player_index >= 0:
		player_index = force_player_index
	else:
		# Reset to player 1 when starting a new main phase
		if new_phase in [Phase.BASE_PLACEMENT, Phase.WEAPON_PLACEMENT, Phase.TARGETING] and old_phase != new_phase:
			player_manager.reset_current_player()
		player_index = player_manager.current_player_index
	
	# When transitioning to BASE_PLACEMENT, reset base placement tracking
	if new_phase == Phase.BASE_PLACEMENT and old_phase != Phase.BASE_PLACEMENT:
		base_placement_done = [false, false]
	
	# Notify GameManager directly instead of emitting signals
	var game_manager = get_service("GameManager")
	if game_manager:
		game_manager.update_ui(current_phase, player_manager.current_player_index)
	
	# Emit proper phase started signal
	emit_signal("phase_started", new_phase, player_index)
	
	# Emit event for external listeners
	emit_event("STATE_CHANGED", {
		"old_state": old_phase,
		"new_state": new_phase,
		"player_index": player_index
	})
	
	# Update UI with phase text - only emit this event once
	emit_event("PHASE_CHANGED", {
		"phase_text": get_phase_display_name(new_phase),
		"state": new_phase
	})
	
	# Get PhaseUIManager service - CHANGED APPROACH
	# Instead of direct call, emit an event that the PhaseUIManager will listen for
	# This avoids the timing dependency issue
	emit_event("SHOW_PHASE_TITLE", {
		"phase_name": get_phase_display_name(new_phase)
	})
	
	# Ensure player is updated in UI
	emit_event("PLAYER_CHANGED", {
		"player_index": player_index,
		"player_name": player_manager.get_current_player_name()
	})
	
	# Perform phase-specific initialization
	_initialize_phase(new_phase, player_index)
	
	# Transition complete
	phase_transition_in_progress = false
	
	# Process AI turn if needed (after transition is complete)
	if player_manager.is_current_player_ai():
		# Don't use call_deferred anymore, call directly
		_process_ai_turn()
	
	_active_method_calls["transition_to_phase"] = false
	return true

# Get user-friendly phase name for display - remove redundant "Phase" text
func get_phase_display_name(phase):
	match phase:
		Phase.UNINITIALIZED:
			return "Initializing"
		Phase.START_SCREEN:
			return "Start Screen"
		Phase.BASE_PLACEMENT:
			return "Base Placement" # Removed redundant "Phase"
		Phase.WEAPON_PLACEMENT:
			return "Weapon Placement" # Removed redundant "Phase"
		Phase.TARGETING:
			return "Targeting" # Removed redundant "Phase"
		Phase.ATTACK_RESOLUTION:
			return "Attack Resolution" # Removed redundant "Phase"
		Phase.GAME_OVER:
			return "Game Over"
		_:
			return "Unknown"

# Initialize a specific phase
func _initialize_phase(phase, player_index):
	match phase:
		Phase.BASE_PLACEMENT:
			_initialize_base_placement(player_index)
		Phase.WEAPON_PLACEMENT:
			_initialize_weapon_placement(player_index)
		Phase.TARGETING:
			_initialize_targeting(player_index)
		Phase.ATTACK_RESOLUTION:
			_initialize_attack_resolution()
		Phase.GAME_OVER:
			_initialize_game_over()

# Initialize base placement phase
func _initialize_base_placement(player_index):
	if weapon_placement:
		print("PhaseManager: Initializing base placement for player " + str(player_index) +
			" (" + player_manager.get_player_name(player_index) + ")")
		
		# Activate base placement phase
		weapon_placement.is_base_placement_phase = true
		weapon_placement.current_player_id = player_index # Ensure correct player is set
		weapon_placement.current_phase = Phase.BASE_PLACEMENT # Set the current phase explicitly
		weapon_placement.placement_active = true
		
		# Explicitly enable hover preview
		weapon_placement.enable_placement_preview(true)
	else:
		push_error("PhaseManager ERROR: Cannot initialize base placement - weapon_placement is null")

# Initialize weapon placement phase
func _initialize_weapon_placement(player_index):
	if _active_method_calls.get("_initialize_weapon_placement", false):
		return
		
	_active_method_calls["_initialize_weapon_placement"] = true
	
	if weapon_placement:
		var placement_state = get_service("PlacementState")
		if placement_state:
			placement_state.create_weapon_buttons_for_current_state()
		
		# FIX: Use direct property setting instead of nonexistent method
		weapon_placement.is_base_placement_phase = false
		weapon_placement.current_player_id = player_index
		weapon_placement.placement_active = true
		
		# Make sure the weapon placement system knows we're in WEAPON_PLACEMENT phase
		weapon_placement.current_phase = Phase.WEAPON_PLACEMENT
		
		# Explicitly enable hover preview
		weapon_placement.enable_placement_preview(true)
	else:
		push_error("PhaseManager ERROR: Cannot initialize weapon placement - weapon_placement is null")
	
	_active_method_calls["_initialize_weapon_placement"] = false

# Initialize targeting phase
func _initialize_targeting(player_index):
	if targeting_state:
		targeting_state.start_targeting(player_index)
	else:
		push_error("PhaseManager ERROR: Cannot initialize targeting - targeting_state is null")

# Initialize attack resolution phase
func _initialize_attack_resolution():
	if attack_state:
		attack_state.execute_attacks()
	else:
		push_error("PhaseManager ERROR: Cannot initialize attack resolution - attack_state is null")

# Initialize game over phase
func _initialize_game_over():
	var winning_player = player_manager.get_winner_id()
	emit_event("GAME_OVER", {
		"winning_player": winning_player
	})

# Handle base placement completion
func base_placement_completed(player_index):
	emit_event("PHASE_ACTION_COMPLETED", {
		"phase": Phase.BASE_PLACEMENT,
		"player_index": player_index,
		"all_players_complete": player_index == 1
	})

# Handle weapon placement completion
func weapon_placement_completed(player_index):
	if _active_method_calls.get("weapon_placement_completed", false):
		return false
		
	_active_method_calls["weapon_placement_completed"] = true
	
	if current_phase != Phase.WEAPON_PLACEMENT:
		_active_method_calls["weapon_placement_completed"] = false
		return false
	
	# Emit the phase completed signal for this player
	emit_signal("phase_completed", Phase.WEAPON_PLACEMENT, player_index)
	
	# Notify GameManager directly instead of emitting signals
	var game_manager = get_service("GameManager")
	if game_manager:
		game_manager.update_ui(current_phase, player_manager.current_player_index if player_manager else 0)
	
	if player_index == 0:
		# Add null check before calling next_player
		if player_manager == null:
			push_error("PhaseManager: player_manager is null! Cannot switch to next player.")
			_active_method_calls["weapon_placement_completed"] = false
			return false
			
		player_manager.next_player()
		var next_player = player_manager.current_player_index
		
		emit_event("PLAYER_CHANGED", {
			"player_index": next_player,
			"player_name": player_manager.get_player_name(next_player)
		})
		
		# FIX: Use direct property setting instead of nonexistent method
		weapon_placement.is_base_placement_phase = false
		weapon_placement.current_player_id = next_player
		weapon_placement.placement_active = true
	else:
		transition_to_phase(Phase.TARGETING)
	
	_active_method_calls["weapon_placement_completed"] = false
	return true

# Handle targeting completion
func targeting_completed(player_index):
	if _active_method_calls.get("targeting_completed", false):
		return false
		
	_active_method_calls["targeting_completed"] = true
	
	if current_phase != Phase.TARGETING:
		_active_method_calls["targeting_completed"] = false
		return false
	
	# Emit the phase completed signal for this player
	emit_signal("phase_completed", Phase.TARGETING, player_index)
	
	# Notify GameManager directly instead of emitting signals
	var game_manager = get_service("GameManager")
	if game_manager:
		game_manager.update_ui(current_phase, player_manager.current_player_index)
	
	# First player completed targeting
	if player_index == 0:
		# Switch to player 2
		player_manager.next_player()
		var next_player = player_manager.current_player_index
		
		# Update player without changing phase
		emit_event("PLAYER_CHANGED", {
			"player_index": next_player,
			"player_name": player_manager.get_player_name(next_player)
		})
		
		# Re-initialize targeting for next player
		targeting_state.start_targeting(next_player)
		
		# Process AI turn if needed
		if player_manager.is_current_player_ai():
			# Call directly instead of deferring
			_process_ai_turn()
	else:
		# Both players have completed targeting, move to attack resolution
		transition_to_phase(Phase.ATTACK_RESOLUTION)
	
	_active_method_calls["targeting_completed"] = false
	return true

# Handle attack resolution completion
func attack_resolution_completed():
	if _active_method_calls.get("attack_resolution_completed", false):
		return false
		
	_active_method_calls["attack_resolution_completed"] = true
	
	if current_phase != Phase.ATTACK_RESOLUTION:
		_active_method_calls["attack_resolution_completed"] = false
		return false
	
	# Emit the phase completed signal
	emit_signal("phase_completed", Phase.ATTACK_RESOLUTION, -1)
	
	# Notify GameManager directly instead of emitting signals
	var game_manager = get_service("GameManager")
	if game_manager:
		game_manager.update_ui(current_phase, player_manager.current_player_index)
	
	# Check for game over condition
	var winner = _check_for_game_over()
	
	if winner >= 0:
		# Game is over, transition to game over phase
		player_manager.set_winner(winner)
		transition_to_phase(Phase.GAME_OVER)
	else:
		# Continue to next round with weapon placement
		transition_to_phase(Phase.WEAPON_PLACEMENT)
	
	_active_method_calls["attack_resolution_completed"] = false
	return true

# Track when a weapon is placed - to determine phase completion
func _on_weapon_placed(player_id, weapon_data, position):
	# For base placement, trigger completion when base is placed
	if current_phase == Phase.BASE_PLACEMENT and weapon_data.type == "base":
		# REPLACE direct call with event emission to avoid duplicate processing
		emit_event("PHASE_ACTION_COMPLETED", {
			"phase": Phase.BASE_PLACEMENT,
			"player_index": player_id,
			"all_players_complete": player_id == 1
		})

# Process AI turn if current player is AI
func _process_ai_turn():
	if _active_method_calls.get("_process_ai_turn", false):
		print("PhaseManager: Recursive call to _process_ai_turn detected and blocked")
		return false
	
	_active_method_calls["_process_ai_turn"] = true
	
	# DEBUG: Extra check to see if AI turns are being properly detected
	print("PhaseManager: _process_ai_turn called - player_index=" + str(player_manager.current_player_index) +
		  ", is_ai=" + str(player_manager.is_current_player_ai()))
	
	if !player_manager.is_current_player_ai():
		print("PhaseManager: Not AI turn - current player is " + player_manager.get_current_player_name())
		_active_method_calls["_process_ai_turn"] = false
		return false
	
	if ai_action_in_progress:
		print("PhaseManager: AI action already in progress, skipping")
		_active_method_calls["_process_ai_turn"] = false
		return false
	
	# Set global waiting state AND track which player's AI is processing
	game_waiting_for_ai = true
	ai_action_in_progress = true
	current_ai_action_player = player_manager.current_player_index
	print("PhaseManager: Starting AI action for phase: " + str(current_phase) +
		  " - " + get_phase_display_name(current_phase) +
		  " for player " + str(current_ai_action_player))
	
	# Block all input while AI is thinking by setting global waiting flag
	emit_event("GAME_WAITING_STATE_CHANGED", {"waiting": true, "reason": "ai_thinking"})
	
	# Get the AI controller using service locator
	var ai_controller = get_service("AIController")
	if !ai_controller:
		print("PhaseManager: CRITICAL - AIController service not found!")
		
		# Debug registered services
		if Engine.has_singleton("GameManager"):
			var gm = Engine.get_singleton("GameManager")
			print("PhaseManager: Registered services: " + str(gm.services.keys()))
	
	# Signal that AI is thinking (for UI)
	emit_event("AI_THINKING_STARTED")
	
	# Ensure this is long enough to be visible
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	
	# Special handling for weapon placement phase - it's often problematic
	if current_phase == Phase.WEAPON_PLACEMENT:
		print("PhaseManager: Weapon Placement phase detected for AI - ensuring proper setup")
		_initialize_weapon_placement(player_manager.current_player_index)
	
	var ai_processed = false
	
	# Try AI controller first if available
	if ai_controller:
		print("PhaseManager: Using AIController to process turn")
		# Process AI turn with timeout safety
		ai_processed = ai_controller.process_ai_turn_if_needed()
		print("PhaseManager: AI controller returned: " + str(ai_processed))
	else:
		print("PhaseManager: AIController service not found, using fallback")
		# Try fallback approach immediately
		_handle_ai_fallback()
		ai_processed = true
		print("PhaseManager: Using fallback AI handling")
	
	# If AI processing failed after fallback, complete the phase anyway
	if !ai_processed:
		print("PhaseManager: AI processing failed, forcing completion after delay")
		
		# Force completion based on current phase
		match current_phase:
			Phase.BASE_PLACEMENT:
				print("PhaseManager: Forcing base_placement_completed for player " + str(player_manager.current_player_index))
				get_tree().create_timer(1.0).timeout.connect(func():
					base_placement_completed(player_manager.current_player_index)
				)
				
			Phase.WEAPON_PLACEMENT:
				print("PhaseManager: Forcing weapon_placement_completed for player " + str(player_manager.current_player_index))
				get_tree().create_timer(1.0).timeout.connect(func():
					weapon_placement_completed(player_manager.current_player_index)
				)
				
			Phase.TARGETING:
				print("PhaseManager: Forcing targeting_completed for player " + str(player_manager.current_player_index))
				get_tree().create_timer(1.0).timeout.connect(func():
					targeting_completed(player_manager.current_player_index)
				)
	
	# Signal completion
	emit_event("AI_THINKING_COMPLETED")
	
	# Before returning, clear the waiting state AND player tracking
	game_waiting_for_ai = false
	ai_action_in_progress = false
	current_ai_action_player = -1
	emit_event("GAME_WAITING_STATE_CHANGED", {"waiting": false})
	_active_method_calls["_process_ai_turn"] = false
	
	return ai_processed

# Handle AI fallback for various phases
func _handle_ai_fallback():
	match current_phase:
		Phase.BASE_PLACEMENT:
			_force_ai_base_placement()
		Phase.WEAPON_PLACEMENT:
			weapon_placement_completed(player_manager.current_player_index)
		Phase.TARGETING:
			targeting_completed(player_manager.current_player_index)

# Force AI base placement as fallback
func _force_ai_base_placement():
	# This is a backup method if the AI controller fails
	print("Forcing AI base placement as fallback")
	
	# Get the AI opponent
	var ai_opponent = null
	if Engine.has_singleton("GameManager"):
		var game_manager = Engine.get_singleton("GameManager")
		ai_opponent = game_manager.ai_opponent
		
		if !ai_opponent and game_manager.has_service("AIOpponent"):
			ai_opponent = game_manager.get_service("AIOpponent")
	
	if ai_opponent:
		# Perform AI base placement directly
		print("Using AI opponent to perform base placement")
		var result = ai_opponent.perform_base_placement()
		
		# Complete the base placement phase
		await get_tree().create_timer(0.5).timeout
		base_placement_completed(player_manager.current_player_index)
	else:
		push_error("PhaseManager ERROR: Cannot find AI opponent for fallback base placement")
		# Force completion anyway as last resort
		await get_tree().create_timer(0.5).timeout
		
		# Find a valid position for the base
		var base_placed = _emergency_ai_base_placement()
		
		base_placement_completed(player_manager.current_player_index)

# Emergency fallback if all else fails - place base in first valid position
func _emergency_ai_base_placement():
	print("EMERGENCY: Placing AI base in first valid position")
	
	if !game_board or !weapon_types:
		return false
		
	# Get the base weapon data
	var base_data = null
	for weapon in weapon_types.get_all_weapons():
		if weapon.type == "base":
			base_data = weapon
			break
	
	if !base_data:
		return false
		
	# Find a valid position on the right side of the board (AI side)
	var board_size = game_board.grid_size
	var start_x = floor(board_size.x / 2) + 1 # Start from middle-right
	
	for x in range(start_x, board_size.x):
		for y in range(board_size.y):
			var position = Vector2(x, y)
			
			# Check if cell can be occupied
			if game_board.can_place_at(position, base_data.size, 1): # Player 1 = AI
				# Create a dummy base weapon
				var base_weapon = {
					"id": base_data.id,
					"player_id": 1, # AI is player 1
					"position": position,
					"data": base_data,
					"health": base_data.health
				}
				
				# Try to place the base directly through weapon_placement
				if weapon_placement:
					weapon_placement.place_weapon(base_weapon.id, position, 1)
					return true
				else:
					# Last resort - try placing directly in game_board
					game_board.place_weapon_at(position, base_weapon)
					return true
	
	return false

# Check for game over condition
func _check_for_game_over():
	# Count bases for each player
	var player1_bases = 0
	var player2_bases = 0
	
	for x in range(game_board.grid_size.x):
		for y in range(game_board.grid_size.y):
			var cell = game_board.grid[x][y]
			if cell.occupied_by and "weapon_data" in cell.occupied_by:
				if cell.occupied_by.weapon_data.type == "base":
					if cell.occupied_by.player_id == 0:
						player1_bases += 1
					else:
						player2_bases += 1
	
	# Check for winner
	if player1_bases == 0:
		return 1 # Player 2 (AI) wins
	elif player2_bases == 0:
		return 0 # Player 1 wins
	
	return -1 # No winner yet

# Emit an event through the event bus
func emit_event(event_name, event_data = null):
	if event_bus:
		event_bus.emit_event(event_name, event_data)

# Helper method to get a service using service locator pattern
func get_service(service_name):
	if Engine.has_singleton("GameManager"):
		return Engine.get_singleton("GameManager").get_service(service_name)
	return null

# Start the base placement phase for a player
func start_base_placement_phase(player_index):
	# Notify WeaponPlacement to initialize base placement
	if weapon_placement:
		# FIX: Use the correct method or direct property setting like in _initialize_base_placement
		weapon_placement.is_base_placement_phase = true
		weapon_placement.current_player_id = player_index
		weapon_placement.placement_active = true
	else:
		push_error("PhaseManager ERROR: WeaponPlacement is not available for base placement")

	# Update UI and emit events
	emit_event("PHASE_CHANGED", {
		"phase_text": "Base Placement Phase",
		"state": Phase.BASE_PLACEMENT
	})
	emit_event("PLAYER_CHANGED", {
		"player_index": player_index,
		"player_name": player_manager.get_player_name(player_index)
	})

# Start the weapon placement phase for a player
func start_weapon_placement_phase(player_index):
	# Notify WeaponPlacement to initialize weapon placement
	if weapon_placement:
		# FIX: Use direct property setting instead of nonexistent method
		weapon_placement.is_base_placement_phase = false
		weapon_placement.current_player_id = player_index
		weapon_placement.placement_active = true
	else:
		push_error("PhaseManager ERROR: WeaponPlacement is not available for weapon placement")

	# Update UI and emit events
	emit_event("PHASE_CHANGED", {
		"phase_text": "Weapon Placement Phase",
		"state": Phase.WEAPON_PLACEMENT
	})
	emit_event("PLAYER_CHANGED", {
		"player_index": player_index,
		"player_name": player_manager.get_player_name(player_index)
	})

# Add a new method to check if the game is waiting
func is_game_waiting():
	return game_waiting_for_ai
