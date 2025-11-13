extends Weapon
class_name Flak
## Flak - Timed airburst weapon for area denial
##
## Features:
## - Projectiles explode after fixed time (0.8s)
## - Area-of-effect damage on detonation
## - High fire rate for saturation
## - Direct hit damage + AoE damage

# Flak stats
var damage_direct: float = 30.0
var damage_aoe: float = 50.0
var aoe_radius: float = 100.0
var airburst_time: float = 0.8

# Flak projectile scene
var flak_projectile_scene: PackedScene = preload("res://src/entities/projectile.tscn")


func initialize(weapon_type: String) -> void:
	"""Initialize flak from data"""
	weapon_id = weapon_type
	weapon_data = DataLoader.get_weapon(weapon_type)

	if weapon_data.is_empty():
		push_error("[Flak] Failed to load weapon data: ", weapon_type)
		return

	# Load stats
	fire_rate = weapon_data.get("fire_rate", 4.0)
	damage_direct = weapon_data.get("damage_direct", 30.0)
	damage_aoe = weapon_data.get("damage_aoe", 50.0)
	aoe_radius = weapon_data.get("aoe_radius", 100.0)
	airburst_time = weapon_data.get("airburst_time", 0.8)
	heat_per_shot = weapon_data.get("heat_per_shot", 8.0)
	projectile_speed = weapon_data.get("projectile_speed", 700.0)

	# Ammo
	uses_ammo = true
	max_ammo = weapon_data.get("ammo_capacity", 120)
	current_ammo = max_ammo

	print("[Flak] Initialized: ", weapon_data.get("name", weapon_id))


func _spawn_projectile(direction: Vector2) -> void:
	"""Spawn flak projectile with timed airburst"""
	var projectile: FlakShell = FlakShell.new()
	get_tree().root.add_child(projectile)

	# Position ahead of ship
	projectile.global_position = ship.global_position + direction * 25

	# Calculate damage (with Overdrive bonus if active)
	var direct_dmg: float = damage_direct
	var aoe_dmg: float = damage_aoe
	if ship and ship.is_overdriving():
		direct_dmg *= 2.0
		aoe_dmg *= 2.0

	# Initialize projectile
	var velocity: Vector2 = direction.normalized() * projectile_speed
	projectile.initialize_flak(direct_dmg, aoe_dmg, "explosive", velocity, airburst_time, aoe_radius)
	projectile.shooter = ship

	fired.emit(projectile)


## FlakShell - Special projectile that explodes after a timer
class FlakShell extends Projectile:
	var aoe_damage: float = 50.0
	var aoe_radius: float = 100.0
	var detonation_timer: float = 0.8
	var has_detonated: bool = false

	func initialize_flak(direct_dmg: float, aoe_dmg: float, dmg_type: String, vel: Vector2, det_time: float, radius: float) -> void:
		"""Initialize flak shell with airburst parameters"""
		damage = direct_dmg
		aoe_damage = aoe_dmg
		damage_type = dmg_type
		velocity = vel
		detonation_timer = det_time
		aoe_radius = radius
		lifetime = det_time + 0.5  # Extra lifetime buffer

		# Visual: Orange explosive shell
		modulate = Color(1.0, 0.6, 0.0)  # Orange

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)

		# Count down to detonation
		if not has_detonated:
			detonation_timer -= delta
			if detonation_timer <= 0:
				_detonate()

	func _detonate() -> void:
		"""Airburst explosion"""
		if has_detonated:
			return

		has_detonated = true

		# Create explosion area
		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query: = PhysicsShapeQueryParameters2D.new()
		var circle: = CircleShape2D.new()
		circle.radius = aoe_radius
		query.shape = circle
		query.transform = Transform2D(0, global_position)
		query.collision_mask = 2 | 16  # Asteroids + enemies

		var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
		for result in results:
			var body: Node2D = result.collider
			if body and body != shooter and body.has_method("take_damage"):
				body.take_damage(aoe_damage, damage_type)

		# Visual: Explosion effect
		_create_explosion_vfx()

		# Remove projectile
		queue_free()

	func _create_explosion_vfx() -> void:
		"""Create visual explosion effect"""
		var explosion: ColorRect = ColorRect.new()
		explosion.color = Color(1.0, 0.5, 0.0, 0.6)  # Orange
		explosion.size = Vector2(aoe_radius * 2, aoe_radius * 2)
		explosion.position = -explosion.size / 2
		get_tree().root.add_child(explosion)
		explosion.global_position = global_position

		# Fade out explosion
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(explosion, "modulate:a", 0.0, 0.3)
		tween.tween_callback(explosion.queue_free)

	# Override collision to still deal direct damage
	func _on_body_entered(body: Node2D) -> void:
		if body == shooter:
			return

		if body.has_method("take_damage"):
			# Deal direct hit damage
			body.take_damage(damage, damage_type)
			hit_target.emit(body, damage)

		# Still detonate on impact
		if not has_detonated:
			_detonate()
