extends Node

# Makes sure all required services are properly registered with appropriate methods

func _ready():
	# Run on the next frame to ensure GameManager is initialized
	print("ServiceInitializer: Scheduling service verification")
	call_deferred("ensure_all_services")

func ensure_all_services():
	if !Engine.has_singleton("GameManager"):
		push_error("GameManager singleton not found, can't ensure services")
		return
		
	var game_manager = Engine.get_singleton("GameManager")
	
	# Check and fix critical UI services first
	fix_phase_ui_manager(game_manager)
	fix_base_ui_manager(game_manager)  # Renamed from fix_base_ui_manager

func fix_phase_ui_manager(game_manager):
	print("ServiceInitializer: Checking PhaseUIManager...")
	var phase_ui = game_manager.get_service("PhaseUIManager")
	
	# Only create if we don't have a valid one, and we've already checked other sources
	var is_valid_service = phase_ui != null && 
	                       !(phase_ui is NullService) && 
	                       phase_ui.has_method("update_phase_ui")
	
	print("  - PhaseUIManager found: " + str(phase_ui != null))
	print("  - Is NullService: " + str(phase_ui is NullService if phase_ui != null else "N/A"))
	if phase_ui:
		print("  - Has update_phase_ui method: " + str(phase_ui.has_method("update_phase_ui")))
	
	# First check if one exists in the BaseUIManager
	if !is_valid_service:
		var ui_manager = game_manager.get_service("BaseUIManager")  # Changed from BaseUIManager
		if ui_manager and ui_manager.has_method("get_phase_ui_manager"):
			print("  - Checking for PhaseUIManager in BaseUIManager...")
			var manager_phase_ui = ui_manager.get_phase_ui_manager()
			if manager_phase_ui and manager_phase_ui.has_method("update_phase_ui"):
				print("  - Found valid PhaseUIManager in BaseUIManager")
				game_manager.register_service("PhaseUIManager", manager_phase_ui)
				return
		else:
			print("  - BaseUIManager not found or doesn't have get_phase_ui_manager method")
	
	# If still no valid PhaseUIManager, create a new one
	if !is_valid_service:
		print("  - Creating new PhaseUIManager...")
		
		# Find the necessary UI elements
		var turn_label = null
		var phase_label = null
		var title_screen = null
		var player_manager = game_manager.get_service("PlayerManager")
		
		# Look for UI elements in the scene
		var main_scene = get_tree().current_scene
		if main_scene:
			turn_label = main_scene.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/TurnLabel")
			phase_label = main_scene.get_node_or_null("UI/TopBar/HBoxContainer/PhaseContainer/PhaseLabel")
			title_screen = main_scene.get_node_or_null("UI/TitleScreen")
		
		# Create a new PhaseUIManager with guaranteed methods
		var new_phase_ui = Node.new()
		new_phase_ui.name = "PhaseUIManager"
		new_phase_ui.set_script(load("res://scripts/ui/phase_ui_manager.gd"))
		add_child(new_phase_ui)
		
		# Initialize it
		new_phase_ui.initialize(turn_label, phase_label, title_screen, player_manager)
		
		# Register the new PhaseUIManager
		game_manager.register_service("PhaseUIManager", new_phase_ui)
		print("  - New PhaseUIManager created and registered")
		print("  - Has update_phase_ui: " + str(new_phase_ui.has_method("update_phase_ui")))

# Renamed function from fix_base_ui_manager
func fix_base_ui_manager(game_manager):
	print("ServiceInitializer: Checking for BaseUIManager...")  # Changed
	var ui_manager = game_manager.get_service("BaseUIManager")  # Changed
	
	# Check if we have a valid UI manager
	var is_valid_service = ui_manager != null &&
	                       !(ui_manager is NullService) &&
	                       ui_manager.has_method("update_ui")
	
	print("  - BaseUIManager found: " + str(ui_manager != null))  # Changed
	if ui_manager:
		print("  - Has update_ui method: " + str(ui_manager.has_method("update_ui")))
		print("  - Is BaseUIManager: " + str(ui_manager is BaseUIManager))
	
	# Fix the UI manager if needed
	if !is_valid_service:
		print("  - Creating new BaseUIManager...")
		
		# Create a new BaseUIManager with guaranteed methods
		var new_ui_manager = Node.new()
		new_ui_manager.name = "BaseUIManager"
		new_ui_manager.set_script(load("res://scripts/ui/base_ui_manager.gd"))
		add_child(new_ui_manager)
		
		# BaseUIManager handles initialization in its _ready() method
		await get_tree().process_frame
		
		# Register the new UI manager as BaseUIManager service
		game_manager.register_service("BaseUIManager", new_ui_manager)  # Changed
		print("  - New BaseUIManager registered as BaseUIManager service")  # Changed
		
		# Make sure the PhaseUIManager from this new UI manager is registered
		if new_ui_manager.phase_ui_manager:
			game_manager.register_service("PhaseUIManager", new_ui_manager.phase_ui_manager)
			print("  - PhaseUIManager from new UI manager registered")
