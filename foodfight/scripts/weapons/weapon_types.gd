extends Node

# List of available weapons
var available_weapons = []

func _ready():
	# Initialize weapon types
	_initialize_weapon_types()

# Initialize the available weapon types
func _initialize_weapon_types():
	# Add base structure
	available_weapons.append({
		"id": "food_base",
		"name": "Food Fortress",
		"description": "Your main base structure. Protect it at all costs!",
		"type": "base",
		"size": Vector2(3, 2),
		"cost": 0,  # Bases are free to place
		"attack_range": 0,  # Bases cannot attack
		"damage": 0,
		"splash_radius": 0,
		"cooldown": 0
	})
	
	# Add offensive weapons
	available_weapons.append({
		"id": "ice_cream_catapult",
		"name": "Ice Cream Catapult",
		"description": "Launches ice cream projectiles at medium range",
		"type": "offensive",
		"size": Vector2(2, 2),
		"cost": 5,
		"attack_range": 8,
		"damage": 4,
		"splash_radius": 1,
		"cooldown": 1
	})
	
	available_weapons.append({
		"id": "bread_cannon",
		"name": "Bread Cannon",
		"description": "Fires stale baguettes at long range",
		"type": "offensive",
		"size": Vector2(3, 1),
		"cost": 7,
		"attack_range": 12,
		"damage": 5,
		"splash_radius": 0,
		"cooldown": 2
	})
	
	available_weapons.append({
		"id": "sauce_sprayer",
		"name": "Sauce Sprayer",
		"description": "Short-range condiment assault weapon",
		"type": "offensive",
		"size": Vector2(1, 2),
		"cost": 3,
		"attack_range": 5,
		"damage": 3,
		"splash_radius": 2,
		"cooldown": 1
	})
	
	# Add defensive structures
	available_weapons.append({
		"id": "jello_shield",
		"name": "Jello Shield",
		"description": "Absorbs incoming attacks",
		"type": "defensive",
		"size": Vector2(2, 1),
		"cost": 4,
		"attack_range": 0,
		"damage": 0,
		"splash_radius": 0,
		"cooldown": 0
	})
	
	# Add resource production
	available_weapons.append({
		"id": "donut_factory",
		"name": "Donut Factory",
		"description": "Generates resources each turn",
		"type": "production",
		"size": Vector2(2, 2),
		"cost": 8,
		"attack_range": 0,
		"damage": 0,
		"splash_radius": 0,
		"cooldown": 0
	})
	
	print("Weapon types initialized with ", available_weapons.size(), " types")

# Get a list of all weapon types
func get_all_weapons():
	return available_weapons

# Get a specific weapon by ID
func get_weapon_by_id(id):
	for weapon in available_weapons:
		if weapon.id == id:
			return weapon
	return null

# Get the base weapon type
func get_base_weapon():
	for weapon in available_weapons:
		if "type" in weapon and weapon.type == "base":
			return weapon
	return null

# Get offensive weapons only
func get_offensive_weapons():
	var offensive = []
	for weapon in available_weapons:
		if "type" in weapon and weapon.type == "offensive":
			offensive.append(weapon)
	return offensive

# Get defensive weapons only
func get_defensive_weapons():
	var defensive = []
	for weapon in available_weapons:
		if "type" in weapon and weapon.type == "defensive":
			defensive.append(weapon)
	return defensive

# Get production structures only
func get_production_structures():
	var production = []
	for weapon in available_weapons:
		if "type" in weapon and weapon.type == "production":
			production.append(weapon)
	return production

# Get weapon type as string
func get_type(weapon_id):
	var weapon = get_weapon_by_id(weapon_id)
	if weapon and "type" in weapon:
		return weapon.type
	return ""