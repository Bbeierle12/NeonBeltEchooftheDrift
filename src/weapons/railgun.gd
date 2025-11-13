extends Weapon
class_name Railgun
## Railgun - Charge weapon with infinite pierce
##
## Features:
## - Hold to charge up to 1.5s
## - Damage scales: 200 -> 600
## - Infinite pierce through all targets
## - High heat generation

# Charge mechanics
var is_charging: bool = false
var charge_time: float = 0.0
var max_charge_time: float = 1.5
var min_damage: float = 200.0
var max_damage: float = 600.0
var heat_base: float = 35.0
var heat_charged: float = 50.0

# Visual
var charge_indicator: Line2D = null


func _ready() -> void:
	super._ready()

	# Create charge indicator
	charge_indicator = Line2D.new()
	charge_indicator.width = 2.0
	charge_indicator.default_color = Color(0.0, 1.0, 1.0, 0.6)  # Cyan
	add_child(charge_indicator)


func initialize(weapon_type: String) -> void:
	"""Initialize railgun from data"""
	weapon_id = weapon_type
	weapon_data = DataLoader.get_weapon(weapon_type)

	if weapon_data.is_empty():
		push_error("[Railgun] Failed to load weapon data: ", weapon_type)
		return

	# Load stats
	fire_rate = weapon_data.get("fire_rate", 1.0)
	min_damage = weapon_data.get("damage", 200.0)
	max_damage = weapon_data.get("damage_charged", 600.0)
	max_charge_time = weapon_data.get("charge_time", 1.5)
	heat_base = weapon_data.get("heat_per_shot", 35.0)
	heat_charged = weapon_data.get("heat_per_shot_charged", 50.0)
	projectile_speed = weapon_data.get("projectile_speed", 2000.0)

	# Ammo
	uses_ammo = true
	max_ammo = weapon_data.get("ammo_capacity", 40)
	current_ammo = max_ammo

	print("[Railgun] Initialized: ", weapon_data.get("name", weapon_id))


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Update charge indicator
	if is_charging and ship:
		var charge_percent: float = min(charge_time / max_charge_time, 1.0)
		var aim_direction: Vector2 = (ship.get_global_mouse_position() - ship.global_position).normalized()
		var charge_length: float = 30.0 + (charge_percent * 50.0)

		charge_indicator.clear_points()
		charge_indicator.add_point(Vector2.ZERO)
		charge_indicator.add_point(aim_direction * charge_length)
		charge_indicator.default_color = Color(0.0, 1.0, 1.0, 0.3 + charge_percent * 0.7)
	else:
		charge_indicator.clear_points()


func start_charging() -> void:
	"""Start charging the railgun"""
	if not can_fire or (uses_ammo and current_ammo <= 0):
		return

	is_charging = true
	charge_time = 0.0


func update_charge(delta: float) -> void:
	"""Update charge time while holding fire button"""
	if not is_charging:
		return

	charge_time += delta
	charge_time = min(charge_time, max_charge_time)


func release_shot(aim_direction: Vector2) -> void:
	"""Release charged shot"""
	if not is_charging:
		return

	is_charging = false

	# Can't fire if no ammo or on cooldown
	if not can_fire or (uses_ammo and current_ammo <= 0):
		charge_time = 0.0
		charge_indicator.clear_points()
		return

	# Calculate charge percentage
	var charge_percent: float = min(charge_time / max_charge_time, 1.0)

	# Calculate damage based on charge
	base_damage = lerp(min_damage, max_damage, charge_percent)

	# Calculate heat based on charge
	var heat: float = lerp(heat_base, heat_charged, charge_percent)
	if ship:
		ship.add_heat(heat)

	# Apply cooldown
	fire_cooldown = 1.0 / fire_rate
	can_fire = false

	# Consume ammo
	if uses_ammo:
		current_ammo -= 1

	# Spawn projectile
	_spawn_railgun_projectile(aim_direction, charge_percent)

	# Reset charge
	charge_time = 0.0
	charge_indicator.clear_points()


func _spawn_railgun_projectile(direction: Vector2, charge_percent: float) -> void:
	"""Spawn piercing railgun projectile"""
	var projectile: Projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)

	# Position slightly ahead of ship
	projectile.global_position = ship.global_position + direction * 30

	# Calculate damage (with Overdrive bonus if active)
	var damage: float = base_damage
	if ship and ship.is_overdriving():
		damage *= 2.0

	# Initialize with infinite pierce
	var velocity: Vector2 = direction.normalized() * projectile_speed
	var lifetime: float = weapon_data.get("projectile_lifetime", 3.0)
	projectile.initialize(damage, "kinetic", velocity, lifetime)
	projectile.shooter = ship
	projectile.piercing = true
	projectile.max_pierces = -1  # Infinite pierce

	# Visual: Scale projectile based on charge
	var scale_factor: float = 1.0 + (charge_percent * 0.5)
	projectile.scale = Vector2.ONE * scale_factor

	# Color: Cyan railgun bolt
	if projectile.has_node("Sprite2D"):
		var sprite: Sprite2D = projectile.get_node("Sprite2D")
		sprite.modulate = Color(0.0, 1.0, 1.0)  # Cyan

	fired.emit(projectile)


# Override fire() to prevent instant firing
func fire(_aim_direction: Vector2) -> void:
	# Railgun uses charge mechanics, not instant fire
	pass
