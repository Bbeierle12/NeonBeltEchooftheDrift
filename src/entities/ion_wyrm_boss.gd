extends Node2D
class_name IonWyrmBoss
## IonWyrm - Second boss encounter for Stormtrack sector
##
## Features:
## - Serpent-like body with 5 segments
## - Rotating weak point (only segment vulnerable at a time)
## - Lightning bolt attacks
## - EMP pulse that disables weapons
## - Spiral movement pattern

signal phase_changed(phase: int)
signal weak_point_changed(segment_id: int)
signal boss_defeated()

enum BossPhase { PHASE_1, PHASE_2, PHASE_3 }

# Boss stats
var max_hp: float = 6000.0
var current_hp: float = 6000.0
var current_phase: BossPhase = BossPhase.PHASE_1

# Segments
var segments: Array[WyrmSegment] = []
var segment_count: int = 5
var segment_hp: float = 1200.0
var current_weak_segment: int = 0
var weak_point_rotate_interval: float = 8.0
var weak_point_timer: float = 8.0

# Movement
var position_center: Vector2
var spiral_radius: float = 200.0
var spiral_speed: float = 1.0
var spiral_angle: float = 0.0
var segment_spacing: float = 50.0

# Attacks
var lightning_interval: float = 3.0
var lightning_timer: float = 3.0
var lightning_damage: float = 80.0
var emp_interval: float = 15.0
var emp_timer: float = 15.0
var emp_radius: float = 300.0
var emp_duration: float = 2.0

# Visual
var is_defeated: bool = false


func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")

	# Get screen center
	position_center = get_viewport_rect().size / 2
	global_position = position_center

	# Create segments
	_setup_segments()


func _setup_segments() -> void:
	"""Create wyrm body segments"""
	for i in range(segment_count):
		var segment: WyrmSegment = WyrmSegment.new()
		add_child(segment)

		segment.initialize(segment_hp, i)
		segment.destroyed.connect(_on_segment_destroyed.bind(i))

		segments.append(segment)

	# Mark first segment as weak point
	segments[0].set_weak_point(true)


func _physics_process(delta: float) -> void:
	if is_defeated:
		return

	# Spiral movement
	spiral_angle += spiral_speed * delta
	global_position = position_center + Vector2(cos(spiral_angle), sin(spiral_angle)) * spiral_radius

	# Update segment positions (follow leader)
	_update_segment_positions()

	# Weak point rotation
	weak_point_timer -= delta
	if weak_point_timer <= 0:
		_rotate_weak_point()
		weak_point_timer = weak_point_rotate_interval

	# Lightning attacks
	lightning_timer -= delta
	if lightning_timer <= 0:
		_lightning_attack()
		lightning_timer = lightning_interval

	# EMP pulse
	emp_timer -= delta
	if emp_timer <= 0:
		_emp_pulse()
		emp_timer = emp_interval


func _update_segment_positions() -> void:
	"""Update segment positions to follow in a line"""
	for i in range(segments.size()):
		if not is_instance_valid(segments[i]):
			continue

		# Calculate position along spiral trail
		var trail_angle: float = spiral_angle - (i * 0.3)
		var trail_radius: float = spiral_radius
		var segment_pos: Vector2 = position_center + Vector2(cos(trail_angle), sin(trail_angle)) * trail_radius

		segments[i].global_position = segment_pos


func _rotate_weak_point() -> void:
	"""Rotate weak point to next living segment"""
	# Remove weak point from current
	if current_weak_segment < segments.size() and is_instance_valid(segments[current_weak_segment]):
		segments[current_weak_segment].set_weak_point(false)

	# Find next living segment
	var attempts: int = 0
	while attempts < segment_count:
		current_weak_segment = (current_weak_segment + 1) % segment_count

		if current_weak_segment < segments.size() and is_instance_valid(segments[current_weak_segment]) and not segments[current_weak_segment].is_destroyed:
			segments[current_weak_segment].set_weak_point(true)
			weak_point_changed.emit(current_weak_segment)
			print("[IonWyrm] Weak point: Segment ", current_weak_segment)
			break

		attempts += 1


func _lightning_attack() -> void:
	"""Fire lightning bolt at player"""
	var player_ship: Ship = _find_player()
	if not player_ship:
		return

	# Create lightning bolt
	var lightning: Line2D = Line2D.new()
	lightning.width = 4.0
	lightning.default_color = Color(0.5, 0.5, 1.0, 0.9)  # Blue lightning
	lightning.add_point(global_position)
	lightning.add_point(player_ship.global_position)
	get_tree().root.add_child(lightning)

	# Deal damage
	if player_ship.has_method("take_damage"):
		player_ship.take_damage(lightning_damage, "energy")

	print("[IonWyrm] Lightning strike!")

	# Fade out lightning
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(lightning, "modulate:a", 0.0, 0.3)
	tween.tween_callback(lightning.queue_free)


func _emp_pulse() -> void:
	"""EMP pulse that disables player weapons"""
	var player_ship: Ship = _find_player()
	if not player_ship:
		return

	var distance: float = global_position.distance_to(player_ship.global_position)
	if distance < emp_radius:
		# TODO: Disable player weapons for duration
		print("[IonWyrm] EMP PULSE! Weapons disabled for ", emp_duration, "s")

		# Visual: EMP ring
		_create_emp_visual()


