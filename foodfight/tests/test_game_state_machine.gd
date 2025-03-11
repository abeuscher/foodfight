extends Node

# Test class for GameStateMachine
class_name GameStateMachineTest

var tests_passed = 0
var tests_failed = 0
var test_suite = null

# References to test dependencies
var game_state_machine = null
var mock_game_board = null
var mock_weapon_types = null
var mock_weapon_placement = null
var mock_targeting_state = null
var mock_attack_state = null
var mock_ui_manager = null
var mock_player_manager = null
var mock_game_manager = null

# Setup function to prepare the test environment
func setup():
	print("Setting up test environment...")
	
	# Set up mock GameManager singleton
	mock_game_manager = load("res://tests/mock_game_manager.gd").new()
	# Add to scene tree temporarily so it doesn't get garbage collected
	add_child(mock_game_manager)
	
	# Inject the mock GameManager into the global scope
	if Engine.has_singleton("GameManager"):
		Engine.unregister_singleton("GameManager") # Remove existing if any
	Engine.register_singleton("GameManager", mock_game_manager)
	
	# Create the actual GameStateMachine instance
	game_state_machine = load("res://scripts/states/game_state_machine.gd").new()
	add_child(game_state_machine) # Add to scene tree
	
	# Create mock objects - Now using the objects from mock_game_manager
	# to avoid duplication and potential memory leaks
	mock_game_board = mock_game_manager.game_board
	mock_weapon_types = mock_game_manager.weapon_types
	mock_weapon_placement = MockWeaponPlacement.new()
	add_child(mock_weapon_placement)
	mock_targeting_state = MockTargetingState.new()
	add_child(mock_targeting_state)
	mock_attack_state = MockAttackState.new()
	add_child(mock_attack_state)
	mock_ui_manager = MockUIManager.new()
	add_child(mock_ui_manager)
	mock_player_manager = MockPlayerManager.new()
	add_child(mock_player_manager)
	
	# Initialize the game state machine with mock objects
	game_state_machine.initialize(
		mock_game_board,
		mock_weapon_types,
		mock_weapon_placement,
		mock_targeting_state,
		mock_attack_state,
		mock_ui_manager,
		mock_player_manager
	)

# Teardown function to clean up after tests
func teardown():
	print("Tearing down test environment...")
	
	# Clean up mock GameManager singleton
	if Engine.has_singleton("GameManager"):
		Engine.unregister_singleton("GameManager")
	
	# The Godot memory manager should automatically clean up all nodes
	# when they are removed from the scene tree
	if mock_game_manager:
		if mock_game_manager.is_inside_tree():
			remove_child(mock_game_manager)
		mock_game_manager.queue_free()
		mock_game_manager = null
	
	if game_state_machine:
		if game_state_machine.is_inside_tree():
			remove_child(game_state_machine)
		game_state_machine.queue_free()
		game_state_machine = null
	
	# Free all additional mock objects
	_queue_free_if_valid(mock_weapon_placement)
	_queue_free_if_valid(mock_targeting_state)
	_queue_free_if_valid(mock_attack_state)
	_queue_free_if_valid(mock_ui_manager)
	_queue_free_if_valid(mock_player_manager)
	
	# Set references to null
	mock_game_board = null
	mock_weapon_types = null
	mock_weapon_placement = null
	mock_targeting_state = null
	mock_attack_state = null
	mock_ui_manager = null
	mock_player_manager = null
	
	# Force garbage collection - using a safer approach without singleton
	if Engine.get_main_loop():
		# Process one more frame to help with cleanup
		await get_tree().process_frame
	
	# Process any remaining nils
	mock_game_board = null
	mock_weapon_types = null
	mock_weapon_placement = null
	mock_targeting_state = null
	mock_attack_state = null
	mock_ui_manager = null
	mock_player_manager = null

# Helper to safely free objects
func _queue_free_if_valid(obj):
	if obj and is_instance_valid(obj):
		if obj.is_inside_tree():
			remove_child(obj)
		obj.queue_free()

# Run all tests in this test class
func run_tests():
	test_suite = get_parent()
	
	setup()
	
	# GDScript doesn't support try/except, so we'll use a different approach for error handling
	test_resolution_to_weapon_placement()
	
	teardown()

# Test case for state transition from RESOLUTION to WEAPON_PLACEMENT
func test_resolution_to_weapon_placement():
	test_suite.current_test_name = "test_resolution_to_weapon_placement"
	
	# Set the current state to RESOLUTION
	game_state_machine.current_state = game_state_machine.GameState.RESOLUTION
	
	# Disable title screen for testing
	mock_ui_manager.skip_title_screen = true
	
	# Simulate the end of the RESOLUTION phase
	game_state_machine._apply_state_change(game_state_machine.GameState.WEAPON_PLACEMENT)
	
	# Verify that the state has changed to WEAPON_PLACEMENT
	test_suite.assert_eq(game_state_machine.current_state, game_state_machine.GameState.WEAPON_PLACEMENT, 
		"State should transition to WEAPON_PLACEMENT")

# Mock classes for testing
class MockGameBoard extends Node:
	func _init():
		pass

class MockWeaponTypes extends Node:
	func _init():
		pass

class MockWeaponPlacement extends Node:
	func _init():
		pass
	
	func start_placement_phase(player_index):
		pass

class MockTargetingState extends Node:
	func _init():
		pass
	
	func start_targeting_phase(player_index):
		pass

class MockAttackState extends Node:
	signal attack_completed
	signal points_awarded
	
	func _init():
		pass
	
	func queue_attacks(player_id, selected_weapons, targets):
		pass
	
	func execute_attacks():
		pass
	
	func check_game_over():
		return -1  # No winner

class MockUIManager extends Node:
	signal title_screen_completed
	
	var skip_title_screen = false
	
	func _init():
		pass
	
	func show_phase_title(phase_name):
		if skip_title_screen:
			emit_signal("title_screen_completed")
	
	func update_ui(current_state, current_player_index):
		pass

class MockPlayerManager extends Node:
	var current_player_index = 0
	var winning_player = -1
	
	func _init():
		pass
	
	func get_current_player_name():
		return "Player 1"
	
	func next_player():
		current_player_index = (current_player_index + 1) % 2
	
	func reset_current_player():
		current_player_index = 0
	
	func add_points(player_id, points):
		pass
	
	func set_winner(player_id):
		winning_player = player_id