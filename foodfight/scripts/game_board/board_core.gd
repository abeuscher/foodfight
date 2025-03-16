extends Node2D

# Grid properties
var grid_size = Vector2(32, 20)  # Increased but not too much
var cell_size = Vector2(24, 24)  # Smaller cells to fit on screen
var grid = []  # Will store our grid data

# Island properties
var island_size = Vector2(12, 12)  # Islands
var island_margin = Vector2(2, 2)  # Margin around islands (water border)
var canal_width = 6  # Canal width for separation

# Terrain types
enum TERRAIN {LAND, WATER}

# Visual state types - update to include hover states
enum VISUAL_STATE {NORMAL, HOVER_VALID, HOVER_INVALID, VALID_TARGET, INVALID_TARGET, SELECTED, ATTACK_TARGET, DAMAGED}

# Reference to cell manager and visual manager
@onready var cell_manager
@onready var visual_manager

# Attack visualization properties
var active_attacks = []
var attack_animation_speed = 3.0  # Cells per second
var targeted_cells = []  # Track cells that have been targeted
var damage_indicators = []  # Track damage indicators

func _ready():
	# Get references to child nodes
	visual_manager = get_node("VisualManager")
	
	# Initialize the grid with default values
	initialize_grid()
	
	# Get reference to WeaponTypes
	var main = get_node("/root/Main")
	var weapon_types_ref = main.get_node("WeaponTypes")
	
	# Initialize VisualManager with the WeaponTypes reference
	visual_manager.initialize(weapon_types_ref)
	
	# Position the grid to be centered in the view
	position = Vector2(50, 80)  # Adjust based on your UI layout
	
	# Draw the grid
	queue_redraw()

func initialize_grid():
	# Reset the grid
	grid = []
	
	# Create a 2D array to represent our grid
	for x in range(grid_size.x):
		var column = []
		for y in range(grid_size.y):
			# Default terrain is water
			var terrain_type = TERRAIN.WATER
			
			# Left island (Player 1)
			if x >= island_margin.x and x < island_margin.x + island_size.x and \
			   y >= island_margin.y and y < island_margin.y + island_size.y:
				terrain_type = TERRAIN.LAND
			
			# Right island (Player 2)
			if x >= grid_size.x - island_size.x - island_margin.x and \
			   x < grid_size.x - island_margin.x and \
			   y >= island_margin.y and y < island_margin.y + island_size.y:
				terrain_type = TERRAIN.LAND
			
			# Add cell data to the grid
			column.append({
				"position": Vector2(x, y),
				"terrain": terrain_type,
				"occupied_by": null,  # Will store weapon or defense later
				"visual_state": VISUAL_STATE.NORMAL  # Add visual state tracking
			})
		grid.append(column)
	
	# If visual manager exists, initialize it
	visual_manager.clear_weapon_sprites()

