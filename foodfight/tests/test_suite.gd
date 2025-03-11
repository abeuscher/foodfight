extends Node

# Script that manages multiple test cases

class_name TestSuite

var tests_passed = 0
var tests_failed = 0
var test_files = []
var current_test_name = ""
var log_content = ""

# Updated log file path with timestamp
var logs_dir = "user://logs"
var log_file_path = ""

func _ready():
	# Create timestamp for the log file
	var datetime = Time.get_datetime_dict_from_system()
	var timestamp = "%04d-%02d-%02d_%02d-%02d-%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	# Ensure logs directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")
	
	# Set log file path with timestamp
	log_file_path = logs_dir + "/test_results_" + timestamp + ".log"
	
	print_log("Starting test suite...")
	collect_test_files()
	run_tests()
	report_results()
	save_log_to_file()
	
	# Create a label to show results in GUI mode
	var results_label = Label.new()
	results_label.text = log_content
	results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var scroll = ScrollContainer.new()
	scroll.size = Vector2(get_viewport().size.x, get_viewport().size.y)
	scroll.add_child(results_label)
	add_child(scroll)
	
	# Don't quit immediately to allow viewing results in GUI
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

func print_log(message):
	print(message) # Print to console
	log_content += message + "\n" # Store for file output

func collect_test_files():
	# Get all test scripts in the tests directory
	var dir = DirAccess.open("res://tests")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# Only include files that start with "test_" and aren't utility files
			if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_suite.gd":
				# Make sure we're not including mock files or the runner itself
				if not file_name.begins_with("test_result_") and file_name != "test_runner.gd":
					test_files.append(file_name.replace(".gd", ""))
			file_name = dir.get_next()
	else:
		print_log("Error: Could not open tests directory")
	
	print_log("Found test files: " + str(test_files))

func run_tests():
	print_log("\n===== RUNNING TESTS =====")
	for test_file in test_files:
		var script_path = "res://tests/" + test_file + ".gd"
		print_log("Loading test script: " + script_path)
		
		var script = load(script_path)
		if script:
			var test_instance = script.new()
			if test_instance.has_method("run_tests"):
				print_log("\n----- Running " + test_file + " -----")
				add_child(test_instance)
				test_instance.run_tests()
				tests_passed += test_instance.tests_passed
				tests_failed += test_instance.tests_failed
				remove_child(test_instance)
			else:
				print_log("Warning: " + test_file + " lacks run_tests() method")
		else:
			print_log("Error: Failed to load script " + script_path)

func report_results():
	print_log("\n===== TEST RESULTS =====")
	print_log("Tests passed: " + str(tests_passed))
	print_log("Tests failed: " + str(tests_failed))
	print_log("Total tests: " + str(tests_passed + tests_failed))
	if tests_failed == 0:
		print_log("\n✅ ALL TESTS PASSED")
	else:
		print_log("\n❌ SOME TESTS FAILED")

func save_log_to_file():
	var file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if file:
		file.store_string(log_content)
		print_log("Test results saved to: " + log_file_path)
		# Also save a copy to the latest file for easy access
		var latest_file = FileAccess.open(logs_dir + "/latest_test_results.log", FileAccess.WRITE)
		if latest_file:
			latest_file.store_string(log_content)
	else:
		print_log("Error: Could not write to log file")

func assert_eq(actual, expected, message=""):
	var test_message = current_test_name + ": "
	if message != "":
		test_message += message + " - "
	
	if actual == expected:
		tests_passed += 1
		print_log("✅ " + test_message + "PASS")
		return true
	else:
		tests_failed += 1
		print_log("❌ " + test_message + "FAIL - Expected " + str(expected) + ", got " + str(actual))
		return false

func assert_true(condition, message=""):
	return assert_eq(condition, true, message)

func assert_false(condition, message=""):
	return assert_eq(condition, false, message)
