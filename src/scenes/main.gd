extends Node2D
## Main Game Scene - Testing environment for Phase 1
##
## Handles:
## - Ship spawning
## - Asteroid spawning (test)
## - Basic game loop

var ship_scene: PackedScene = preload("res://src/entities/ship.tscn")
var asteroid_scene: PackedScene = preload("res://src/entities/asteroid.tscn")

var player_ship: Ship = null


func _ready() -> void:
	# Wait for data to load
	if not DataLoader.is_loaded:
		await DataLoader.data_loaded

	_spawn_player_ship()
	_spawn_test_asteroids()

	print("[Main] Game scene loaded - Press F3 for debug info")


func _spawn_player_ship() -> void:
	"""Spawn the player ship"""
	player_ship = ship_scene.instantiate()
	add_child(player_ship)

	# Position in center of screen
	var screen_size: Vector2 = get_viewport_rect().size
	player_ship.global_position = screen_size / 2.0

	# Initialize with Interceptor (default starter ship)
	player_ship.initialize("interceptor")

	# Connect signals
	player_ship.died.connect(_on_player_died)
	player_ship.hull_changed.connect(_on_player_hull_changed)
	player_ship.shields_changed.connect(_on_player_shields_changed)
	player_ship.heat_changed.connect(_on_player_heat_changed)

	print("[Main] Player ship spawned")


func _spawn_test_asteroids() -> void:
	"""Spawn some test asteroids"""
	var screen_size: Vector2 = get_viewport_rect().size

	for i in range(5):
		var asteroid: Asteroid = asteroid_scene.instantiate()
		add_child(asteroid)

		# Random position
		var spawn_pos: Vector2 = Vector2(
			randf_range(100, screen_size.x - 100),
			randf_range(100, screen_size.y - 100)
		)

		# Random velocity
		var angle: float = randf() * TAU
		var speed: float = randf_range(50, 120)
		var velocity: Vector2 = Vector2.from_angle(angle) * speed

		# Initialize as Basalt (most common)
		asteroid.initialize("basalt", Asteroid.AsteroidSize.LARGE, spawn_pos, velocity)

	print("[Main] Spawned test asteroids")


func _on_player_died(death_cause: String) -> void:
	"""Handle player death"""
	print("[Main] Player died: ", death_cause)
	GameManager.end_run(death_cause)

	# TODO: Show game over screen
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()


func _on_player_hull_changed(current: float, maximum: float) -> void:
	"""Forward hull changes to HUD"""
	# TODO: Update HUD
	pass


func _on_player_shields_changed(current: float, maximum: float) -> void:
	"""Forward shield changes to HUD"""
	# TODO: Update HUD
	pass


func _on_player_heat_changed(current: float, maximum: float) -> void:
	"""Forward heat changes to HUD"""
	# TODO: Update HUD
	pass


func _input(event: InputEvent) -> void:
	"""Handle debug input"""
	if event.is_action_pressed("toggle_debug"):
		OS.set_debug_mode(!OS.is_debug_build())
