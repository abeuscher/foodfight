extends Node2D

# References to child nodes (state machine and components)
@onready var game_state_machine
@onready var placement_state

# References to core components
@onready var weapon_buttons_container = $UI/BottomBar/WeaponButtonsContainer

func _ready():
	# Get references to components
	game_state_machine = $GameStateMachine
	placement_state = $PlacementState
	
	# Initialize placement state with references
	placement_state.initialize($WeaponTypes, $WeaponPlacement, weapon_buttons_container)
	
	# Forward to game state machine
	game_state_machine._ready()

# Handle input events
func _input(event):
	# Forward input to appropriate state handler based on current game state
	match game_state_machine.current_state:
		game_state_machine.GameState.PLACEMENT:
			placement_state.handle_input(event)
		game_state_machine.GameState.ATTACK:
			# Attack state handler would go here
			pass