func _create_emp_visual() -> void:
	"""Create EMP pulse visual"""
	var ring: Line2D = Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(1.0, 1.0, 0.3, 0.8)  # Electric yellow
	get_tree().root.add_child(ring)
	ring.global_position = global_position

	# Draw circle
	var segments_count: int = 32
	for i in range(segments_count + 1):
		var angle: float = (float(i) / float(segments_count)) * TAU
		var point: Vector2 = Vector2(cos(angle), sin(angle)) * emp_radius
		ring.add_point(point)

	# Expand and fade
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(ring, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(ring.queue_free)


func _on_segment_destroyed(segment_id: int) -> void:
	"""Handle segment destruction"""
	print("[IonWyrm] Segment ", segment_id, " destroyed!")

	# Check if all segments destroyed
	var segments_alive: int = 0
	for segment in segments:
		if is_instance_valid(segment) and not segment.is_destroyed:
			segments_alive += 1

	if segments_alive == 0:
		_defeat()
	elif segments_alive <= 3 and current_phase == BossPhase.PHASE_1:
		_enter_phase_2()
	elif segments_alive <= 1 and current_phase == BossPhase.PHASE_2:
		_enter_phase_3()


func _enter_phase_2() -> void:
	"""Enter phase 2 (faster, more aggressive)"""
	current_phase = BossPhase.PHASE_2
	spiral_speed = 1.5
	lightning_interval = 2.0
	emp_interval = 12.0
	weak_point_rotate_interval = 6.0
	phase_changed.emit(2)
	print("[IonWyrm] Entering Phase 2")


func _enter_phase_3() -> void:
	"""Enter phase 3 (desperate)"""
	current_phase = BossPhase.PHASE_3
	spiral_speed = 2.0
	lightning_interval = 1.5
	emp_interval = 8.0
	weak_point_rotate_interval = 4.0
	phase_changed.emit(3)
	print("[IonWyrm] Entering Phase 3")


func _defeat() -> void:
	"""Boss defeated"""
	if is_defeated:
		return

	is_defeated = true
	print("[IonWyrm] DEFEATED!")

	boss_defeated.emit()

	# Award rewards
	GameManager.add_score(15000, "Ion Wyrm defeated")
	GameManager.add_scrap(600)

	# Visual: Multiple explosions
	for i in range(10):
		var explosion: ColorRect = ColorRect.new()
		explosion.color = Color(0.5, 0.5, 1.0, 0.8)  # Blue explosion
		explosion.size = Vector2(80, 80)
		get_tree().root.add_child(explosion)
		explosion.global_position = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))

		var tween: Tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(explosion, "scale", Vector2(2.0, 2.0), 0.6)
		tween.tween_property(explosion, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(explosion.queue_free)

	# Remove boss
	queue_free()


func _find_player() -> Ship:
	"""Find player ship"""
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Ship
	return null


## WyrmSegment - Individual segment of the wyrm body
class WyrmSegment extends Area2D:
	signal destroyed()

	var max_hp: float = 1200.0
	var current_hp: float = 1200.0
	var segment_id: int = 0
	var is_weak_point: bool = false
	var is_destroyed: bool = false

	var visual: ColorRect = null

	func initialize(hp: float, id: int) -> void:
		"""Initialize segment"""
		max_hp = hp
		current_hp = hp
		segment_id = id

		# Setup collision
		collision_layer = 16  # Enemy layer
		collision_mask = 4  # Projectile layer

		# Visual
		visual = ColorRect.new()
		visual.color = Color(0.4, 0.4, 0.8, 0.9)  # Blue segment
		visual.size = Vector2(40, 40)
		visual.position = -visual.size / 2
		add_child(visual)

		# Collision shape
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = 20
		collision_shape.shape = circle
		add_child(collision_shape)

	func set_weak_point(is_weak: bool) -> void:
		"""Mark this segment as the weak point"""
		is_weak_point = is_weak

		if visual:
			if is_weak:
				visual.color = Color(1.0, 0.3, 0.3, 0.9)  # Red (vulnerable)
			else:
				visual.color = Color(0.4, 0.4, 0.8, 0.9)  # Blue (armored)

	func take_damage(amount: float, _damage_type: String = "kinetic") -> void:
		"""Take damage (only if weak point)"""
		if is_destroyed:
			return

		if not is_weak_point:
			# Armored - no damage
			print("[Segment] Armored! Attack weak point (red)")
			return

		current_hp -= amount
		print("[Segment ", segment_id, "] HP: ", current_hp, "/", max_hp)

		# Visual feedback
		if visual:
			var hp_percent: float = current_hp / max_hp
			visual.modulate.a = 0.5 + (hp_percent * 0.5)

		if current_hp <= 0:
			_destroy()

	func _destroy() -> void:
		"""Destroy this segment"""
		if is_destroyed:
			return

		is_destroyed = true
		destroyed.emit()

		# Visual: Explosion
		var explosion: ColorRect = ColorRect.new()
		explosion.color = Color(0.5, 0.5, 1.0, 0.8)
		explosion.size = Vector2(60, 60)
		get_tree().root.add_child(explosion)
		explosion.global_position = global_position

		var tween: Tween = get_tree().create_tween()
		tween.tween_property(explosion, "scale", Vector2(1.5, 1.5), 0.4)
		tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.4)
		tween.tween_callback(explosion.queue_free)

		# Remove segment
		queue_free()
