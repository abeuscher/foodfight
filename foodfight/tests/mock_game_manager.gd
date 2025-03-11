extends Node

# Mock GameManager for testing purposes
class_name MockGameManager

# Mock properties
var placement_state
var weapon_manager
var targeting_state 
var ui_manager
var player_manager
var game_board
var weapon_types

func _init():
	# Create mock components
	placement_state = MockPlacementState.new()
	weapon_manager = MockWeaponManager.new()
	targeting_state = MockTargetingState.new()
	ui_manager = MockUIManager.new()
	player_manager = MockPlayerManager.new()
	game_board = MockGameBoard.new()
	weapon_types = MockWeaponTypes.new()
	
	# Add mock components as children to prevent memory leaks
	add_child(placement_state)
	add_child(weapon_manager)
	add_child(targeting_state)
	add_child(ui_manager)
	add_child(player_manager)
	add_child(game_board)
	add_child(weapon_types)

# Mock placement state class
class MockPlacementState extends Node:
	signal weapon_buttons_created
	
	func _init():
		pass
		
	func _create_weapon_buttons():
		# Mock implementation that does nothing except log and emit signal
		print("Mock: Creating weapon buttons")
		emit_signal("weapon_buttons_created")
		
	func start_placement_phase(player_index):
		print("Mock: Starting placement phase for player", player_index)

	# Add any other methods that might be called during testing
	func get_selected_weapon():
		return null
		
	func end_placement_phase():
		print("Mock: Ending placement phase")

# Mock weapon manager class
class MockWeaponManager extends Node:
	func collect_weapons():
		# Mock implementation that does nothing
		print("Mock: Collecting weapons")

# Mock targeting state - FIXED: extend Node
class MockTargetingState extends Node:
	func start_targeting_phase(player_index):
		print("Mock: Starting targeting phase for player", player_index)

# Mock UI manager - FIXED: extend Node
class MockUIManager extends Node:
	signal title_screen_completed
	
	var skip_title_screen = false
	
	func show_phase_title(phase_name):
		print("Mock: Showing phase title:", phase_name)
		if skip_title_screen:
			emit_signal("title_screen_completed")
	
	func update_ui(current_state, current_player_index):
		print("Mock: Updating UI for state", current_state, "player", current_player_index)

# Mock player manager - FIXED: extend Node
class MockPlayerManager extends Node:
	var current_player_index = 0
	var winning_player = -1
	
	func get_current_player_name():
		return "Player " + str(current_player_index + 1)
		
	func next_player():
		current_player_index = (current_player_index + 1) % 2
		
	func reset_current_player():
		current_player_index = 0

# Mock game board - already extends Node
class MockGameBoard extends Node:
	pass

# Mock weapon types - already extends Node
class MockWeaponTypes extends Node:
	pass