func _draw():
	# Draw the grid for visualization
	if grid.size() == 0:
		return
		
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell = grid[x][y]
			var rect = Rect2(
				x * cell_size.x, 
				y * cell_size.y, 
				cell_size.x, 
				cell_size.y
			)
			
			# Draw cell with color based on terrain type
			var color = Color.FOREST_GREEN if cell["terrain"] == TERRAIN.LAND else Color.DODGER_BLUE
			draw_rect(rect, color)
			
			# Draw visual state overlays
			match cell.get("visual_state", VISUAL_STATE.NORMAL):
				VISUAL_STATE.HOVER_VALID:
					# Green hover effect for valid targets
					draw_rect(rect, Color(0.0, 1.0, 0.3, 0.3))
					draw_rect(rect, Color(0.0, 1.0, 0.3, 0.8), false, 2)
				VISUAL_STATE.HOVER_INVALID:
					# Red hover effect for invalid targets
					draw_rect(rect, Color(1.0, 0.3, 0.3, 0.3))
					draw_rect(rect, Color(1.0, 0.3, 0.3, 0.8), false, 2)
				VISUAL_STATE.VALID_TARGET:
					# Subtle highlight for valid target cells
					draw_rect(rect, Color(0.0, 1.0, 0.3, 0.15))
				VISUAL_STATE.INVALID_TARGET:
					# Red highlight for invalid targets
					draw_rect(rect, Color(1, 0, 0, 0.4))
					draw_rect(rect, Color(1, 0, 0, 0.8), false, 2)
				VISUAL_STATE.SELECTED:
					# Yellow highlight for selected cells
					draw_rect(rect, Color(1, 1, 0, 0.4))
					draw_rect(rect, Color(1, 1, 0, 0.8), false, 2)
				VISUAL_STATE.ATTACK_TARGET:
					# Orange highlight for attack targets
					draw_rect(rect, Color(1, 0.5, 0, 0.5))
					draw_rect(rect, Color(1, 0.5, 0, 0.9), false, 2)
				VISUAL_STATE.DAMAGED:
					# Red pulsing highlight for damaged cells
					var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1) / 2
					draw_rect(rect, Color(1, 0, 0, 0.3 + 0.2 * pulse))
					draw_rect(rect, Color(1, 0, 0, 0.8), false, 2)
			
			# Draw grid lines
			draw_rect(rect, Color.BLACK, false)
	
	# Draw attack trajectories and projectiles
	for attack in active_attacks:
		if attack.completed:
			continue
		
		var start_world = get_cell_center_world(attack.start)
		var end_world = get_cell_center_world(attack.end)
		
		# Draw trajectory line
		draw_line(start_world, end_world, Color(1.0, 0.5, 0.0, 0.4), 2.0)
		
		# Calculate current position
		var t = attack.progress
		var current_world = start_world.lerp(end_world, t)
		
		# Draw projectile as a circle
		draw_circle(current_world, 5.0, Color(1.0, 0.5, 0.0))
	
	# Draw damage indicators
	for indicator in damage_indicators:
		if indicator.active:
			var pos = get_cell_center_world(indicator.position)
			var font_size = 16
			var damage_text = str(int(indicator.damage))
			
			# Create a dynamic font for damage numbers
			var label_pos = Vector2(pos.x - font_size/2, pos.y - indicator.offset)
			
			# Draw damage number
			draw_string(ThemeDB.fallback_font, label_pos, damage_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 0, 0))

# Function to get cell at world position
func get_cell_at_position(world_position):
	if grid.size() == 0:
		return null
		
	# Adjust position for grid offset
	var adjusted_position = world_position - global_position
	
	var x = int(adjusted_position.x / cell_size.x)
	var y = int(adjusted_position.y / cell_size.y)
	
	# Check if within bounds
	if x >= 0 and x < grid_size.x and y >= 0 and y < grid_size.y:
		return grid[x][y]
	return null

# Function to convert grid coordinates to world position
func grid_to_world(grid_position):
	return Vector2(
		grid_position.x * cell_size.x,
		grid_position.y * cell_size.y
	)

# Get board dimensions in pixels
func get_board_size_pixels():
	return Vector2(grid_size.x * cell_size.x, grid_size.y * cell_size.y)

# Add methods to set visual states
func set_cell_visual_state(grid_position, state):
	var x = int(grid_position.x)
	var y = int(grid_position.y)
	
	if x >= 0 and x < grid_size.x and y >= 0 and y < grid_size.y:
		grid[x][y]["visual_state"] = state
		queue_redraw()  # Request redraw to update visuals
		return true
	return false

# Utility method to reset all cells to normal state
func reset_all_visual_states():
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			grid[x][y]["visual_state"] = VISUAL_STATE.NORMAL
	queue_redraw()

# Add methods for common visual operations
func set_hover_cell(grid_position, is_valid=true):
	reset_all_visual_states()
	if is_valid:
		set_cell_visual_state(grid_position, VISUAL_STATE.HOVER_VALID)
	else:
		set_cell_visual_state(grid_position, VISUAL_STATE.HOVER_INVALID)

