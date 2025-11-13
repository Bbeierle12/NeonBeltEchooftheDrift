extends Asteroid
class_name CrystalAsteroid
## CrystalAsteroid - Special asteroid that refracts beam weapons
##
## Features:
## - Refracts energy beam weapons at angles
## - Creates additional damage rays
## - Resistant to energy damage (50%)
## - Weak to kinetic damage (150%)

signal beam_refracted(origin: Vector2, direction: Vector2, damage: float)

# Refraction properties
var refract_angle_range: float = deg_to_rad(45)  # ±45 degrees
var refract_damage_mult: float = 0.7  # 70% of original damage
var max_refraction_distance: float = 600.0
var refraction_count: int = 2  # Number of refraction beams


func initialize(type: String, init_size: AsteroidSize, spawn_pos: Vector2, spawn_velocity: Vector2) -> void:
	"""Initialize crystal asteroid"""
	super.initialize(type, init_size, spawn_pos, spawn_velocity)

	# Override damage modifiers for crystal type
	if asteroid_data.is_empty():
		asteroid_data = {
			"damageModifiers": {
				"energy": 0.5,   # 50% damage from energy (resistant)
				"kinetic": 1.5,  # 150% damage from kinetic (weak)
				"explosive": 1.0
			}
		}


func take_damage(amount: float, damage_type: String = "kinetic", hit_position: Vector2 = Vector2.ZERO, hit_direction: Vector2 = Vector2.ZERO) -> void:
	"""Take damage and refract beams"""
	# Apply normal damage with modifiers
	super.take_damage(amount, damage_type)

	# Refract energy beams
	if damage_type == "energy" and hit_direction.length() > 0.1:
		_refract_beam(hit_position, hit_direction, amount * refract_damage_mult)


func _refract_beam(entry_point: Vector2, incident_direction: Vector2, damage: float) -> void:
	"""Create refracted beams at angles from the impact point"""
	# Calculate refraction angles
	var incident_angle: float = incident_direction.angle()

	# Create multiple refraction rays
	for i in range(refraction_count):
		# Alternate between positive and negative angles
		var angle_offset: float = refract_angle_range * (0.5 + 0.5 * (i % 2) * (1 if i % 2 == 0 else -1))
		var refract_angle: float = incident_angle + angle_offset

		var refract_direction: Vector2 = Vector2(cos(refract_angle), sin(refract_angle))

		# Cast refracted ray
		_cast_refracted_ray(entry_point, refract_direction, damage)

		# Emit signal for visual effects
		beam_refracted.emit(entry_point, refract_direction, damage)


func _cast_refracted_ray(origin: Vector2, direction: Vector2, damage: float) -> void:
	"""Cast a refracted ray and damage targets along its path"""
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: = PhysicsRayQueryParameters2D.new()
	query.from = origin
	query.to = origin + direction * max_refraction_distance
	query.collision_mask = 2 | 16  # Asteroids + enemies
	query.hit_from_inside = true

	var result: Dictionary = space_state.intersect_ray(query)

	if result:
		var hit_body: Node2D = result.collider
		if hit_body and hit_body != self and hit_body.has_method("take_damage"):
			# Deal refracted damage
			hit_body.take_damage(damage, "energy")

			# Visual: Draw refracted beam
			_draw_refraction_beam(origin, result.position)

			# Chain refraction if hit another crystal
			if hit_body is CrystalAsteroid:
				# Recursive refraction (limited depth)
				pass


func _draw_refraction_beam(from: Vector2, to: Vector2) -> void:
	"""Draw visual for refracted beam"""
	var beam_line: Line2D = Line2D.new()
	beam_line.add_point(from)
	beam_line.add_point(to)
	beam_line.width = 3.0
	beam_line.default_color = Color(0.5, 0.8, 1.0, 0.8)  # Light blue/cyan
	get_tree().root.add_child(beam_line)

	# Fade out beam
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(beam_line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(beam_line.queue_free)


func _setup_visual() -> void:
	"""Override visual setup for crystal appearance"""
	super._setup_visual()

	# Add crystal-specific visual (cyan/blue tint)
	if has_node("Visual"):
		var visual: ColorRect = get_node("Visual")
		visual.color = Color(0.3, 0.7, 1.0, 0.8)  # Cyan crystal


# Override to use crystal JSON data
func _get_asteroid_type() -> String:
	return "crystal"
