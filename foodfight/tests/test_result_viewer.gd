extends Control

func _ready():
	var log_file_path = "user://logs/latest_test_results.log"
	var log_content = $MarginContainer/VBoxContainer/ScrollContainer/LogContent
	
	# Check if test results file exists
	if FileAccess.file_exists(log_file_path):
		var file = FileAccess.open(log_file_path, FileAccess.READ)
		log_content.text = file.get_as_text()
		
		# Add coloring for pass/fail
		log_content.text = log_content.text.replace("✅", "[color=green]✅[/color]")
		log_content.text = log_content.text.replace("❌", "[color=red]❌[/color]")
	else:
		log_content.text = "No test results found. Run tests first."
	
	# Connect button
	$MarginContainer/VBoxContainer/RunAgainButton.pressed.connect(_on_run_again_pressed)

func _on_run_again_pressed():
	# Run the test suite
	var test_runner = load("res://tests/test_runner.tscn").instantiate()
	get_tree().root.add_child(test_runner)
	queue_free()
