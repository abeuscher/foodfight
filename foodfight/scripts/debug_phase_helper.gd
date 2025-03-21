extends Node

# This tool helps debug phase mismatches between different files

# PhaseManager Phase enum
const PhaseManagerPhase = preload("res://scripts/states/phase_manager.gd").Phase

# GameStateMachine GameState enum
const GameState = preload("res://scripts/states/game_state_machine.gd").GameState

# Print a comparison of phase enums to help debug mismatches
func print_phase_comparison():
	print("\n=== PHASE ENUM COMPARISON ===")
	print("PhaseManager.Phase:")
	for i in range(len(PhaseManagerPhase.keys())):
		print("  " + str(i) + ": " + PhaseManagerPhase.keys()[i])
		
	print("\nGameStateMachine.GameState:")
	for i in range(len(GameState.keys())):
		print("  " + str(i) + ": " + GameState.keys()[i])
	print("============================\n")
	
	# Check for matching values
	print("Checking enum value consistency:")
	var success = true
	for i in range(min(len(PhaseManagerPhase.keys()), len(GameState.keys()))):
		var phase_name = PhaseManagerPhase.keys()[i]
		var state_name = GameState.keys()[i]
		if phase_name != state_name:
			print("  MISMATCH at index " + str(i) + ": " + phase_name + " vs " + state_name)
			success = false
			
	if success:
		print("  All enum values match correctly!")
	print("============================\n")
	
# Call this after GameManager initialization
func run_checks():
	print_phase_comparison()
	
	# Check services
	if Engine.has_singleton("GameManager"):
		var gm = Engine.get_singleton("GameManager")
		var phase_mgr = gm.get_service("PhaseManager")
		var game_state = gm.get_service("GameStateMachine")
		
		print("\n=== PHASE MANAGER STATE CHECK ===")
		if phase_mgr:
			print("PhaseManager current phase: " + str(phase_mgr.current_phase))
		else:
			print("PhaseManager not found!")
			
		if game_state:
			print("GameStateMachine current state: " + str(game_state.current_state))
		else:
			print("GameStateMachine not found!")
		print("================================\n")
