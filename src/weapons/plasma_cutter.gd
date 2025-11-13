extends Weapon
class_name PlasmaCutter
## PlasmaCutter - Short-range cutting beam
##
## Features:
## - Continuous close-range beam (150 unit max range)
## - High DPS (180 per second)
## - Armor penetration (bypasses 50% of armor)
## - Damage falloff after 80 units
## - Requires player to get close for maximum effect

# Plasma cutter stats
var damage_per_sec: float = 180.0
var max_range: float = 150.0
var heat_per_sec: float = 35.0
var armor_penetration: float = 0.5  # 50% armor pen
var damage_falloff_start: float = 80.0

# Beam state
var is_beam_active: bool = false
var beam_line: Line2D = null
var beam_glow: Line2D = null


func _ready() -> void:
	super._ready()

	# Create beam visuals
	beam_line = Line2D.new()
	beam_line.width = 6.0
	beam_line.default_color = Color(0.0, 1.0, 0.5, 0.9)  # Bright green plasma
	add_child(beam_line)

	beam_glow = Line2D.new()
	beam_glow.width = 12.0
	beam_glow.default_color = Color(0.0, 1.0, 0.5, 0.4)  # Glow
	add_child(beam_glow)


func initialize(weapon_type: String) -> void:
	"""Initialize plasma cutter from data"""
	weapon_id = weapon_type
	weapon_data = DataLoader.get_weapon(weapon_type)

	if weapon_data.is_empty():
		push_error("[PlasmaCutter] Failed to load weapon data: ", weapon_type)
		return

	# Load stats
	damage_per_sec = weapon_data.get("damage_per_sec", 180.0)
	max_range = weapon_data.get("max_range", 150.0)
	heat_per_sec = weapon_data.get("heat_per_sec", 35.0)
	armor_penetration = weapon_data.get("armor_penetration", 0.5)
	damage_falloff_start = weapon_data.get("damage_falloff_start", 80.0)

	# Energy weapon - no ammo
	uses_ammo = false

	print("[PlasmaCutter] Initialized: ", weapon_data.get("name", weapon_id))


func fire(aim_direction: Vector2) -> void:
	"""Start firing beam"""
	if not can_fire:
		return

	is_beam_active = true


func stop_firing() -> void:
	"""Stop firing beam"""
	is_beam_active = false

	# Clear beam visuals
	if beam_line:
		beam_line.clear_points()
	if beam_glow:
		beam_glow.clear_points()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_beam_active and ship:
		_process_beam(delta)
	else:
		# Clear beam when not active
		if beam_line:
			beam_line.clear_points()
		if beam_glow:
			beam_glow.clear_points()


func _process_beam(delta: float) -> void:
	"""Process continuous beam"""
	if not ship:
		return

	# Calculate aim direction
	var aim_direction: Vector2 = (ship.get_global_mouse_position() - ship.global_position).normalized()

	# Generate heat
	ship.add_heat(heat_per_sec * delta)

	# Raycast for targets
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: = PhysicsRayQueryParameters2D.new()
	query.from = ship.global_position
	query.to = ship.global_position + aim_direction * max_range
	query.collision_mask = 2 | 16  # Asteroids + enemies
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)

	var beam_end: Vector2
	var hit_something: bool = false

	if result:
		beam_end = result.position
		hit_something = true

		var hit_body: Node2D = result.collider
		if hit_body and hit_body.has_method("take_damage"):
			# Calculate distance for damage falloff
			var distance: float = ship.global_position.distance_to(result.position)
			var damage_mult: float = 1.0

			if distance > damage_falloff_start:
				var falloff_range: float = max_range - damage_falloff_start
				var falloff_amount: float = (distance - damage_falloff_start) / falloff_range
				damage_mult = 1.0 - (falloff_amount * 0.5)  # Up to 50% reduction

			# Calculate damage (with Overdrive bonus if active)
			var damage: float = damage_per_sec * delta * damage_mult
			if ship.is_overdriving():
				damage *= 2.0

			# Apply damage with armor penetration
			# TODO: Implement armor penetration modifier
			hit_body.take_damage(damage, "energy")
	else:
		beam_end = ship.global_position + aim_direction * max_range

	# Update beam visuals
	_update_beam_visual(ship.global_position, beam_end, hit_something)


func _update_beam_visual(start: Vector2, end: Vector2, hitting: bool) -> void:
	"""Update beam line visualization"""
	if not beam_line or not beam_glow:
		return

	# Convert to local space
	var local_end: Vector2 = to_local(end)

	# Main beam
	beam_line.clear_points()
	beam_line.add_point(Vector2.ZERO)
	beam_line.add_point(local_end)

	# Glow
	beam_glow.clear_points()
	beam_glow.add_point(Vector2.ZERO)
	beam_glow.add_point(local_end)

	# Color intensity based on hitting
	if hitting:
		beam_line.default_color = Color(0.0, 1.0, 0.3, 1.0)  # Brighter when hitting
		beam_glow.default_color = Color(0.0, 1.0, 0.3, 0.6)
	else:
		beam_line.default_color = Color(0.0, 1.0, 0.5, 0.7)  # Dimmer when not hitting
		beam_glow.default_color = Color(0.0, 1.0, 0.5, 0.3)


# Override to prevent standard projectile firing
func _spawn_projectile(_direction: Vector2) -> void:
	# Plasma cutter uses beam, not projectiles
	pass
