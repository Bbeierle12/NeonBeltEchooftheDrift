extends Weapon
class_name PulseLaser
## PulseLaser - Rhythm-based exotic weapon
##
## Features:
## - Fires on a rhythm (140 BPM default)
## - Perfect timing (on beat) deals 2x damage
## - Visual and audio feedback for rhythm
## - Rewards player skill and timing

# Pulse stats
var damage_normal: float = 35.0
var damage_perfect: float = 70.0
var bpm: float = 140.0
var timing_window: float = 0.1  # ±0.1s for perfect timing
var beat_interval: float = 0.0
var last_beat_time: float = 0.0
var time_accumulator: float = 0.0

# Visual
var beat_indicator: ColorRect = null


func _ready() -> void:
	super._ready()

	# Create beat indicator
	beat_indicator = ColorRect.new()
	beat_indicator.color = Color(1.0, 0.0, 1.0, 0.0)  # Magenta, initially transparent
	beat_indicator.size = Vector2(40, 40)
	beat_indicator.position = Vector2(-20, -60)
	add_child(beat_indicator)


func initialize(weapon_type: String) -> void:
	"""Initialize pulse laser from data"""
	weapon_id = weapon_type
	weapon_data = DataLoader.get_weapon(weapon_type)

	if weapon_data.is_empty():
		push_error("[PulseLaser] Failed to load weapon data: ", weapon_type)
		return

	# Load stats
	fire_rate = weapon_data.get("fire_rate", 2.33)
	damage_normal = weapon_data.get("damage_normal", 35.0)
	damage_perfect = weapon_data.get("damage_perfect", 70.0)
	bpm = weapon_data.get("bpm", 140.0)
	timing_window = weapon_data.get("timing_window", 0.1)
	heat_per_shot = weapon_data.get("heat_per_shot", 12.0)
	projectile_speed = weapon_data.get("projectile_speed", 1500.0)

	# Calculate beat interval from BPM
	beat_interval = 60.0 / bpm  # Seconds per beat

	# Energy weapon - no ammo
	uses_ammo = false

	print("[PulseLaser] Initialized: ", weapon_data.get("name", weapon_id), " @ ", bpm, " BPM")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Track rhythm
	time_accumulator += delta

	# Beat pulses
	if time_accumulator >= beat_interval:
		time_accumulator -= beat_interval
		last_beat_time = Time.get_ticks_msec() / 1000.0
		_pulse_beat()


func _pulse_beat() -> void:
	"""Visual pulse on beat"""
	if not beat_indicator:
		return

	# Flash indicator
	beat_indicator.color.a = 1.0

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(beat_indicator, "color:a", 0.0, beat_interval * 0.5)


func fire(aim_direction: Vector2) -> void:
	"""Fire with timing check"""
	if not can_fire:
		return

	# Check ammo (if applicable)
	if uses_ammo and current_ammo <= 0:
		out_of_ammo.emit()
		return

	# Apply cooldown
	fire_cooldown = 1.0 / fire_rate
	can_fire = false

	# Generate heat
	if ship and heat_per_shot > 0:
		ship.add_heat(heat_per_shot)

	# Check timing
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var time_since_beat: float = current_time - last_beat_time
	var time_to_next_beat: float = beat_interval - time_since_beat

	var is_perfect: bool = (time_since_beat <= timing_window) or (time_to_next_beat <= timing_window)

	# Determine damage
	base_damage = damage_perfect if is_perfect else damage_normal

	# Visual feedback
	if is_perfect:
		_show_perfect_timing()

	# Spawn projectile
	_spawn_pulse_projectile(aim_direction, is_perfect)


func _spawn_pulse_projectile(direction: Vector2, is_perfect: bool) -> void:
	"""Spawn pulse laser projectile"""
	var projectile: Projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)

	# Position ahead of ship
	projectile.global_position = ship.global_position + direction * 25

	# Calculate damage (with Overdrive bonus if active)
	var damage: float = base_damage
	if ship and ship.is_overdriving():
		damage *= 2.0

	# Initialize projectile
	var velocity: Vector2 = direction.normalized() * projectile_speed
	projectile.initialize(damage, "energy", velocity, 3.0)
	projectile.shooter = ship

	# Visual: Different colors for perfect vs normal
	if is_perfect:
		projectile.modulate = Color(1.0, 0.0, 1.0)  # Magenta (perfect)
		projectile.scale = Vector2.ONE * 1.5
	else:
		projectile.modulate = Color(0.7, 0.0, 0.7)  # Dimmer purple (normal)

	fired.emit(projectile)


func _show_perfect_timing() -> void:
	"""Visual feedback for perfect timing"""
	if not beat_indicator:
		return

	# Flash bright
	beat_indicator.color = Color(1.0, 0.0, 1.0, 1.0)

	# Scale pulse
	var original_scale: Vector2 = beat_indicator.scale
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(beat_indicator, "scale", original_scale * 1.5, 0.1)
	tween.tween_property(beat_indicator, "scale", original_scale, 0.1)
