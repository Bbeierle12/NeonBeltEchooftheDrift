extends RigidBody2D
class_name Asteroid
## Asteroid - Base class for all asteroid types
##
## Handles:
## - Movement and rotation
## - Damage and destruction
## - Splitting into smaller asteroids
## - Loot drops
## - Screen wrapping

signal destroyed(asteroid_type: String, size: String)
signal damaged(remaining_hp: float)

enum AsteroidSize {
	LARGE,
	MEDIUM,
	SMALL
}

# Asteroid data
var asteroid_data: Dictionary = {}
var asteroid_type: String = ""
var size: AsteroidSize = AsteroidSize.LARGE

# Stats
var max_hp: float = 100.0
var current_hp: float = 100.0
var radius: float = 32.0
var mass_value: float = 50.0
var score_value: int = 50

# Movement
var movement_speed: float = 80.0
var rotation_speed: float = 20.0

# Screen bounds
var screen_size: Vector2
var margin: float = 100.0

# Splitting
var can_split: bool = true
var split_data: Dictionary = {}


func _ready() -> void:
	screen_size = get_viewport_rect().size
	add_to_group("asteroids")

	# Configure physics
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0
	contact_monitor = true
	max_contacts_reported = 4


func initialize(type: String, init_size: AsteroidSize, spawn_pos: Vector2, spawn_velocity: Vector2) -> void:
	"""Initialize asteroid from data"""
	asteroid_type = type
	size = init_size
	asteroid_data = DataLoader.get_asteroid(type)

	if asteroid_data.is_empty():
		push_error("[Asteroid] Failed to load asteroid data: ", type)
		return

	# Load size-specific stats
	var sizes: Dictionary = asteroid_data.get("sizes", {})
	var size_key: String = _get_size_key()
	var size_data: Dictionary = sizes.get(size_key, {})

	max_hp = size_data.get("hp", 100.0)
	current_hp = max_hp
	radius = size_data.get("radius", 32.0)
	mass_value = size_data.get("mass", 50.0)
	score_value = size_data.get("scoreValue", 50)

	# Check if this size can split
	split_data = size_data.get("splitInto", {})
	can_split = not split_data.is_empty()

	# Set random speed and rotation
	var speed_range: Dictionary = asteroid_data.get("speedRange", {"min": 50, "max": 120})
	movement_speed = randf_range(speed_range.min, speed_range.max)

	var rotation_range: Dictionary = asteroid_data.get("rotationSpeedRange", {"min": 10, "max": 45})
	rotation_speed = randf_range(rotation_range.min, rotation_range.max)

	# Apply physics
	global_position = spawn_pos
	linear_velocity = spawn_velocity.normalized() * movement_speed
	angular_velocity = deg_to_rad(rotation_speed) * (1 if randf() > 0.5 else -1)
	mass = mass_value

	# Set up collision shape
	_setup_collision()

	print("[Asteroid] Spawned ", asteroid_type, " (", size_key, ") at ", spawn_pos)


func _setup_collision() -> void:
	"""Set up collision shape based on size"""
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	collision_shape.shape = circle
	add_child(collision_shape)

	# Set collision layers
	collision_layer = 2  # asteroids layer
	collision_mask = 1 | 4  # player + projectiles_player


func _physics_process(_delta: float) -> void:
	_process_screen_wrap()


func _process_screen_wrap() -> void:
	"""Wrap asteroid position at screen edges"""
	if global_position.x < -margin:
		global_position.x = screen_size.x + margin
	elif global_position.x > screen_size.x + margin:
		global_position.x = -margin

	if global_position.y < -margin:
		global_position.y = screen_size.y + margin
	elif global_position.y > screen_size.y + margin:
		global_position.y = -margin


func take_damage(amount: float, damage_type: String = "kinetic") -> void:
	"""Take damage with type modifiers"""
	# Apply damage modifiers
	var modifiers: Dictionary = asteroid_data.get("damageModifiers", {})
	var modifier: float = modifiers.get(damage_type, 1.0)
	var final_damage: float = amount * modifier

	current_hp -= final_damage
	damaged.emit(current_hp)

	if current_hp <= 0:
		_destroy()
	else:
		# Flash or play hit effect
		_play_hit_effect()


func _destroy() -> void:
	"""Destroy asteroid and handle splitting/loot"""
	print("[Asteroid] Destroyed ", asteroid_type, " (", _get_size_key(), ")")

	# Award score
	GameManager.add_score(score_value, asteroid_type + " destroyed")
	GameManager.add_kill(asteroid_type)

	# Spawn fragments if applicable
	if can_split:
		_spawn_fragments()

	# Drop loot
	_drop_loot()

	# Play destruction effect
	_play_destruction_effect()

	destroyed.emit(asteroid_type, _get_size_key())

	# Remove from scene
	queue_free()


func _spawn_fragments() -> void:
	"""Spawn smaller asteroids when destroyed"""
	if split_data.is_empty():
		return

	for fragment_size_key in split_data.keys():
		var fragment_count_range: Dictionary = split_data[fragment_size_key]
		var count: int = randi_range(fragment_count_range.get("min", 2), fragment_count_range.get("max", 3))

		var fragment_size: AsteroidSize = _parse_size_key(fragment_size_key)

		for i in range(count):
			# Spawn at slightly offset positions
			var offset: Vector2 = Vector2(randf_range(-20, 20), randf_range(-20, 20))
			var spawn_pos: Vector2 = global_position + offset

			# Random velocity outward
			var angle: float = randf() * TAU
			var speed: float = movement_speed * randf_range(0.8, 1.5)
			var spawn_velocity: Vector2 = Vector2.from_angle(angle) * speed

			# Create fragment
			var fragment: Asteroid = preload("res://src/entities/asteroid.tscn").instantiate()
			get_parent().add_child(fragment)
			fragment.initialize(asteroid_type, fragment_size, spawn_pos, spawn_velocity)


func _drop_loot() -> void:
	"""Drop loot based on drop table"""
	var drop_table: Dictionary = asteroid_data.get("dropTable", {})

	for loot_type in drop_table.keys():
		var drop_info: Dictionary = drop_table[loot_type]
		var chance: float = drop_info.get("chance", 0.0)

		if randf() <= chance:
			var amount: int = randi_range(drop_info.get("min", 1), drop_info.get("max", 1))
			if amount > 0:
				_spawn_loot(loot_type, amount)


func _spawn_loot(loot_type: String, amount: int) -> void:
	"""Spawn loot pickup"""
	# TODO: Implement loot pickup spawning
	print("[Asteroid] Would drop ", amount, "x ", loot_type)


func _play_hit_effect() -> void:
	"""Play hit visual/audio effect"""
	# TODO: Implement hit VFX/SFX
	pass


func _play_destruction_effect() -> void:
	"""Play destruction visual/audio effect"""
	# TODO: Implement destruction VFX/SFX
	pass


func _get_size_key() -> String:
	"""Convert size enum to string key"""
	match size:
		AsteroidSize.LARGE:
			return "large"
		AsteroidSize.MEDIUM:
			return "medium"
		AsteroidSize.SMALL:
			return "small"
	return "large"


func _parse_size_key(size_key: String) -> AsteroidSize:
	"""Convert string key to size enum"""
	match size_key:
		"large":
			return AsteroidSize.LARGE
		"medium":
			return AsteroidSize.MEDIUM
		"small":
			return AsteroidSize.SMALL
	return AsteroidSize.LARGE


func get_hp_percentage() -> float:
	"""Get HP as percentage (0-1)"""
	return current_hp / max_hp
