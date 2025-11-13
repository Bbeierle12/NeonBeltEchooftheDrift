extends Node2D
## Main Game Scene - Arcade Mode
##
## Handles:
## - Ship spawning
## - Wave-based progression
## - Arcade mode game loop
## - Game over / restart

var ship_scene: PackedScene = preload("res://src/entities/ship.tscn")
var wave_generator_script: Script = preload("res://src/systems/wave_generator.gd")

var player_ship: Ship = null
var wave_generator: WaveGenerator = null

# Game state
enum GameState { STARTING, PLAYING, BETWEEN_WAVES, GAME_OVER }
var current_state: GameState = GameState.STARTING

var current_wave_number: int = 0
var max_waves: int = 10
var between_wave_timer: float = 0.0
var between_wave_delay: float = 3.0


func _ready() -> void:
	# Wait for data to load
	if not DataLoader.is_loaded:
		await DataLoader.data_loaded

	# Initialize game
	_initialize_game()

	print("[Main] Arcade mode loaded - Press SPACE to start!")


func _initialize_game() -> void:
	"""Initialize all game systems"""
	# Spawn player ship
	_spawn_player_ship()

	# Create wave generator
	wave_generator = wave_generator_script.new()
	add_child(wave_generator)
	wave_generator.initialize(randi())  # Random seed for now

	# Connect wave signals
	wave_generator.wave_completed.connect(_on_wave_completed)
	wave_generator.all_waves_completed.connect(_on_all_waves_completed)

	# Start game when ready
	current_state = GameState.STARTING


func _process(delta: float) -> void:
	match current_state:
		GameState.STARTING:
			# Wait for player input to start
			if Input.is_action_just_pressed("fire"):
				_start_game()

		GameState.BETWEEN_WAVES:
			between_wave_timer -= delta
			if between_wave_timer <= 0:
				_start_next_wave()


func _start_game() -> void:
	"""Start the game"""
	print("[Main] Game started!")

	# Start run in GameManager
	GameManager.start_new_run("interceptor", "normal")

	# Start first wave
	current_wave_number = 0
	_start_next_wave()

	current_state = GameState.PLAYING


func _start_next_wave() -> void:
	"""Start the next wave"""
	current_wave_number += 1

	if current_wave_number > max_waves:
		_game_victory()
		return

	print("[Main] Starting wave ", current_wave_number, "/", max_waves)

	GameManager.start_wave(current_wave_number)
	wave_generator.start_wave(current_wave_number)

	current_state = GameState.PLAYING


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

	print("[Main] Player ship spawned")


func _on_wave_completed(wave_number: int) -> void:
	"""Handle wave completion"""
	print("[Main] Wave ", wave_number, " completed!")

	GameManager.complete_wave(wave_number)

	# Add wave clear bonus
	GameManager.add_score(500 * wave_number, "Wave " + str(wave_number) + " clear bonus")

	# Start between-wave period
	current_state = GameState.BETWEEN_WAVES
	between_wave_timer = between_wave_delay

	print("[Main] Next wave in ", between_wave_delay, " seconds...")


func _on_all_waves_completed() -> void:
	"""Handle all waves completed"""
	_game_victory()


func _game_victory() -> void:
	"""Handle game victory"""
	print("[Main] === VICTORY! ===")
	print("[Main] Final Score: ", GameManager.current_run.score)

	GameManager.end_run("victory")

	current_state = GameState.GAME_OVER

	# Restart after delay
	await get_tree().create_timer(5.0).timeout
	get_tree().reload_current_scene()


func _on_player_died(death_cause: String) -> void:
	"""Handle player death"""
	print("[Main] Player died: ", death_cause)
	print("[Main] Final Score: ", GameManager.current_run.score)

	GameManager.end_run(death_cause)

	current_state = GameState.GAME_OVER

	# Restart after delay
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
