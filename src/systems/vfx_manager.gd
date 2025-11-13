extends Node
class_name VFXManager
## VFXManager - Centralized visual effects system
##
## Features:
## - Spawn and manage particle effects
## - Explosion effects with customization
## - Hit impacts and sparks
## - Trails and beams
## - Screen flashes
## - Pooling for performance

signal effect_created(effect: Node2D)

# Effect pools
var explosion_pool: Array[Node2D] = []
var spark_pool: Array[Node2D] = []
var flash_pool: Array[Node2D] = []
var pool_size: int = 20

# Settings
var vfx_enabled: bool = true
var particle_limit: int = 500
var active_particles: int = 0


func _ready() -> void:
	_initialize_pools()


func _initialize_pools() -> void:
	"""Pre-create effect objects for pooling"""
	# Pool initialization can be added here
	pass


## Explosions

func create_explosion(position: Vector2, size: float = 1.0, color: Color = Color.ORANGE) -> void:
	"""Create explosion effect"""
	if not vfx_enabled:
		return

	# Create expanding circle explosion
	var explosion: ColorRect = ColorRect.new()
	explosion.color = color
	explosion.color.a = 0.8
	explosion.size = Vector2(60, 60) * size
	explosion.position = -explosion.size / 2
	get_tree().root.add_child(explosion)
	explosion.global_position = position

	# Animate
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(explosion, "scale", Vector2(2.0, 2.0) * size, 0.4)
	tween.tween_property(explosion, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(explosion.queue_free)

	effect_created.emit(explosion)


func create_multi_explosion(position: Vector2, count: int = 5, radius: float = 50.0, color: Color = Color.ORANGE) -> void:
	"""Create multiple explosions in area"""
	for i in range(count):
		var offset: Vector2 = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
		var delay: float = i * 0.1

		get_tree().create_timer(delay).timeout.connect(func():
			create_explosion(position + offset, randf_range(0.6, 1.2), color)
		)


## Impacts

func create_hit_impact(position: Vector2, direction: Vector2 = Vector2.ZERO) -> void:
	"""Create hit impact effect"""
	if not vfx_enabled:
		return

	# Flash at impact point
	var flash: ColorRect = ColorRect.new()
	flash.color = Color.WHITE
	flash.size = Vector2(12, 12)
	flash.position = -flash.size / 2
	get_tree().root.add_child(flash)
	flash.global_position = position

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.15)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)


func create_sparks(position: Vector2, count: int = 5, color: Color = Color.YELLOW) -> void:
	"""Create spark particles"""
	if not vfx_enabled:
		return

	for i in range(count):
		var spark: ColorRect = ColorRect.new()
		spark.color = color
		spark.size = Vector2(3, 3)
		get_tree().root.add_child(spark)
		spark.global_position = position

		# Random direction
		var angle: float = randf() * TAU
		var speed: float = randf_range(50, 150)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var target: Vector2 = position + direction * speed

		var tween: Tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position", target, 0.3)
		tween.tween_property(spark, "modulate:a", 0.0, 0.3)
		tween.chain().tween_callback(spark.queue_free)


## Beams and Lines

func create_beam_flash(from: Vector2, to: Vector2, width: float = 3.0, color: Color = Color.CYAN, duration: float = 0.2) -> void:
	"""Create temporary beam line"""
	if not vfx_enabled:
		return

	var beam: Line2D = Line2D.new()
	beam.width = width
	beam.default_color = color
	beam.add_point(from)
	beam.add_point(to)
	get_tree().root.add_child(beam)

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, duration)
	tween.tween_callback(beam.queue_free)


func create_lightning_arc(from: Vector2, to: Vector2, segments: int = 5, color: Color = Color(0.5, 0.5, 1.0)) -> void:
	"""Create lightning arc effect"""
	if not vfx_enabled:
		return

	var lightning: Line2D = Line2D.new()
	lightning.width = 2.0
	lightning.default_color = color

	# Generate jagged path
	lightning.add_point(from)
	for i in range(1, segments):
		var t: float = float(i) / float(segments)
		var point: Vector2 = from.lerp(to, t)
		# Add random offset
		var perpendicular: Vector2 = (to - from).orthogonal().normalized()
		var offset: float = randf_range(-20, 20)
		point += perpendicular * offset
		lightning.add_point(point)
	lightning.add_point(to)

	get_tree().root.add_child(lightning)

	# Fade out
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(lightning, "modulate:a", 0.0, 0.15)
	tween.tween_callback(lightning.queue_free)


## Screen Effects

func create_screen_flash(color: Color = Color.WHITE, intensity: float = 0.5, duration: float = 0.1) -> void:
	"""Create full-screen flash"""
	if not vfx_enabled:
		return

	var flash: ColorRect = ColorRect.new()
	flash.color = color
	flash.color.a = intensity
	flash.size = get_viewport().get_visible_rect().size
	flash.z_index = 100  # Top layer
	get_tree().root.add_child(flash)

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)


func create_radial_flash(position: Vector2, radius: float = 200.0, color: Color = Color.WHITE) -> void:
	"""Create radial flash effect"""
	if not vfx_enabled:
		return

	var flash: ColorRect = ColorRect.new()
	flash.color = color
	flash.size = Vector2(radius * 2, radius * 2)
	flash.position = -flash.size / 2
	get_tree().root.add_child(flash)
	flash.global_position = position

	var tween: Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(flash.queue_free)


## Trails

func create_trail(from: Vector2, to: Vector2, width: float = 2.0, color: Color = Color.WHITE, fade_time: float = 0.3) -> void:
	"""Create fading trail"""
	if not vfx_enabled:
		return

	var trail: Line2D = Line2D.new()
	trail.width = width
	trail.default_color = color
	trail.add_point(from)
	trail.add_point(to)
	get_tree().root.add_child(trail)

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, fade_time)
	tween.tween_callback(trail.queue_free)


## Damage Numbers

func create_damage_number(position: Vector2, damage: float, color: Color = Color.WHITE) -> void:
	"""Create floating damage number"""
	if not vfx_enabled:
		return

	var label: Label = Label.new()
	label.text = str(int(damage))
	label.add_theme_font_size_override("font_size", 16)
	label.modulate = color
	get_tree().root.add_child(label)
	label.global_position = position - Vector2(10, 10)

	# Float up and fade
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", position.y - 50, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


## Shield Effects

func create_shield_hit(position: Vector2, radius: float = 40.0) -> void:
	"""Create shield impact ripple"""
	if not vfx_enabled:
		return

	var ripple: Line2D = Line2D.new()
	ripple.width = 2.0
	ripple.default_color = Color(0.0, 0.8, 1.0, 0.8)

	# Draw circle
	var segments: int = 24
	for i in range(segments + 1):
		var angle: float = (float(i) / float(segments)) * TAU
		var point: Vector2 = Vector2(cos(angle), sin(angle)) * radius
		ripple.add_point(point)

	get_tree().root.add_child(ripple)
	ripple.global_position = position

	# Expand and fade
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(ripple, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(ripple.queue_free)


## Utility

func set_vfx_enabled(enabled: bool) -> void:
	"""Enable/disable VFX"""
	vfx_enabled = enabled


func clear_all_effects() -> void:
	"""Remove all active effects"""
	# Would clear pools and active effects
	pass
