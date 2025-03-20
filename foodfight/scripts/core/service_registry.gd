class_name ServiceRegistry
extends Node

# Dictionary to store registered services
var _services = {}

# Dictionary to track service dependencies
var _dependencies = {}

# Dictionary for method validation requirements
var _required_methods = {
	"PhaseUIManager": ["update_phase_ui", "update_game_phase", "update_current_turn"],
	"BaseUIManager": ["update_ui", "handle_player_turn_update"],
	"WeaponManager": ["create_weapon", "process_attacks"],
	"TargetingManager": ["validate_target", "get_target_cells"]
}

# Validation functions for services based on their type
var _validation_functions = {
	"PhaseUIManager": _validate_phase_ui_manager,
	"BaseUIManager": _validate_base_ui_manager
}

# Singleton instance
static var _instance = null

# Get singleton instance
static func get_instance():
	if _instance == null:
		_instance = ServiceRegistry.new()
	return _instance

# Register a service in the registry
func register_service(service_name: String, service_instance: Object) -> bool:
	if service_instance == null:
		push_error("ServiceRegistry: Cannot register null service: " + service_name)
		return false
		
	# Check if we already have this exact instance registered
	if _services.has(service_name) and _services[service_name] == service_instance:
		return true
		
	# If there's an existing service, validate whether to replace it
	if _services.has(service_name):
		var should_replace = _should_replace_service(service_name, _services[service_name], service_instance)
		if !should_replace:
			print("ServiceRegistry: Keeping existing service: " + service_name)
			return false
	
	# Validate the service
	if !_validate_service(service_name, service_instance):
		push_warning("ServiceRegistry: Service validation failed for: " + service_name)
		# Only register if we don't have a service, even if validation fails
		if !_services.has(service_name):
			_services[service_name] = service_instance
			print("ServiceRegistry: Registered unvalidated service: " + service_name)
			return true
		return false
	
	print("ServiceRegistry: Registered service: " + service_name)
	_services[service_name] = service_instance
	return true

# Get a service from the registry
func get_service(service_name: String):
	if _services.has(service_name):
		return _services[service_name]
	return null

# Check if a service exists
func has_service(service_name: String) -> bool:
	return _services.has(service_name)

# Remove a service
func unregister_service(service_name: String) -> bool:
	if _services.has(service_name):
		_services.erase(service_name)
		return true
	return false

# Add a dependency between services
func add_dependency(service_name: String, depends_on: String) -> void:
	if !_dependencies.has(service_name):
		_dependencies[service_name] = []
		
	if !_dependencies[service_name].has(depends_on):
		_dependencies[service_name].append(depends_on)

# Check if all dependencies for a service are met
func check_dependencies(service_name: String) -> Dictionary:
	var result = {
		"success": true,
		"missing": []
	}
	
	if !_dependencies.has(service_name):
		return result
		
	for dependency in _dependencies[service_name]:
		if !has_service(dependency):
			result.success = false
			result.missing.append(dependency)
	
	return result

# Get all registered services
func get_all_services() -> Dictionary:
	return _services.duplicate()

# Get all service names
func get_service_names() -> Array:
	return _services.keys()

# General validation of a service based on required methods
func _validate_service(service_name: String, service_instance: Object) -> bool:
	# First check if there's a custom validation function
	if _validation_functions.has(service_name):
		var validation_func = _validation_functions[service_name]
		return validation_func.call(service_instance)
		
	# Otherwise check required methods
	if _required_methods.has(service_name):
		var methods = _required_methods[service_name]
		for method in methods:
			if !service_instance.has_method(method):
				push_warning("ServiceRegistry: Service " + service_name + " missing required method: " + method)
				return false
	
	return true

# Decide if we should replace an existing service with a new one
func _should_replace_service(service_name: String, old_service: Object, new_service: Object) -> bool:
	# Never replace with null
	if new_service == null:
		return false
	
	# Always replace null with something
	if old_service == null:
		return true
		
	# Special handling for NullService
	if new_service is NullService:
		return false
		
	if old_service is NullService:
		return true
		
	# Check required methods - if new has methods that old doesn't
	if _required_methods.has(service_name):
		var methods = _required_methods[service_name]
		for method in methods:
			if new_service.has_method(method) and !old_service.has_method(method):
				return true
	
	# Special validation for specific services
	match service_name:
		"PhaseUIManager":
			return _compare_phase_ui_managers(old_service, new_service)
		"BaseUIManager":
			return _compare_base_ui_managers(old_service, new_service)
	
	# By default, don't replace
	return false

# Specific validation for PhaseUIManager
func _validate_phase_ui_manager(service_instance: Object) -> bool:
	if !service_instance.has_method("update_phase_ui"):
		return false
	if !service_instance.has_method("update_game_phase"):
		return false
	if !service_instance.has_method("update_current_turn"):
		return false
	return true

# Compare two PhaseUIManager instances
func _compare_phase_ui_managers(old_service: Object, new_service: Object) -> bool:
	# Check if the new one has phase_label and turn_label set
	if "phase_label" in new_service and new_service.phase_label != null:
		if !("phase_label" in old_service) or old_service.phase_label == null:
			return true
			
	# Check initialization status
	if "is_initialized" in new_service and new_service.is_initialized:
		if !("is_initialized" in old_service) or !old_service.is_initialized:
			return true
	
	return false

# Specific validation for BaseUIManager
func _validate_base_ui_manager(service_instance: Object) -> bool:
	if !service_instance.has_method("update_ui"):
		return false
	return true

# Compare two BaseUIManager instances
func _compare_base_ui_managers(old_service: Object, new_service: Object) -> bool:
	# Check if the new one has important sub-managers
	if "phase_ui_manager" in new_service and new_service.phase_ui_manager != null:
		if !("phase_ui_manager" in old_service) or old_service.phase_ui_manager == null:
			return true
			
	return false
