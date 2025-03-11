extends SceneTree

# This script can be executed directly by Godot engine to run tests
# without requiring a scene file

func _init():
	print("Starting test runner...")
	
	# Load and instantiate the test suite
	var TestSuiteClass = load("res://tests/test_suite.gd")
	if TestSuiteClass:
		var test_suite = TestSuiteClass.new()
		get_root().add_child(test_suite)
		print("Test suite loaded successfully")
	else:
		print("ERROR: Failed to load test suite script!")
	
	# Keep running for a short while to process results
	create_timer(2.0).timeout.connect(func():
		# Process multiple frames to help with cleanup
		await process_frame
		
		# Clear any remaining singletons
		var singleton_names = Engine.get_singleton_list()
		for singleton_name in singleton_names:
			if singleton_name == "GameManager" and Engine.has_singleton(singleton_name):
				print("Cleaning up GameManager singleton")
				Engine.unregister_singleton(singleton_name)
				
		# Process one more frame
		await process_frame
		quit()
	)
