extends Node
## Game Manager - Central orchestrator for game state and systems
##
## Autoloaded singleton that manages:
## - Game state (menu, playing, paused, game over)
## - Current run data (score, sector, wave)
## - Global settings
## - Telemetry collection

signal game_started
signal game_paused
signal game_resumed
signal game_over(final_score: int, death_cause: String)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal sector_changed(sector_id: String)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	SHOP,
	LOADING
}

# Current state
var current_state: GameState = GameState.MENU

# Run data
var current_run: Dictionary = {}
var session_id: String = ""

# Settings
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"screen_shake_intensity": 0.7,
	"flash_intensity": 0.8,
	"game_speed": 1.0,
	"photosensitivity_mode": false,
	"show_fps": true,
	"debug_mode": true
}

# Telemetry buffer
var telemetry_buffer: Array[Dictionary] = []
const MAX_TELEMETRY_BUFFER: int = 100


func _ready() -> void:
	randomize()
	session_id = _generate_session_id()
	print("[GameManager] Initialized - Session ID: ", session_id)
	_load_settings()


func start_new_run(ship_id: String, difficulty: String = "normal", seed: int = -1) -> void:
	"""Start a new game run"""
	if seed == -1:
		seed = randi()

	current_run = {
		"session_id": session_id,
		"ship_id": ship_id,
		"difficulty": difficulty,
		"seed": seed,
		"start_time": Time.get_unix_time_from_system(),
		"current_sector": "rustfields",
		"current_wave": 1,
		"score": 0,
		"kills": {},
		"damage_dealt": 0,
		"damage_taken": 0,
		"deaths": 0,
		"credits": 0,
		"research_data": 0,
		"upgrades": [],
		"weapons": []
	}

	current_state = GameState.PLAYING
	game_started.emit()

	_send_telemetry("run_start", {
		"ship_id": ship_id,
		"difficulty": difficulty,
		"seed": seed
	})

	print("[GameManager] Run started - Ship: ", ship_id, " | Seed: ", seed)


func end_run(death_cause: String = "unknown") -> void:
	"""End the current run"""
	if current_run.is_empty():
		return

	var duration: float = Time.get_unix_time_from_system() - current_run.start_time

	_send_telemetry("run_end", {
		"duration_seconds": int(duration),
		"final_sector": current_run.current_sector,
		"final_wave": current_run.current_wave,
		"death_cause": death_cause,
		"final_score": current_run.score,
		"kills": current_run.kills,
		"damage_dealt": current_run.damage_dealt,
		"damage_taken": current_run.damage_taken,
		"deaths": current_run.deaths
	})

	current_state = GameState.GAME_OVER
	game_over.emit(current_run.score, death_cause)

	print("[GameManager] Run ended - Score: ", current_run.score, " | Cause: ", death_cause)


func pause_game() -> void:
	"""Pause the game"""
	if current_state != GameState.PLAYING:
		return

	current_state = GameState.PAUSED
	get_tree().paused = true
	game_paused.emit()


func resume_game() -> void:
	"""Resume the game"""
	if current_state != GameState.PAUSED:
		return

	current_state = GameState.PLAYING
	get_tree().paused = false
	game_resumed.emit()


func add_score(amount: int, reason: String = "") -> void:
	"""Add to the current score"""
	if current_run.is_empty():
		return

	current_run.score += amount

	if reason != "":
		print("[GameManager] +", amount, " score: ", reason)


func add_kill(entity_type: String) -> void:
	"""Track enemy/asteroid kills"""
	if current_run.is_empty():
		return

	if not current_run.kills.has(entity_type):
		current_run.kills[entity_type] = 0
	current_run.kills[entity_type] += 1


func start_wave(wave_number: int) -> void:
	"""Signal wave start"""
	if current_run.is_empty():
		return

	current_run.current_wave = wave_number
	wave_started.emit(wave_number)

	print("[GameManager] Wave ", wave_number, " started")


func complete_wave(wave_number: int) -> void:
	"""Signal wave completion"""
	wave_completed.emit(wave_number)

	print("[GameManager] Wave ", wave_number, " completed")


func change_sector(sector_id: String) -> void:
	"""Change to a new sector"""
	if current_run.is_empty():
		return

	current_run.current_sector = sector_id
	sector_changed.emit(sector_id)

	print("[GameManager] Sector changed to: ", sector_id)


func _send_telemetry(event: String, data: Dictionary) -> void:
	"""Queue telemetry event for sending"""
	if not settings.get("telemetry_enabled", true):
		return

	var telemetry_event: Dictionary = {
		"event": event,
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": session_id,
		"game_version": ProjectSettings.get_setting("application/config/version")
	}
	telemetry_event.merge(data)

	telemetry_buffer.append(telemetry_event)

	if telemetry_buffer.size() >= MAX_TELEMETRY_BUFFER:
		_flush_telemetry()


func _flush_telemetry() -> void:
	"""Send buffered telemetry to server (placeholder)"""
	if telemetry_buffer.is_empty():
		return

	# TODO: Implement actual HTTP request to telemetry server
	if settings.debug_mode:
		print("[GameManager] Would send ", telemetry_buffer.size(), " telemetry events")

	telemetry_buffer.clear()


func _generate_session_id() -> String:
	"""Generate unique session ID"""
	var time: float = Time.get_unix_time_from_system()
	var random: int = randi()
	return "%d-%d" % [int(time), random]


func _load_settings() -> void:
	"""Load settings from file"""
	var config_path: String = "user://settings.cfg"
	var config: = ConfigFile.new()

	if config.load(config_path) == OK:
		for key in settings.keys():
			if config.has_section_key("settings", key):
				settings[key] = config.get_value("settings", key)
		print("[GameManager] Settings loaded from ", config_path)
	else:
		print("[GameManager] No settings file found, using defaults")


func save_settings() -> void:
	"""Save settings to file"""
	var config_path: String = "user://settings.cfg"
	var config: = ConfigFile.new()

	for key in settings.keys():
		config.set_value("settings", key, settings[key])

	var err: = config.save(config_path)
	if err == OK:
		print("[GameManager] Settings saved to ", config_path)
	else:
		push_error("[GameManager] Failed to save settings: ", err)


func _notification(what: int) -> void:
	"""Handle application quit"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_flush_telemetry()
		save_settings()
		get_tree().quit()
