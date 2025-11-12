extends Weapon
class_name Autocannon
## Autocannon - High rate of fire kinetic weapon
##
## Reliable kinetic repeater with low heat generation.
## Can be upgraded with ricochet for bank shots.


func initialize(weapon_type: String = "autocannon") -> void:
	super.initialize(weapon_type)


func _spawn_projectile(direction: Vector2) -> void:
	"""Spawn autocannon bullet"""
	var projectile: Projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)

	# Position at ship with slight forward offset
	projectile.global_position = ship.global_position + direction * 24

	# Calculate damage
	var damage: float = base_damage
	if ship and ship.is_overdriving():
		damage *= 2.0  # Overdrive doubles damage

	# Initialize with kinetic damage
	var velocity: Vector2 = direction.normalized() * projectile_speed
	projectile.initialize(damage, "kinetic", velocity, max_range / projectile_speed)
	projectile.shooter = ship

	# Visual: Make bullet orange
	var sprite: Polygon2D = projectile.get_node("Sprite2D")
	if sprite:
		sprite.color = Color(1.0, 0.6, 0.2, 1.0)

	fired.emit(projectile)

	# Play SFX
	# TODO: Add audio
