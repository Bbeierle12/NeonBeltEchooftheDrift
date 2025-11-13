extends Node2D
class_name ArchivistBoss
## Archivist - Third boss encounter for Silent Archive sector
##
## Features:
## - Mirror fight - copies player's weapons
## - Reflects projectiles back at player
## - Teleports around arena
## - Creates holographic duplicates
## - Most difficult boss

signal phase_changed(phase: int)
signal duplicate_spawned(position: Vector2)
signal boss_defeated()

enum BossPhase { PHASE_1, PHASE_2, PHASE_3 }

# Boss stats
var max_hp: float = 8000.0
var current_hp: float = 8000.0
var current_phase: BossPhase = BossPhase.PHASE_1

# Movement
var position_center: Vector2
var teleport_interval: float = 6.0
var teleport_timer: float = 6.0
var teleport_radius: float = 250.0

# Combat
var reflection_chance: float = 0.7  # 70% chance to reflect projectiles
var duplicate_count: int = 0
var max_duplicates: int = 2
var duplicate_spawn_interval: float = 10.0
var duplicate_timer: float = 10.0

# Weapons (mirrors player)
var mirrored_weapons: Array[String] = []

# Visual
var core_visual: ColorRect = null
var shield_visual: Line2D = null
var is_defeated: bool = false


func _ready() -> void:
	add_to_group("bosses")
	add_to_group("enemies")

	# Get screen center
	position_center = get_viewport_rect().size / 2
	global_position = position_center

	# Create visual
	_setup_visual()

	# Mirror player weapons
	_mirror_player_weapons()


func _setup_visual() -> void:
	"""Create boss visual"""
	core_visual = ColorRect.new()
	core_visual.color = Color(0.2, 0.9, 0.4, 0.9)  # Green alien tech
	core_visual.size = Vector2(60, 60)
	core_visual.position = -core_visual.size / 2
	add_child(core_visual)

	# Shield effect
	shield_visual = Line2D.new()
	shield_visual.width = 2.0
	shield_visual.default_color = Color(0.2, 0.9, 0.4, 0.5)
	add_child(shield_visual)
	_update_shield_visual()


func _update_shield_visual() -> void:
	"""Draw shield circle"""
	if not shield_visual:
		return

	shield_visual.clear_points()
	var segments: int = 24
	var radius: float = 50.0
	for i in range(segments + 1):
		var angle: float = (float(i) / float(segments)) * TAU
		var point: Vector2 = Vector2(cos(angle), sin(angle)) * radius
		shield_visual.add_point(point)


func _mirror_player_weapons() -> void:
	"""Copy player's current weapons"""
	var player_ship: Ship = _find_player()
	if not player_ship:
		return

	# TODO: Actually copy player weapons
	# For now, use placeholder weapons
	mirrored_weapons = ["autocannon", "beam_lance"]
	print("[Archivist] Mirrored player weapons: ", mirrored_weapons)


func _physics_process(delta: float) -> void:
	if is_defeated:
		return

	# Teleport
	teleport_timer -= delta
	if teleport_timer <= 0:
		_teleport()
		teleport_timer = teleport_interval

	# Spawn duplicates
	duplicate_timer -= delta
	if duplicate_timer <= 0 and duplicate_count < max_duplicates:
		_spawn_duplicate()
		duplicate_timer = duplicate_spawn_interval

	# Pulsing shield visual
	if shield_visual:
		var pulse: float = 0.3 + 0.2 * sin(Time.get_ticks_msec() * 0.005)
		shield_visual.default_color.a = pulse


func _teleport() -> void:
	"""Teleport to random position"""
	var angle: float = randf() * TAU
	var distance: float = randf_range(100, teleport_radius)
	var new_pos: Vector2 = position_center + Vector2(cos(angle), sin(angle)) * distance

	# Teleport effect
	_create_teleport_effect(global_position)
	global_position = new_pos
	_create_teleport_effect(global_position)

	print("[Archivist] Teleported")


func _create_teleport_effect(pos: Vector2) -> void:
	"""Visual teleport effect"""
	var effect: ColorRect = ColorRect.new()
	effect.color = Color(0.2, 0.9, 0.4, 0.8)
	effect.size = Vector2(80, 80)
	get_tree().root.add_child(effect)
	effect.global_position = pos - effect.size / 2

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(effect, "scale", Vector2(0.0, 0.0), 0.3)
	tween.tween_callback(effect.queue_free)


