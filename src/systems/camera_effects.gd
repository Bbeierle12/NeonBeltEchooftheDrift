extends Camera2D
class_name CameraEffects
## CameraEffects - Screen shake and camera juice
##
## Features:
## - Screen shake with intensity and duration
## - Camera trauma system
## - Smooth camera follow
## - Zoom effects
## - Configurable intensity sliders

signal shake_started(intensity: float)
signal shake_ended()

# Shake settings
var shake_enabled: bool = true
var shake_intensity: float = 1.0  # 0.0 - 1.0 slider
var trauma: float = 0.0  # 0.0 - 1.0, decays over time
var trauma_decay: float = 1.0  # Trauma decay per second
var max_shake_offset: float = 50.0
var max_shake_rotation: float = 5.0  # degrees

# Camera follow
var follow_target: Node2D = null
var follow_smoothing: float = 5.0
var follow_offset: Vector2 = Vector2.ZERO

# Zoom
var target_zoom: Vector2 = Vector2.ONE
var zoom_speed: float = 3.0

# Hitstop
var hitstop_enabled: bool = true
var hitstop_duration: float = 0.0
var original_time_scale: float = 1.0


func _ready() -> void:
	# Default camera settings
	enabled = true
	position_smoothing_enabled = true
	position_smoothing_speed = follow_smoothing


func _process(delta: float) -> void:
	# Handle hitstop
	if hitstop_duration > 0:
		hitstop_duration -= delta
		if hitstop_duration <= 0:
			_end_hitstop()
		return

	# Decay trauma
	if trauma > 0:
		trauma = max(trauma - trauma_decay * delta, 0.0)
		if trauma == 0:
			shake_ended.emit()

	# Apply shake if trauma exists
	if trauma > 0 and shake_enabled:
		_apply_shake()
	else:
		offset = Vector2.ZERO
		rotation = 0.0

	# Smooth zoom
	if zoom != target_zoom:
		zoom = zoom.lerp(target_zoom, zoom_speed * delta)

	# Follow target
	if follow_target and is_instance_valid(follow_target):
		var target_position: Vector2 = follow_target.global_position + follow_offset
		global_position = global_position.lerp(target_position, follow_smoothing * delta)


func _apply_shake() -> void:
	"""Apply screen shake based on trauma"""
	if not shake_enabled or shake_intensity == 0.0:
		return

	# Calculate shake amount (squared for better feel)
	var shake_amount: float = pow(trauma, 2) * shake_intensity

	# Random offset
	var max_offset: float = max_shake_offset * shake_amount
	offset.x = randf_range(-max_offset, max_offset)
	offset.y = randf_range(-max_offset, max_offset)

	# Random rotation
	var max_rotation: float = deg_to_rad(max_shake_rotation * shake_amount)
	rotation = randf_range(-max_rotation, max_rotation)


## Screen Shake

func add_trauma(amount: float) -> void:
	"""Add trauma to trigger screen shake"""
	if not shake_enabled:
		return

	trauma = min(trauma + amount, 1.0)

	if trauma > 0:
		shake_started.emit(trauma)


func shake(intensity: float, duration: float = 0.5) -> void:
	"""Trigger screen shake with intensity"""
	add_trauma(intensity)

	# Optional: Force trauma duration
	if duration > 0:
		trauma_decay = intensity / duration


func shake_light() -> void:
	"""Light screen shake (hits, small explosions)"""
	add_trauma(0.2)


func shake_medium() -> void:
	"""Medium screen shake (explosions, big hits)"""
	add_trauma(0.5)


func shake_heavy() -> void:
	"""Heavy screen shake (boss attacks, massive explosions)"""
	add_trauma(0.8)


func shake_extreme() -> void:
	"""Extreme screen shake (boss deaths, catastrophic events)"""
	add_trauma(1.0)


## Hitstop

func hitstop(duration: float = 0.05) -> void:
	"""Freeze frame for impact feel"""
	if not hitstop_enabled or hitstop_duration > 0:
		return

	hitstop_duration = duration
	original_time_scale = Engine.time_scale
	Engine.time_scale = 0.0


func _end_hitstop() -> void:
	"""End hitstop and restore time"""
	Engine.time_scale = original_time_scale
	hitstop_duration = 0.0


## Camera Follow

func set_follow_target(target: Node2D) -> void:
	"""Set camera to follow a target"""
	follow_target = target


func set_follow_offset(offset_vec: Vector2) -> void:
	"""Set offset from follow target"""
	follow_offset = offset_vec


func set_follow_smoothing(smoothing: float) -> void:
	"""Set camera smoothing (higher = smoother)"""
	follow_smoothing = smoothing
	position_smoothing_speed = smoothing


## Zoom

func set_zoom(new_zoom: Vector2, instant: bool = false) -> void:
	"""Set camera zoom"""
	target_zoom = new_zoom
	if instant:
		zoom = new_zoom


func zoom_in(amount: float = 0.2, duration: float = 0.5) -> void:
	"""Zoom in camera"""
	target_zoom = Vector2.ONE * (1.0 + amount)
	zoom_speed = 1.0 / duration if duration > 0 else 999.0


func zoom_out(amount: float = 0.2, duration: float = 0.5) -> void:
	"""Zoom out camera"""
	target_zoom = Vector2.ONE * (1.0 - amount)
	zoom_speed = 1.0 / duration if duration > 0 else 999.0


func reset_zoom(duration: float = 0.5) -> void:
	"""Reset to default zoom"""
	target_zoom = Vector2.ONE
	zoom_speed = 1.0 / duration if duration > 0 else 999.0


## Camera Impulse

func apply_impulse(direction: Vector2, strength: float = 100.0) -> void:
	"""Apply camera impulse in direction"""
	# Move camera in direction, then snap back
	var impulse_offset: Vector2 = direction.normalized() * strength

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "offset", impulse_offset, 0.1)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.3).set_ease(Tween.EASE_OUT)


## Settings

func set_shake_enabled(enabled: bool) -> void:
	"""Enable/disable screen shake"""
	shake_enabled = enabled
	if not enabled:
		offset = Vector2.ZERO
		rotation = 0.0
		trauma = 0.0


func set_shake_intensity(intensity: float) -> void:
	"""Set shake intensity (0.0 - 1.0)"""
	shake_intensity = clamp(intensity, 0.0, 1.0)


func set_hitstop_enabled(enabled: bool) -> void:
	"""Enable/disable hitstop"""
	hitstop_enabled = enabled


## Utility

func reset_camera() -> void:
	"""Reset camera to default state"""
	offset = Vector2.ZERO
	rotation = 0.0
	trauma = 0.0
	target_zoom = Vector2.ONE
	zoom = Vector2.ONE
