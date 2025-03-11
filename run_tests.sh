#!/bin/bash

# Load environment variables if .env file exists
if [ -f .env ]; then
  echo "Loading environment variables from .env file"
  source .env
fi

# Configuration with defaults that can be overridden by .env
: ${GODOT_PATH:="C:/Godot/Godot_v4.4-stable_win64.exe"}
: ${PROJECT_PATH:="/e/FoodFightGodot/foodfight"}
: ${TEST_SCRIPT:="res://tests/run_tests.gd"}
: ${LOG_FILE:="test_results.txt"}

# Create logs directory if it doesn't exist
PROJECT_LOGS_DIR="$(dirname "$PROJECT_PATH")/logs"
mkdir -p "$PROJECT_LOGS_DIR"

# Get timestamp for log file
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
PROJECT_LOG_FILE="$PROJECT_LOGS_DIR/test_results_$TIMESTAMP.txt"

# Run tests
echo "Running tests..."
"$GODOT_PATH" --path "$PROJECT_PATH" --script "$TEST_SCRIPT" --headless > "$PROJECT_LOG_FILE" 2>&1

# Copy to the specified LOG_FILE as well
cp "$PROJECT_LOG_FILE" "$LOG_FILE"

# Display results
echo "Test results saved to: $PROJECT_LOG_FILE"
echo "Test results:"
cat "$LOG_FILE"

# Also open the test results viewer if needed
if [ "$1" == "--gui" ]; then
  echo "Opening test results viewer..."
  "$GODOT_PATH" --path "$PROJECT_PATH" --scene res://tests/test_result_viewer.tscn
fi
