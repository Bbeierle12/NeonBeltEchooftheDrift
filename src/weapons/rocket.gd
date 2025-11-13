extends Weapon
class_name Rocket
## Rocket - High-damage explosive weapon with area-of-effect
##
## Limited ammo, high impact. Leaves fire trails and creates explosions.

# Explosion settings
var aoe_damage: float = 40.0
var aoe_radius: float = 80.0


func initialize(weapon_type: String = "rocket") -> void:
	super.initialize(weapon_type)

	# Load explosion stats
	var stats: Dictionary = weapon_data.get("stats", {})
	aoe_damage = stats.get("aoeDamage", 40.0)
	aoe_radius = stats.get("aoeRadius", 80.0)


func _spawn_projectile(direction: Vector2) -> void:
	"""Spawn rocket with explosion capabilities"""
	var projectile: Projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)

	# Position at ship
	projectile.global_position = ship.global_position + direction * 30

	# Calculate damage
	var damage: float = base_damage
	if ship and ship.is_overdriving():
		damage *= 2.0

	# Initialize as explosive projectile
	var velocity: Vector2 = direction.normalized() * projectile_speed
	projectile.initialize(damage, "explosive", velocity, max_range / projectile_speed)
	projectile.shooter = ship

	# Connect hit signal for AoE
	projectile.hit_target.connect(_on_rocket_hit.bind(projectile))

	# Visual: Make rocket red
	var sprite: Polygon2D = projectile.get_node("Sprite2D")
	if sprite:
		sprite.color = Color(1.0, 0.3, 0.2, 1.0)
		# Make it bigger
		sprite.scale = Vector2(1.5, 1.5)

	fired.emit(projectile)


func _on_rocket_hit(target: Node2D, _damage: float, projectile: Projectile) -> void:
	"""Handle rocket explosion"""
	if not is_instance_valid(projectile):
		return

	# Create AoE explosion
	_create_explosion(projectile.global_position)


func _create_explosion(position: Vector2) -> void:
	"""Create area-of-effect explosion damage"""
	# Find all asteroids and enemies in radius
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: = PhysicsShapeQueryParameters2D.new()

	# Create circular query shape
	var circle: = CircleShape2D.new()
	circle.radius = aoe_radius
	query.shape = circle
	query.transform = Transform2D(0, position)
	query.collision_mask = 2 | 16  # asteroids + enemies

	# Query overlapping bodies
	var results: Array[Dictionary] = space_state.intersect_shape(query, 32)

	# Apply AoE damage
	var aoe_dmg: float = aoe_damage
	if ship and ship.is_overdriving():
		aoe_dmg *= 2.0

	for result in results:
		var body: Node2D = result.collider
		if body and body.has_method("take_damage"):
			body.take_damage(aoe_dmg, "explosive")

	# Visual explosion (simple colored circle for now)
	_spawn_explosion_effect(position)

	print("[Rocket] Explosion at ", position, " hit ", results.size(), " targets")


func _spawn_explosion_effect(position: Vector2) -> void:
	"""Spawn visual explosion effect"""
	# Create temporary visual node
	var explosion: = Node2D.new()
	get_tree().root.add_child(explosion)
	explosion.global_position = position

	# Draw explosion circle
	var sprite: = Polygon2D.new()
	explosion.add_child(sprite)

	# Create circle polygon
	var points: PackedVector2Array = []
	var segments: int = 16
	for i in range(segments):
		var angle: float = (i / float(segments)) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * aoe_radius)
	sprite.polygon = points
	sprite.color = Color(1.0, 0.5, 0.0, 0.6)

	# Fade out and remove
	var tween: = explosion.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)
