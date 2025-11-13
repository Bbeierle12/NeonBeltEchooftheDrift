extends Asteroid
class_name ArmoredAsteroid
## ArmoredAsteroid - Heavily armored asteroid with ricochet mechanics
##
## Features:
## - Ricochets kinetic projectiles (reflects them back)
## - Resistant to kinetic damage (20% damage taken)
## - Weak to explosive damage (150%)
## - Normal energy damage (100%)
## - Visual armor plating indicators

signal projectile_ricocheted(projectile: Node2D, new_direction: Vector2)

# Armor properties
var ricochet_chance: float = 0.8  # 80% chance to ricochet kinetic projectiles
var kinetic_damage_reduction: float = 0.2  # Take only 20% kinetic damage
var explosive_weakness: float = 1.5  # Take 150% explosive damage
var ricochet_damage_mult: float = 0.5  # Ricocheted projectiles deal 50% damage

# Visual
var armor_plates: Array[ColorRect] = []


func initialize(type: String, init_size: AsteroidSize, spawn_pos: Vector2, spawn_velocity: Vector2) -> void:
	"""Initialize armored asteroid"""
	super.initialize(type, init_size, spawn_pos, spawn_velocity)

	# Override damage modifiers
	if asteroid_data.is_empty() or not asteroid_data.has("damageModifiers"):
		asteroid_data["damageModifiers"] = {}

	asteroid_data["damageModifiers"]["kinetic"] = kinetic_damage_reduction
	asteroid_data["damageModifiers"]["explosive"] = explosive_weakness
	asteroid_data["damageModifiers"]["energy"] = 1.0

	# Create armor visual
	_setup_armor_visual()


func _setup_armor_visual() -> void:
	"""Create visual armor plating"""
	# Create 4 armor plate segments around the asteroid
	for i in range(4):
		var plate: ColorRect = ColorRect.new()
		plate.color = Color(0.6, 0.6, 0.7, 0.9)  # Gray metallic
		plate.size = Vector2(radius * 0.4, radius * 0.8)
		plate.position = Vector2(-plate.size.x / 2, -plate.size.y / 2)

		var angle: float = (TAU / 4.0) * i
		plate.rotation = angle
		plate.position += Vector2(cos(angle), sin(angle)) * radius * 0.5

		add_child(plate)
		armor_plates.append(plate)


func take_damage(amount: float, damage_type: String = "kinetic", projectile: Node2D = null) -> void:
	"""Take damage with ricochet mechanics for kinetic projectiles"""

	# Handle ricochet for kinetic projectiles
	if damage_type == "kinetic" and projectile:
		var should_ricochet: bool = randf() < ricochet_chance

		if should_ricochet:
			_ricochet_projectile(projectile)
			# Take reduced damage even on ricochet
			super.take_damage(amount * 0.1, damage_type)  # Only 10% damage on ricochet
			_play_ricochet_effect()
			return

	# Normal damage with modifiers
	super.take_damage(amount, damage_type)

	# Visual feedback for armor damage
	_update_armor_visual()


func _ricochet_projectile(projectile: Node2D) -> void:
	"""Ricochet a projectile back"""
	if not projectile or not is_instance_valid(projectile):
		return

	# Calculate ricochet direction (reflect off asteroid surface)
	var to_projectile: Vector2 = (projectile.global_position - global_position).normalized()
	var incident_direction: Vector2 = projectile.velocity.normalized() if "velocity" in projectile else to_projectile

	# Reflect direction
	var reflect_direction: Vector2 = incident_direction.bounce(to_projectile)

	# Add some randomness to ricochet angle (±15 degrees)
	var random_angle: float = randf_range(-0.26, 0.26)  # ±15 degrees in radians
	reflect_direction = reflect_direction.rotated(random_angle)

	# Update projectile velocity
	if "velocity" in projectile:
		var speed: float = projectile.velocity.length()
		projectile.velocity = reflect_direction * speed

	# Reduce projectile damage
	if "damage" in projectile:
		projectile.damage *= ricochet_damage_mult

	# Change projectile ownership to hurt enemies/player
	if "shooter" in projectile:
		projectile.shooter = self

	# Visual/audio feedback
	projectile_ricocheted.emit(projectile, reflect_direction)

	print("[Armored] Ricocheted projectile!")


func _play_ricochet_effect() -> void:
	"""Visual effect for ricochet"""
	# Flash white briefly
	modulate = Color(1.5, 1.5, 1.5)

	# Tween back to normal
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func _update_armor_visual() -> void:
	"""Update armor plates based on remaining HP"""
	var hp_percent: float = current_hp / max_hp

	# Remove armor plates as HP decreases
	var plates_to_show: int = ceili(hp_percent * armor_plates.size())

	for i in range(armor_plates.size()):
		if i < plates_to_show:
			armor_plates[i].visible = true
			# Fade damaged plates
			if hp_percent < 0.5:
				armor_plates[i].color.a = 0.5 + hp_percent
		else:
			armor_plates[i].visible = false


func _play_hit_effect() -> void:
	"""Override hit effect for armored asteroids"""
	super._play_hit_effect()

	# Spark effect on armor hit
	_create_spark_effect()


func _create_spark_effect() -> void:
	"""Create spark particles on armor impact"""
	# Simple spark visual (can be enhanced with particles later)
	for i in range(3):
		var spark: ColorRect = ColorRect.new()
		spark.color = Color(1.0, 0.8, 0.0, 1.0)  # Yellow spark
		spark.size = Vector2(4, 4)
		get_tree().root.add_child(spark)
		spark.global_position = global_position + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))

		# Animate spark
		var tween: Tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position", spark.position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), 0.3)
		tween.tween_property(spark, "modulate:a", 0.0, 0.3)
		tween.chain().tween_callback(spark.queue_free)
