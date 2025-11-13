extends Node
class_name WaveGenerator
## Wave Generator - Procedural asteroid wave spawning system
##
## Generates waves of asteroids based on:
## - Seed (for reproducibility)
## - Difficulty (sector/wave number)
## - Budget system (HP-based)

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()

# Wave configuration
var current_wave: int = 0
var max_waves: int = 10
var wave_seed: int = 0

# Asteroid spawning
var asteroid_scene: PackedScene = preload("res://src/entities/asteroid.tscn")
var active_asteroids: Array[Asteroid] = []

# Screen bounds for spawning
var screen_size: Vector2
var spawn_margin: float = 100.0

# RNG for deterministic generation
var rng: RandomNumberGenerator


func _ready() -> void:
	screen_size = get_viewport_rect().size
	rng = RandomNumberGenerator.new()


func initialize(seed_value: int) -> void:
	"""Initialize wave generator with seed"""
	wave_seed = seed_value
	rng.seed = seed_value
	current_wave = 0
	active_asteroids.clear()

	print("[WaveGenerator] Initialized with seed: ", wave_seed)


func start_wave(wave_number: int) -> void:
	"""Generate and start a new wave"""
	current_wave = wave_number

	# Generate wave recipe
	var recipe: Dictionary = _generate_wave_recipe(wave_number)

	# Spawn asteroids
	_spawn_wave(recipe)

	wave_started.emit(wave_number)

	print("[WaveGenerator] Wave ", wave_number, " started - ", recipe.total_asteroids, " asteroids")


func _generate_wave_recipe(wave_num: int) -> Dictionary:
	"""Generate wave recipe based on wave number"""
	# Base HP budget increases with wave
	var hp_budget: float = 500.0 + (wave_num * 150.0)

	# Difficulty modifiers
	var speed_multiplier: float = 1.0 + (wave_num * 0.05)

	# Asteroid type weights (changes with difficulty)
	var type_weights: Dictionary = {
		"basalt": 1.0,
		"crystal": 0.0,  # No Crystal in Phase 1
		"volatile": 0.0,  # No Volatile in Phase 1
		"armored": 0.0   # No Armored in Phase 1
	}

	# Build spawn list
	var spawns: Array[Dictionary] = []
	var remaining_budget: float = hp_budget

	while remaining_budget > 50:
		# Pick asteroid type
		var asteroid_type: String = _weighted_choice(type_weights)

		# Pick size (prefer large early, more mix later)
		var size_roll: float = rng.randf()
		var size: Asteroid.AsteroidSize
		var asteroid_hp: float

		if size_roll < 0.4:  # 40% large
			size = Asteroid.AsteroidSize.LARGE
			asteroid_hp = 240.0
		elif size_roll < 0.75:  # 35% medium
			size = Asteroid.AsteroidSize.MEDIUM
			asteroid_hp = 120.0
		else:  # 25% small
			size = Asteroid.AsteroidSize.SMALL
			asteroid_hp = 60.0

		# Check if fits in budget
		if asteroid_hp <= remaining_budget:
			spawns.append({
				"type": asteroid_type,
				"size": size,
				"speed_multiplier": speed_multiplier
			})
			remaining_budget -= asteroid_hp

	return {
		"wave_number": wave_num,
		"spawns": spawns,
		"total_asteroids": spawns.size(),
		"speed_multiplier": speed_multiplier
	}


func _spawn_wave(recipe: Dictionary) -> void:
	"""Spawn all asteroids for the wave"""
	var spawns: Array = recipe.spawns
	var speed_mult: float = recipe.get("speed_multiplier", 1.0)

	for spawn_data in spawns:
		_spawn_asteroid(
			spawn_data.type,
			spawn_data.size,
			speed_mult
		)


func _spawn_asteroid(asteroid_type: String, size: Asteroid.AsteroidSize, speed_multiplier: float = 1.0) -> void:
	"""Spawn a single asteroid"""
	var asteroid: Asteroid = asteroid_scene.instantiate()
	get_tree().root.add_child(asteroid)

	# Random edge spawn position
	var spawn_pos: Vector2 = _get_random_edge_position()

	# Random velocity toward screen center
	var center: Vector2 = screen_size / 2.0
	var direction: Vector2 = (center - spawn_pos).normalized()

	# Add some randomness to direction
	var angle_variance: float = rng.randf_range(-PI/4, PI/4)
	direction = direction.rotated(angle_variance)

	var base_speed: float = rng.randf_range(50, 120)
	var velocity: Vector2 = direction * base_speed * speed_multiplier

	# Initialize asteroid
	asteroid.initialize(asteroid_type, size, spawn_pos, velocity)

	# Track asteroid
	active_asteroids.append(asteroid)
	asteroid.destroyed.connect(_on_asteroid_destroyed.bind(asteroid))


func _get_random_edge_position() -> Vector2:
	"""Get random position on screen edge"""
	var edge: int = rng.randi_range(0, 3)

	match edge:
		0:  # Top
			return Vector2(rng.randf_range(0, screen_size.x), -spawn_margin)
		1:  # Right
			return Vector2(screen_size.x + spawn_margin, rng.randf_range(0, screen_size.y))
		2:  # Bottom
			return Vector2(rng.randf_range(0, screen_size.x), screen_size.y + spawn_margin)
		_:  # Left
			return Vector2(-spawn_margin, rng.randf_range(0, screen_size.y))


func _weighted_choice(weights: Dictionary) -> String:
	"""Choose random item based on weights"""
	var total_weight: float = 0.0
	for weight in weights.values():
		total_weight += weight

	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0

	for key in weights.keys():
		cumulative += weights[key]
		if roll <= cumulative:
			return key

	return weights.keys()[0]


func _on_asteroid_destroyed(asteroid_type: String, size: String, asteroid: Asteroid) -> void:
	"""Handle asteroid destruction"""
	# Remove from tracking
	active_asteroids.erase(asteroid)

	# Check if wave is complete
	if active_asteroids.is_empty() and current_wave > 0:
		_complete_wave()


func _complete_wave() -> void:
	"""Complete the current wave"""
	print("[WaveGenerator] Wave ", current_wave, " completed!")

	wave_completed.emit(current_wave)

	# Check if all waves done
	if current_wave >= max_waves:
		all_waves_completed.emit()
		print("[WaveGenerator] All waves completed!")


func is_wave_active() -> bool:
	"""Check if a wave is currently active"""
	return not active_asteroids.is_empty()


func get_remaining_asteroids() -> int:
	"""Get count of remaining asteroids in wave"""
	return active_asteroids.size()
