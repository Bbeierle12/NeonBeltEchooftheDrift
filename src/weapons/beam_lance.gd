extends Weapon
class_name BeamLance
## Beam Lance - Sustained energy beam that ramps damage over time
##
## Fires a continuous beam that increases damage the longer it's held.
## Refracts through Crystal asteroids for trick shots.

# Beam-specific stats
var dps_base: float = 40.0
var dps_ramp: float = 110.0
var ramp_time: float = 1.5
var heat_per_second: float = 18.0
var beam_width: float = 8.0

# Beam state
var is_beaming: bool = false
var beam_duration: float = 0.0
var current_dps: float = 0.0

# Raycast for beam
var beam_raycast: RayCast2D


func initialize(weapon_type: String = "beam_lance") -> void:
	super.initialize(weapon_type)

	# Load beam-specific stats
	var stats: Dictionary = weapon_data.get("stats", {})
	dps_base = stats.get("dpsBase", 40.0)
	dps_ramp = stats.get("dpsRamp", 110.0)
	ramp_time = stats.get("rampTime", 1.5)
	heat_per_second = stats.get("heatPerSecond", 18.0)
	beam_width = stats.get("beamWidth", 8.0)
	max_range = stats.get("maxRange", 800.0)

	# Create raycast for beam
	beam_raycast = RayCast2D.new()
	add_child(beam_raycast)
	beam_raycast.enabled = false
	beam_raycast.collision_mask = 2 | 16  # asteroids + enemies
	beam_raycast.target_position = Vector2(max_range, 0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_beaming:
		_process_beam(delta)


func fire(aim_direction: Vector2) -> void:
	"""Start firing beam"""
	is_beaming = true
	beam_duration = 0.0
	current_dps = dps_base


func stop_firing() -> void:
	"""Stop firing beam"""
	is_beaming = false
	beam_duration = 0.0
	current_dps = 0.0


func _process_beam(delta: float) -> void:
	"""Process continuous beam firing"""
	if not ship:
		return

	# Update beam duration and ramp damage
	beam_duration += delta
	var ramp_progress: float = min(beam_duration / ramp_time, 1.0)
	current_dps = lerp(dps_base, dps_ramp, ramp_progress)

	# Generate heat
	ship.add_heat(heat_per_second * delta)

	# Apply Overdrive multiplier
	var final_dps: float = current_dps
	if ship.is_overdriving():
		final_dps *= 2.0

	# Raycast to find targets
	beam_raycast.global_rotation = ship.aim_direction.angle()
	beam_raycast.force_raycast_update()

	if beam_raycast.is_colliding():
		var collider: Node2D = beam_raycast.get_collider()
		if collider and collider.has_method("take_damage"):
			# Apply damage per frame
			collider.take_damage(final_dps * delta, "energy")

	# Visual beam (simple line for now)
	# TODO: Add beam VFX
	queue_redraw()


func _draw() -> void:
	"""Draw beam visual"""
	if not is_beaming or not ship:
		return

	# Draw line from ship to target
	var beam_end: Vector2 = ship.aim_direction * max_range
	if beam_raycast.is_colliding():
		beam_end = to_local(beam_raycast.get_collision_point())

	# Beam color (cyan for energy)
	var beam_color: Color = Color(0.4, 0.7, 1.0, 0.8)
	draw_line(Vector2.ZERO, beam_end, beam_color, beam_width)

	# Brighter core
	draw_line(Vector2.ZERO, beam_end, Color(0.8, 0.9, 1.0, 1.0), beam_width * 0.4)
