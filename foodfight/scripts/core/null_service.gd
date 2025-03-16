class_name NullService
extends RefCounted

# Null object pattern implementation for services
# Returns null for any property access
func _get(property):
	push_warning("Attempted to access property '" + property + "' on NullService")
	return null

# Returns null for any method call    
func _call(method, args):
	push_warning("Attempted to call method '" + method + "' on NullService")
	return null

# No-op implementation for commonly used methods
func connect(_signal_name, _callable, _flags=0):
	push_warning("Attempted to connect signal '" + _signal_name + "' on NullService")
	return OK

func emit_signal(_signal_name, _args=null):
	push_warning("Attempted to emit signal '" + _signal_name + "' on NullService")
	return
	
func has_method(_method):
	return false