func _spawn_duplicate() -> void:
	"""Spawn holographic duplicate"""
	var duplicate: ArchivistDuplicate = ArchivistDuplicate.new()
	get_tree().root.add_child(duplicate)

	var angle: float = randf() * TAU
	var distance: float = 200.0
	duplicate.global_position = position_center + Vector2(cos(angle), sin(angle)) * distance

	duplicate.initialize(2000.0)  # Lower HP than main boss
	duplicate.destroyed.connect(_on_duplicate_destroyed)

	duplicate_count += 1
	duplicate_spawned.emit(duplicate.global_position)

	print("[Archivist] Spawned duplicate")


func _on_duplicate_destroyed() -> void:
	"""Handle duplicate destruction"""
	duplicate_count -= 1


func take_damage(amount: float, damage_type: String = "kinetic") -> void:
	"""Take damage with reflection chance"""
	# Check reflection
	if randf() < reflection_chance:
		print("[Archivist] Projectile reflected!")
		# TODO: Reflect projectile back
		return

	# Take damage
	current_hp -= amount
	print("[Archivist] HP: ", current_hp, "/", max_hp)

	# Visual feedback
	if core_visual:
		core_visual.modulate = Color(1.5, 1.5, 1.5)
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(core_visual, "modulate", Color.WHITE, 0.2)

	# Check phase transitions
	var hp_percent: float = current_hp / max_hp
	if hp_percent < 0.66 and current_phase == BossPhase.PHASE_1:
		_enter_phase_2()
	elif hp_percent < 0.33 and current_phase == BossPhase.PHASE_2:
		_enter_phase_3()

	# Check defeat
	if current_hp <= 0:
		_defeat()


func _enter_phase_2() -> void:
	"""Enter phase 2"""
	current_phase = BossPhase.PHASE_2
	teleport_interval = 4.0
	duplicate_spawn_interval = 8.0
	max_duplicates = 3
	reflection_chance = 0.8  # 80% reflection
	phase_changed.emit(2)
	print("[Archivist] Entering Phase 2")


func _enter_phase_3() -> void:
	"""Enter phase 3"""
	current_phase = BossPhase.PHASE_3
	teleport_interval = 3.0
	duplicate_spawn_interval = 6.0
	max_duplicates = 4
	reflection_chance = 0.9  # 90% reflection!
	phase_changed.emit(3)
	print("[Archivist] Entering Phase 3")


func _defeat() -> void:
	"""Boss defeated"""
	if is_defeated:
		return

	is_defeated = true
	print("[Archivist] DEFEATED!")

	boss_defeated.emit()

	# Award rewards
	GameManager.add_score(20000, "Archivist defeated")
	GameManager.add_scrap(800)

	# Destroy all duplicates
	for duplicate in get_tree().get_nodes_in_group("archivist_duplicates"):
		if is_instance_valid(duplicate):
			duplicate.queue_free()

	# Visual: Final explosion
	for i in range(15):
		var explosion: ColorRect = ColorRect.new()
		explosion.color = Color(0.2, 0.9, 0.4, 0.8)
		explosion.size = Vector2(100, 100)
		get_tree().root.add_child(explosion)
		explosion.global_position = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))

		var tween: Tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(explosion, "scale", Vector2(2.5, 2.5), 0.8)
		tween.tween_property(explosion, "modulate:a", 0.0, 0.8)
		tween.chain().tween_callback(explosion.queue_free)

	# Remove boss
	queue_free()


func _find_player() -> Ship:
	"""Find player ship"""
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Ship
	return null


## ArchivistDuplicate - Holographic copy
class ArchivistDuplicate extends Area2D:
	signal destroyed()

	var max_hp: float = 2000.0
	var current_hp: float = 2000.0
	var is_destroyed: bool = false

	var visual: ColorRect = null

	func initialize(hp: float) -> void:
		"""Initialize duplicate"""
		max_hp = hp
		current_hp = hp

		add_to_group("archivist_duplicates")
		add_to_group("enemies")

		# Setup collision
		collision_layer = 16  # Enemy layer
		collision_mask = 4  # Projectile layer

		# Visual (semi-transparent)
		visual = ColorRect.new()
		visual.color = Color(0.2, 0.9, 0.4, 0.5)  # Transparent green
		visual.size = Vector2(50, 50)
		visual.position = -visual.size / 2
		add_child(visual)

		# Collision shape
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(50, 50)
		collision_shape.shape = rect
		add_child(collision_shape)

	func take_damage(amount: float, _damage_type: String = "kinetic") -> void:
		"""Take damage"""
		if is_destroyed:
			return

		current_hp -= amount
		print("[Duplicate] HP: ", current_hp, "/", max_hp)

		if current_hp <= 0:
			_destroy()

	func _destroy() -> void:
		"""Destroy duplicate"""
		if is_destroyed:
			return

		is_destroyed = true
		destroyed.emit()

		# Visual: Flicker out
		if visual:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(visual, "modulate:a", 0.0, 0.3)
			tween.tween_callback(queue_free)