func highlight_valid_targets(valid_positions):
	for pos in valid_positions:
		set_cell_visual_state(pos, VISUAL_STATE.VALID_TARGET)

func highlight_cell_as_target(grid_position, is_valid):
	var state = VISUAL_STATE.VALID_TARGET if is_valid else VISUAL_STATE.INVALID_TARGET
	set_cell_visual_state(grid_position, state)

# Get cell center in world coordinates
func get_cell_center_world(grid_position):
	var top_left = grid_to_world(grid_position)
	return top_left + cell_size / 2

# Add a function to clear only hover effects
func reset_hover_effects():
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			# Only clear hover states, preserve other visual states
			if grid[x][y].get("visual_state", VISUAL_STATE.NORMAL) == VISUAL_STATE.HOVER_VALID or \
			   grid[x][y].get("visual_state", VISUAL_STATE.NORMAL) == VISUAL_STATE.HOVER_INVALID:
				grid[x][y]["visual_state"] = VISUAL_STATE.NORMAL
	queue_redraw()

# Add a cell to the targeted list
func add_targeted_cell(grid_position):
	if not grid_position in targeted_cells:
		targeted_cells.append(grid_position)
		set_cell_visual_state(grid_position, VISUAL_STATE.ATTACK_TARGET)

# Clear all targeted cells
func clear_targeted_cells():
	for pos in targeted_cells:
		set_cell_visual_state(pos, VISUAL_STATE.NORMAL)
	targeted_cells = []

# Process function to animate attacks
func _process(delta):
	# Update active attacks
	var i = 0
	while i < active_attacks.size():
		var attack = active_attacks[i]
		
		# Update progress
		attack.progress += delta * attack_animation_speed
		
		# Check if attack completed
		if attack.progress >= 1.0:
			attack.progress = 1.0
			attack.completed = true
			
			# Show impact at target position
			show_impact(attack.end, attack.damage)
			
			# Remove completed attack
			active_attacks.remove_at(i)
		else:
			i += 1
	
	# Update damage indicators
	i = 0
	while i < damage_indicators.size():
		var indicator = damage_indicators[i]
		
		# Update lifetime
		indicator.lifetime -= delta
		indicator.offset += delta * 20  # Float upward
		
		# Remove expired indicators
		if indicator.lifetime <= 0:
			damage_indicators.remove_at(i)
		else:
			i += 1
	
	# Request redraw if we have active animations
	if active_attacks.size() > 0 or damage_indicators.size() > 0:
		queue_redraw()

# Create an attack visualization
func visualize_attack(attacker_position, target_position, damage):
	var attack = {
		"start": attacker_position,
		"end": target_position,
		"progress": 0.0,
		"damage": damage,
		"completed": false
	}
	
	# Add to active attacks array
	active_attacks.append(attack)
	
	# Highlight target cell
	set_cell_visual_state(target_position, VISUAL_STATE.ATTACK_TARGET)
	
	# Request redraw to show the attack immediately
	queue_redraw()

# Show impact effect at a position
func show_impact(position, damage):
	# Set cell to damaged state temporarily
	set_cell_visual_state(position, VISUAL_STATE.DAMAGED)
	
	# Create a damage indicator
	damage_indicators.append({
		"position": position,
		"damage": damage,
		"lifetime": 1.5,  # Show for 1.5 seconds
		"offset": 0,      # Initial vertical offset
		"active": true
	})
	
	# Use a synchronous approach - schedule cell reset
	get_tree().create_timer(0.5).timeout.connect(func():
		var x = int(position.x)
		var y = int(position.y)
		if x >= 0 and x < grid_size.x and y >= 0 and y < grid_size.y:
			if grid[x][y]["visual_state"] == VISUAL_STATE.DAMAGED:
				grid[x][y]["visual_state"] = VISUAL_STATE.NORMAL
				queue_redraw()
	)
