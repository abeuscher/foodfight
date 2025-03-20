class_name ServiceDiagnostic
extends Node

signal diagnostic_completed(issues_found, fixed_count)

var _issues_found = []
var _fixed_count = 0

func _ready():
	# Run diagnostics with a slight delay to ensure all initialization is done
	await get_tree().create_timer(0.5).timeout
	run_service_diagnostic()

# Perform diagnostic check without creating new services
func run_service_diagnostic():
	if !Engine.has_singleton("GameManager"):
		push_warning("ServiceDiagnostic: GameManager singleton not available")
		emit_signal("diagnostic_completed", ["GameManager singleton not available"], 0)
		return
		
	var game_manager = Engine.get_singleton("GameManager")
	_issues_found.clear()
	_fixed_count = 0
	
	# Check critical services
	print("ServiceDiagnostic: Running service integrity check...")
	var critical_services = ["BaseUIManager", "PhaseUIManager", "GameStateMachine"]
	
	for service_name in critical_services:
		var service = game_manager.get_service(service_name)
		var is_null_service = service != null && service is NullService
		
		if service == null || is_null_service:
			var issue = "Missing critical service: " + service_name
			print("ServiceDiagnostic: " + issue)
			_issues_found.append(issue)
			
			# For PhaseUIManager, check if it exists in BaseUIManager
			if service_name == "PhaseUIManager":
				_check_phase_ui_in_game_ui(game_manager)
	
	# Check for UI manager references
	var ui_manager = game_manager.get_service("BaseUIManager")
	if ui_manager != null and !(ui_manager is NullService):
		var required_props = ["phase_ui_manager", "player_ui_manager"]
		for prop in required_props:
			if !(prop in ui_manager) or ui_manager[prop] == null:
				var issue = "BaseUIManager missing " + prop
				print("ServiceDiagnostic: " + issue)
				_issues_found.append(issue)
	
	# Check for circular dependencies
	_check_for_circular_dependencies()
	
	print("ServiceDiagnostic completed: Found " + str(_issues_found.size()) + " issues, fixed " + str(_fixed_count))
	emit_signal("diagnostic_completed", _issues_found, _fixed_count)

# Check if PhaseUIManager exists in UI manager
func _check_phase_ui_in_game_ui(game_manager):
	var ui_manager = game_manager.get_service("BaseUIManager")
	if ui_manager and "phase_ui_manager" in ui_manager and ui_manager.phase_ui_manager != null:
		print("ServiceDiagnostic: Found PhaseUIManager in BaseUIManager, registering it")
		game_manager.register_service("PhaseUIManager", ui_manager.phase_ui_manager)
		_fixed_count += 1

# Check for circular dependencies in event listeners
func _check_for_circular_dependencies():
	if !Engine.has_singleton("GameManager"):
		return
		
	var game_manager = Engine.get_singleton("GameManager")
	var event_bus = game_manager.get_service("EventBus")
	
	if event_bus and event_bus.has_method("get_registered_listeners"):
		var listeners = event_bus.get_registered_listeners()
		print("ServiceDiagnostic: Event listeners: " + str(listeners))
		
		# Check specific problematic event patterns
		var problematic_patterns = [
			["UI_UPDATE_REQUIRED", "STATE_CHANGED"],
			["PHASE_CHANGED", "UI_UPDATE_REQUIRED"]
		]
		
		for pattern in problematic_patterns:
			if listeners.has(pattern[0]) and listeners.has(pattern[1]):
				var issue = "Potential circular event dependency: " + pattern[0] + " <-> " + pattern[1]
				print("ServiceDiagnostic: " + issue)
				_issues_found.append(issue)

# Report all current diagnostic issues
func get_diagnostic_issues():
	return _issues_found
