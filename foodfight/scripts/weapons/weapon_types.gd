# weapon_types.gd
extends Node

# Weapon properties
class WeaponData:
	var id: String
	var name: String
	var description: String
	var attack_range: int
	var damage: int
	var splash_radius: int
	var cooldown: int
	var cost: int
	var size: Vector2  # Size in grid cells
	var texture_path: String
	
	func _init(p_id, p_name, p_desc, p_range, p_damage, p_splash, p_cooldown, p_cost, p_size, p_texture):
		id = p_id
		name = p_name
		description = p_desc
		attack_range = p_range
		damage = p_damage
		splash_radius = p_splash
		cooldown = p_cooldown
		cost = p_cost
		size = p_size
		texture_path = p_texture

# List of all available weapons
var weapons = []

func _ready():
	# Initialize weapon types
	_initialize_weapons()

func _initialize_weapons():
	# Add all weapon types to the list
	
	# Ice Cream Catapult - Long range with medium damage
	weapons.append(WeaponData.new(
		"ice_cream_catapult",
		"Ice Cream Catapult",
		"Launches ice cream scoops at long range. Slow but powerful!",
		8,  # Range (in cells)
		3,  # Damage
		1,  # Splash radius (in cells)
		2,  # Cooldown (in turns)
		3,  # Cost (in resource points)
		Vector2(2, 2),  # Size (2x2 cells)
		"res://assets/weapons/ice_cream_catapult.png"  # Texture path (will need to be created)
	))
	
	# Cream Puff Cannon - Medium range with splash damage
	weapons.append(WeaponData.new(
		"cream_puff_cannon",
		"Cream Puff Cannon",
		"Fires cream puffs at medium range with moderate splash damage.",
		5,  # Range
		2,  # Damage
		2,  # Splash radius
		1,  # Cooldown
		2,  # Cost
		Vector2(2, 1),  # Size (2x1 cells)
		"res://assets/weapons/cream_puff_cannon.png"
	))
	
	# Pie Flinger - Short range but rapid fire
	weapons.append(WeaponData.new(
		"pie_flinger",
		"Pie Flinger",
		"Throws pies at short range. Fast reload and cheap!",
		3,  # Range
		1,  # Damage
		1,  # Splash radius
		0,  # No cooldown
		1,  # Cost
		Vector2(1, 1),  # Size (1x1 cells)
		"res://assets/weapons/pie_flinger.png"
	))
	
	# Cake Bomb - Medium range with large splash damage
	weapons.append(WeaponData.new(
		"cake_bomb",
		"Cake Bomb",
		"Explosive cake with massive splash damage but limited range.",
		4,  # Range
		2,  # Damage
		3,  # Splash radius
		2,  # Cooldown
		3,  # Cost
		Vector2(1, 1),  # Size (1x1 cells)
		"res://assets/weapons/cake_bomb.png"
	))
	
	# Milkshake Mortar - Maximum range
	weapons.append(WeaponData.new(
		"milkshake_mortar",
		"Milkshake Mortar",
		"Lobs milkshakes in an arc for maximum range but less accuracy.",
		10,  # Range
		2,  # Damage
		2,  # Splash radius
		1,  # Cooldown
		4,  # Cost
		Vector2(2, 2),  # Size (2x2 cells)
		"res://assets/weapons/milkshake_mortar.png"
	))
	
	print("Weapon types initialized: ", weapons.size())

# Get weapon data by ID
func get_weapon_by_id(id: String) -> WeaponData:
	for weapon in weapons:
		if weapon.id == id:
			return weapon
	return null

# Get all weapon data
func get_all_weapons() -> Array:
	return weapons
