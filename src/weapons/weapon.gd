extends Node2D
class_name Weapon
## Weapon - Base class for all weapon systems
##
## Handles:
## - Firing logic
## - Heat generation
## - Ammo management
## - Cooldowns
## - Upgrades

signal fired(projectile: Node2D)
signal out_of_ammo()

# Weapon data
var weapon_data: Dictionary = {}
var weapon_id: String = ""

# Stats (from JSON)
var fire_rate: float = 1.0  # Shots per second
var base_damage: float = 10.0
var heat_per_shot: float = 0.0
var projectile_speed: float = 800.0
var max_range: float = 1200.0

# Ammo (for kinetic/explosive weapons)
var uses_ammo: bool = false
var current_ammo: int = 0
var max_ammo: int = 200

# Firing state
var can_fire: bool = true
var fire_cooldown: float = 0.0
var is_firing: bool = false

# Projectile scene
var projectile_scene: PackedScene = preload("res://src/entities/projectile.tscn")

# Reference to ship
var ship: Ship = null


func _ready() -> void:
	ship = get_parent() as Ship


func initialize(weapon_type: String) -> void:
	"""Initialize weapon from data"""
	weapon_id = weapon_type
	weapon_data = DataLoader.get_weapon(weapon_type)

	if weapon_data.is_empty():
		push_error("[Weapon] Failed to load weapon data: ", weapon_type)
		return

	# Load stats
	var stats: Dictionary = weapon_data.get("stats", {})
	fire_rate = stats.get("fireRate", 1.0)
	base_damage = stats.get("baseDamage", 10.0)
	heat_per_shot = stats.get("heatPerShot", 0.0)
	projectile_speed = stats.get("projectileSpeed", 800.0)
	max_range = stats.get("maxRange", 1200.0)

	# Check weapon type for ammo
	var weapon_type_str: String = weapon_data.get("type", "")
	uses_ammo = weapon_type_str in ["kinetic", "explosive"]

	if uses_ammo:
		max_ammo = stats.get("ammoCapacity", 200)
		current_ammo = max_ammo

	print("[Weapon] Initialized: ", weapon_data.get("displayName", weapon_id))


func _physics_process(delta: float) -> void:
	# Update cooldown
	if fire_cooldown > 0:
		fire_cooldown -= delta
		if fire_cooldown <= 0:
			can_fire = true


func fire(aim_direction: Vector2) -> void:
	"""Fire the weapon"""
	if not can_fire:
		return

	# Check ammo
	if uses_ammo and current_ammo <= 0:
		out_of_ammo.emit()
		return

	# Apply cooldown
	fire_cooldown = 1.0 / fire_rate
	can_fire = false

	# Generate heat
	if ship and heat_per_shot > 0:
		ship.add_heat(heat_per_shot)

	# Consume ammo
	if uses_ammo:
		current_ammo -= 1

	# Spawn projectile
	_spawn_projectile(aim_direction)


func _spawn_projectile(direction: Vector2) -> void:
	"""Spawn a projectile (to be overridden by subclasses)"""
	var projectile: Projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)

	# Position at ship
	projectile.global_position = ship.global_position + direction * 20

	# Calculate damage (with Overdrive bonus if active)
	var damage: float = base_damage
	if ship and ship.is_overdriving():
		damage *= 2.0  # Overdrive doubles damage

	# Initialize projectile
	var velocity: Vector2 = direction.normalized() * projectile_speed
	projectile.initialize(damage, weapon_data.get("type", "kinetic"), velocity, max_range / projectile_speed)
	projectile.shooter = ship

	fired.emit(projectile)


func reload(amount: int) -> void:
	"""Reload ammo"""
	if not uses_ammo:
		return

	current_ammo = min(current_ammo + amount, max_ammo)


func get_ammo_percentage() -> float:
	"""Get ammo as percentage (0-1)"""
	if not uses_ammo:
		return 1.0
	return float(current_ammo) / float(max_ammo)
