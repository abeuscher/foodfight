extends Node2D

# Game states
enum GameState {SETUP, PLACEMENT, ATTACK, RESOLUTION}

# Current game state
var current_state = GameState.SETUP

# Player information (pulled from GameData singleton)
var player1_name = ""
var player2_name = ""
var current_player = 1  # 1 or 2 for display purposes
var current_player_index = 0  # 0 or 1 for array indexing

# Player scores
var player1_score = 0
var player2_score = 0

# References to UI elements
var player1_name_label
var player2_name_label
var player1_score_label
var player2_score_label
var turn_label
var phase_label
var resource_label
var weapon_buttons_container

# Reference to the game board
var game_board

# References to weapon systems
var weapon_types
var weapon_placement

func _ready():
	# Get references to UI elements using the correct paths
	var main = get_parent()
	player1_name_label = main.get_node("UI/TopBar/HBoxContainer/Player1Container/NameLabel")
	player2_name_label = main.get_node("UI/TopBar/HBoxContainer/Player2Container/NameLabel")
	player1_score_label = main.get_node("UI/TopBar/HBoxContainer/Player1Container/ScoreLabel")
	player2_score_label = main.get_node("UI/TopBar/HBoxContainer/Player2Container/ScoreLabel")
	turn_label = main.get_node("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel")
	phase_label = main.get_node("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
	resource_label = main.get_node("UI/TopBar/HBoxContainer/ResourceContainer/ResourceLabel")
	weapon_buttons_container = main.get_node("UI/BottomBar/WeaponButtonsContainer")
	
	# Get references to other nodes
	game_board = main.get_node("GameBoard")
	weapon_types = main.get_node("WeaponTypes")
	weapon_placement = main.get_node("WeaponPlacement")
	
	# Get player names from GameData singleton
	player1_name = GameData.player1_name
	player2_name = GameData.player2_name
	
	# Set player names in UI
	player1_name_label.text = player1_name
	player2_name_label.text = player2_name
	
	# Initialize game
	game_board.initialize_grid()
	
	# Initialize weapon systems
	weapon_placement.initialize(game_board, weapon_types)
	
	# Connect weapon placement signals
	if !weapon_placement.is_connected("weapon_placed", Callable(self, "_on_weapon_placed")):
		weapon_placement.connect("weapon_placed", Callable(self, "_on_weapon_placed"))
	if !weapon_placement.is_connected("resource_updated", Callable(self, "_on_resource_updated")):
		weapon_placement.connect("resource_updated", Callable(self, "_on_resource_updated"))
	
	# Connect to the existing EndPlacementButton created in scene
	var end_placement_button = get_parent().get_node("UI/BottomBar/EndPlacementButton")
	if end_placement_button and !end_placement_button.is_connected("pressed", Callable(self, "placement_completed")):
		end_placement_button.pressed.connect(Callable(self, "placement_completed"))
	
	# Start in SETUP state and then move to PLACEMENT
	change_state(GameState.SETUP)
	
	# Update UI
	update_ui()

func _process(_delta):
	# Game state machine
	match current_state:
		GameState.SETUP:
			# Setup phase logic
			# This phase is for initializing the game components
			pass
			
		GameState.PLACEMENT:
			# Placement phase logic is handled by signals
			pass
			
		GameState.ATTACK:
			# Attack phase logic
			# Players choose targets and execute attacks
			pass
			
		GameState.RESOLUTION:
			# Resolution phase logic
			# Resolve attacks and check for game end conditions
			pass

# Change the game state
func change_state(new_state):
	current_state = new_state
	print("Game state changed to: ", GameState.keys()[current_state])
	
	# Perform actions when entering a new state
	match new_state:
		GameState.SETUP:
			print("Setting up the game...")
			# After setup is complete, move to placement phase
			await get_tree().create_timer(0.5).timeout
			change_state(GameState.PLACEMENT)
			
		GameState.PLACEMENT:
			print("Starting placement phase for " + _get_current_player_name())
			# Start placement phase for current player
			weapon_placement.start_placement_phase(current_player_index)
			
		GameState.ATTACK:
			print("Starting attack phase...")
			# Execute attacks automatically
			execute_attacks()
			
		GameState.RESOLUTION:
			print("Resolving attacks...")
			# Resolution phase logic will go here
	
	update_ui()

# Switch to the next player
func next_player():
	current_player = 2 if current_player == 1 else 1
	current_player_index = 1 if current_player == 2 else 0
	print("Current player: " + _get_current_player_name())
	
	# If in placement phase, start placement for the new player
	if current_state == GameState.PLACEMENT:
		weapon_placement.start_placement_phase(current_player_index)
	
	update_ui()

# Handle weapon placement event
func _on_weapon_placed(player_id, weapon_data, _position):
	# Add visual feedback or sound effect here
	print(weapon_data.name + " placed by Player " + str(player_id + 1))
	
	# Check if player can continue placing weapons
	if weapon_placement.get_player_resources(player_id) <= 0:
		print("Player " + str(player_id + 1) + " has no resources left")
		_on_placement_phase_complete(player_id)

# Handle resource update
func _on_resource_updated(player_id, amount):
	# Update resource display
	if player_id == current_player_index:
		resource_label.text = "Resources: " + str(amount)

# Handle completion of placement phase for a player
func _on_placement_phase_complete(player_id):
	# If player 1 (index 0) just finished, switch to player 2
	if player_id == 0:
		next_player()
	# If player 2 (index 1) just finished, move to attack phase
	else:
		change_state(GameState.ATTACK)

# Get the name of the current player
func _get_current_player_name():
	return player1_name if current_player == 1 else player2_name

func update_ui():
	print("update_ui() called, current_state =", GameState.keys()[current_state])
	
	# Debug node paths
	print("Parent node: ", get_parent().name)
	print("BottomBar exists: ", get_parent().has_node("UI/BottomBar"))
	print("EndPlacementButton exists: ", get_parent().has_node("UI/BottomBar/EndPlacementButton"))
	
	# If the path is failing, try a different approach
	var ui_layer = get_parent().get_node("UI")
	if ui_layer:
		var bottom_bar = ui_layer.get_node("BottomBar")
		if bottom_bar:
			print("Found BottomBar directly")
			var end_button = bottom_bar.get_node("EndPlacementButton")
			if end_button:
				print("Found EndPlacementButton directly")
				end_button.visible = (current_state == GameState.PLACEMENT)
				end_button.z_index = 1
				end_button.modulate = Color(1, 0, 0)  # Bright red
	
	# Update score labels
	player1_score_label.text = "Score: " + str(player1_score)
	player2_score_label.text = "Score: " + str(player2_score)
	
	# Update turn label
	turn_label.text = _get_current_player_name() + "'s Turn"
	
	# Update phase label
	var phase_text = GameState.keys()[current_state].capitalize() + " Phase"
	phase_label.text = phase_text
	
	# Update resource label if in placement phase
	if current_state == GameState.PLACEMENT:
		resource_label.text = "Resources: " + str(weapon_placement.get_player_resources(current_player_index))
	else:
		resource_label.text = "Resources: -"
	
	# Show/hide weapon buttons based on game state
	weapon_buttons_container.visible = (current_state == GameState.PLACEMENT)
	
	# Show/hide end placement button
	var end_placement_button = get_parent().get_node("UI/BottomBar/EndPlacementButton")
	if end_placement_button:
		end_placement_button.visible = (current_state == GameState.PLACEMENT)
		print("Found end button")
		if current_state == GameState.PLACEMENT:
			# Make it more visible by bringing it to front and coloring it
			end_placement_button.z_index = 1
			end_placement_button.modulate = Color(1, 0.8, 0.2) # Make it gold colored to stand out
			
# Update player scores
func update_score(player, points):
	if player == 1:
		player1_score += points
	else:
		player2_score += points
	update_ui()

# Complete the placement phase
func placement_completed():
	if current_state == GameState.PLACEMENT:
		weapon_placement.end_placement_phase()
		_on_placement_phase_complete(current_player_index)

# Execute attacks for both players
func execute_attacks():
	print("Executing attacks...")
	
	# For now, just wait a bit and move to resolution phase
	# Since we don't have actual weapons to attack with yet
	await get_tree().create_timer(2.0).timeout
	
	# Move to resolution phase
	change_state(GameState.RESOLUTION)

# This will be expanded when we implement the full attack system
func process_weapon_attack(weapon, player_id):
	# Placeholder for weapon attack processing
	pass

# This will be expanded when we implement the full attack system
func find_targets_for_weapon(weapon, player_id):
	# Placeholder for finding valid targets
	return []

# This will be expanded when we implement the full attack system
func visualize_attack(weapon, target):
	# Placeholder for attack visualization
	pass

# This will be expanded when we implement the full attack system
func apply_damage(weapon, target):
	# Placeholder for damage application
	pass
