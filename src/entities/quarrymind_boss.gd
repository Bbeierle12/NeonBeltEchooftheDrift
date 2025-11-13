extends Node2D
class_name QuarrymindBoss
## Quarrymind - First boss encounter
##
## Features:
## - Core protected by 4 magnetic armor segments
## - Must destroy armor before damaging core
## - Summons asteroids periodically
## - Magnetic pull attack
## - Vulnerability windows after armor destroyed

signal phase_changed(phase: int)
signal armor_destroyed(segment_id: int)
signal boss_defeated()

enum BossPhase { PHASE_1, PHASE_2, PHASE_3, VULNERABLE }

# Boss stats
var max_hp: float = 5000.0
var current_hp: float = 5000.0
var current_phase: BossPhase = BossPhase.PHASE_1

# Armor segments
var armor_segments: Array[ArmorSegment] = []
var armor_count: int = 4
var armor_hp: float = 800.0

# Movement
var position_center: Vector2
var orbit_radius: float = 150.0
var orbit_speed: float = 0.5
var orbit_angle: float = 0.0

# Attacks
var attack_cooldown: float = 0.0
var asteroid_summon_interval: float = 8.0
var summon_timer: float = 8.0
var magnetic_pull_cooldown: float = 12.0
var pull_timer: float = 12.0
var pull_radius: float = 400.0
var pull_strength: float = 200.0

# Visual
var core_visual: ColorRect = null
var is_defeated: bool = false


func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")

	# Get screen center
	position_center = get_viewport_rect().size / 2
	global_position = position_center

	# Create core visual
	_setup_core_visual()

	# Create armor segments
	_setup_armor_segments()


func _setup_core_visual() -> void:
	"""Create boss core visual"""
	core_visual = ColorRect.new()
	core_visual.color = Color(1.0, 0.3, 0.3, 0.9)  # Red core
	core_visual.size = Vector2(80, 80)
	core_visual.position = -core_visual.size / 2
	add_child(core_visual)


func _setup_armor_segments() -> void:
	"""Create protective armor segments"""
	for i in range(armor_count):
		var segment: ArmorSegment = ArmorSegment.new()
		add_child(segment)

		var angle: float = (TAU / armor_count) * i
		segment.initialize(armor_hp, angle, orbit_radius)
		segment.destroyed.connect(_on_armor_segment_destroyed.bind(i))

		armor_segments.append(segment)


func _physics_process(delta: float) -> void:
	if is_defeated:
		return

	# Orbit movement
	orbit_angle += orbit_speed * delta
	global_position = position_center + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius

	# Update armor positions
	for i in range(armor_segments.size()):
		if is_instance_valid(armor_segments[i]):
			var angle: float = orbit_angle + (TAU / armor_count) * i
			armor_segments[i].update_position(global_position, angle, orbit_radius * 1.5)

	# Attack timers
	summon_timer -= delta
	if summon_timer <= 0:
		_summon_asteroids()
		summon_timer = asteroid_summon_interval

	pull_timer -= delta
	if pull_timer <= 0:
		_magnetic_pull_attack()
		pull_timer = magnetic_pull_cooldown


func _summon_asteroids() -> void:
	"""Summon asteroids around the boss"""
	var count: int = 3 + (3 - _count_active_armor())  # More asteroids with less armor

	for i in range(count):
		var angle: float = randf() * TAU
		var distance: float = 200.0
		var spawn_pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * distance
		var velocity: Vector2 = Vector2(cos(angle + PI), sin(angle + PI)) * 100.0

		# TODO: Spawn asteroid
		print("[Quarrymind] Summoning asteroid at ", spawn_pos)


func _magnetic_pull_attack() -> void:
	"""Pull player towards boss"""
	var player_ship: Ship = _find_player()
	if not player_ship:
		return

	var distance: float = global_position.distance_to(player_ship.global_position)
	if distance < pull_radius:
		var direction: Vector2 = (global_position - player_ship.global_position).normalized()
		var pull_force: Vector2 = direction * pull_strength

		# Apply pull force to player
		if "velocity" in player_ship:
			player_ship.velocity += pull_force * get_physics_process_delta_time()

		print("[Quarrymind] Magnetic pull!")


func take_damage(amount: float, damage_type: String = "kinetic") -> void:
	"""Take damage (only when armor destroyed)"""
	# Check if any armor remains
	if _count_active_armor() > 0:
		print("[Quarrymind] Core protected by armor!")
		return

	# Take damage to core
	current_hp -= amount
	print("[Quarrymind] Core HP: ", current_hp, "/", max_hp)

	# Check phase transitions
	var hp_percent: float = current_hp / max_hp
	if hp_percent < 0.66 and current_phase == BossPhase.PHASE_1:
		_enter_phase_2()
	elif hp_percent < 0.33 and current_phase == BossPhase.PHASE_2:
		_enter_phase_3()

	# Check defeat
	if current_hp <= 0:
		_defeat()


func _on_armor_segment_destroyed(segment_id: int) -> void:
	"""Handle armor segment destruction"""
	print("[Quarrymind] Armor segment ", segment_id, " destroyed!")
	armor_destroyed.emit(segment_id)

	# Check if all armor destroyed
	if _count_active_armor() == 0:
		print("[Quarrymind] All armor destroyed! Core vulnerable!")
		current_phase = BossPhase.VULNERABLE


func _count_active_armor() -> int:
	"""Count remaining armor segments"""
	var count: int = 0
	for segment in armor_segments:
		if is_instance_valid(segment) and not segment.is_destroyed:
			count += 1
	return count


func _enter_phase_2() -> void:
	"""Enter phase 2 (more aggressive)"""
	current_phase = BossPhase.PHASE_2
	asteroid_summon_interval = 6.0
	magnetic_pull_cooldown = 9.0
	orbit_speed = 0.7
	phase_changed.emit(2)
	print("[Quarrymind] Entering Phase 2")


func _enter_phase_3() -> void:
	"""Enter phase 3 (desperate)"""
	current_phase = BossPhase.PHASE_3
	asteroid_summon_interval = 4.0
	magnetic_pull_cooldown = 6.0
	orbit_speed = 1.0
	phase_changed.emit(3)
	print("[Quarrymind] Entering Phase 3")


func _defeat() -> void:
	"""Boss defeated"""
	if is_defeated:
		return

	is_defeated = true
	print("[Quarrymind] DEFEATED!")

	boss_defeated.emit()

	# Award rewards
	GameManager.add_score(10000, "Quarrymind defeated")
	GameManager.add_scrap(500)

	# Visual: Explosion
	_create_defeat_vfx()

	# Remove boss
	queue_free()


func _create_defeat_vfx() -> void:
	"""Create boss defeat visual"""
	for i in range(8):
		var explosion: ColorRect = ColorRect.new()
		explosion.color = Color(1.0, 0.3, 0.0, 0.8)
		explosion.size = Vector2(100, 100)
		get_tree().root.add_child(explosion)
		explosion.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))

		var tween: Tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(explosion, "scale", Vector2(2.0, 2.0), 0.6)
		tween.tween_property(explosion, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(explosion.queue_free)


func _find_player() -> Ship:
	"""Find player ship"""
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Ship
	return null


## ArmorSegment - Protective armor piece
class ArmorSegment extends Area2D:
	signal destroyed()

	var max_hp: float = 800.0
	var current_hp: float = 800.0
	var angle_offset: float = 0.0
	var orbit_radius: float = 150.0
	var is_destroyed: bool = false

	var visual: ColorRect = null

	func initialize(hp: float, angle: float, radius: float) -> void:
		"""Initialize armor segment"""
		max_hp = hp
		current_hp = hp
		angle_offset = angle
		orbit_radius = radius

		# Setup collision
		collision_layer = 16  # Enemy layer
		collision_mask = 4  # Projectile layer

		# Visual
		visual = ColorRect.new()
		visual.color = Color(0.5, 0.5, 0.7, 0.9)  # Gray armor
		visual.size = Vector2(50, 50)
		visual.position = -visual.size / 2
		add_child(visual)

		# Collision shape
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(50, 50)
		collision_shape.shape = rect
		add_child(collision_shape)

	func update_position(center: Vector2, angle: float, radius: float) -> void:
		"""Update position relative to boss"""
		if not is_destroyed:
			global_position = center + Vector2(cos(angle), sin(angle)) * radius

	func take_damage(amount: float, _damage_type: String = "kinetic") -> void:
		"""Take damage"""
		if is_destroyed:
			return

		current_hp -= amount
		print("[Armor] HP: ", current_hp, "/", max_hp)

		# Visual feedback
		if visual:
			var hp_percent: float = current_hp / max_hp
			visual.color.a = hp_percent

		if current_hp <= 0:
			_destroy()

	func _destroy() -> void:
		"""Destroy armor segment"""
		if is_destroyed:
			return

		is_destroyed = true
		destroyed.emit()

		# Visual: Break apart
		if visual:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(visual, "scale", Vector2(1.5, 1.5), 0.3)
			tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.3)
			tween.tween_callback(queue_free)
