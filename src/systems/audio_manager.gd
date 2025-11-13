extends Node
class_name AudioManager
## AudioManager - Centralized audio management
##
## Features:
## - Sound effect playback with pooling
## - Music management with transitions
## - Volume controls (master, sfx, music)
## - Audio ducking
## - Spatial audio support

signal music_changed(track_id: String)
signal volume_changed(bus_name: String, volume: float)

# Audio buses
const BUS_MASTER: String = "Master"
const BUS_SFX: String = "SFX"
const BUS_MUSIC: String = "Music"
const BUS_UI: String = "UI"

# Volume settings (0.0 - 1.0)
var master_volume: float = 0.8
var sfx_volume: float = 0.7
var music_volume: float = 0.6
var ui_volume: float = 0.8

# Music state
var current_music_track: String = ""
var music_player: AudioStreamPlayer = null
var music_fade_tween: Tween = null

# SFX pools
var sfx_pool: Dictionary = {}  # sound_id -> Array[AudioStreamPlayer]
var pool_size: int = 10
var max_concurrent_sounds: int = 32
var active_sounds: int = 0

# Audio settings
var audio_enabled: bool = true

# Save path
var save_path: String = "user://audio_settings.save"


func _ready() -> void:
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = BUS_MUSIC
	add_child(music_player)

	load_audio_settings()

	# Apply initial volumes
	_apply_volumes()


## SFX Playback

func play_sfx(sound_id: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	"""Play sound effect"""
	if not audio_enabled:
		return

	if active_sounds >= max_concurrent_sounds:
		return  # Too many sounds playing

	# TODO: Load actual audio file
	# For now, this is a placeholder framework

	active_sounds += 1

	print("[Audio] SFX: ", sound_id)


func play_sfx_at_position(sound_id: String, position: Vector2, volume_db: float = 0.0) -> void:
	"""Play positional sound effect"""
	if not audio_enabled:
		return

	# TODO: Create AudioStreamPlayer2D at position
	print("[Audio] SFX at position: ", sound_id, " @ ", position)


func stop_sfx(sound_id: String) -> void:
	"""Stop all instances of a sound"""
	# TODO: Stop pooled sounds
	pass


## Music Management

func play_music(track_id: String, fade_in: float = 1.0) -> void:
	"""Play music track"""
	if not audio_enabled or current_music_track == track_id:
		return

	# Stop current music
	if current_music_track != "":
		stop_music(fade_in)

	current_music_track = track_id

	# TODO: Load actual music file
	# For now, placeholder

	if music_fade_tween:
		music_fade_tween.kill()

	music_player.volume_db = -80.0  # Start silent
	music_player.play()

	# Fade in
	if fade_in > 0:
		music_fade_tween = get_tree().create_tween()
		music_fade_tween.tween_property(music_player, "volume_db", 0.0, fade_in)

	music_changed.emit(track_id)

	print("[Audio] Music: ", track_id)


func stop_music(fade_out: float = 1.0) -> void:
	"""Stop current music"""
	if current_music_track == "":
		return

	if music_fade_tween:
		music_fade_tween.kill()

	if fade_out > 0:
		music_fade_tween = get_tree().create_tween()
		music_fade_tween.tween_property(music_player, "volume_db", -80.0, fade_out)
		music_fade_tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

	current_music_track = ""


func crossfade_music(new_track: String, crossfade_time: float = 2.0) -> void:
	"""Crossfade to new music track"""
	if current_music_track == new_track:
		return

	stop_music(crossfade_time)
	play_music(new_track, crossfade_time)


## Volume Controls

func set_master_volume(volume: float) -> void:
	"""Set master volume (0-1)"""
	master_volume = clamp(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_MASTER, master_volume)
	volume_changed.emit(BUS_MASTER, master_volume)
	save_audio_settings()


func set_sfx_volume(volume: float) -> void:
	"""Set SFX volume (0-1)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_SFX, sfx_volume)
	volume_changed.emit(BUS_SFX, sfx_volume)
	save_audio_settings()


func set_music_volume(volume: float) -> void:
	"""Set music volume (0-1)"""
	music_volume = clamp(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	volume_changed.emit(BUS_MUSIC, music_volume)
	save_audio_settings()


func set_ui_volume(volume: float) -> void:
	"""Set UI volume (0-1)"""
	ui_volume = clamp(volume, 0.0, 1.0)
	_apply_bus_volume(BUS_UI, ui_volume)
	volume_changed.emit(BUS_UI, ui_volume)
	save_audio_settings()


func _apply_volumes() -> void:
	"""Apply all volume settings to buses"""
	_apply_bus_volume(BUS_MASTER, master_volume)
	_apply_bus_volume(BUS_SFX, sfx_volume)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	_apply_bus_volume(BUS_UI, ui_volume)


func _apply_bus_volume(bus_name: String, volume: float) -> void:
	"""Apply volume to audio bus"""
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return

	# Convert linear volume to dB
	var volume_db: float = linear_to_db(volume) if volume > 0 else -80.0
	AudioServer.set_bus_volume_db(bus_index, volume_db)


## Audio Ducking

func duck_music(amount_db: float = -20.0, duration: float = 0.5) -> void:
	"""Temporarily lower music volume"""
	if not music_player:
		return

	var current_db: float = music_player.volume_db
	var ducked_db: float = current_db + amount_db

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(music_player, "volume_db", ducked_db, duration)


func unduck_music(duration: float = 0.5) -> void:
	"""Restore music volume"""
	if not music_player:
		return

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(music_player, "volume_db", 0.0, duration)


## Utility

func set_audio_enabled(enabled: bool) -> void:
	"""Enable/disable all audio"""
	audio_enabled = enabled

	if not enabled:
		stop_music(0.0)
		# Stop all SFX


func get_master_volume() -> float:
	return master_volume


func get_sfx_volume() -> float:
	return sfx_volume


func get_music_volume() -> float:
	return music_volume


func get_ui_volume() -> float:
	return ui_volume


## Save/Load

func save_audio_settings() -> void:
	"""Save audio settings"""
	var save_data: Dictionary = {
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"ui_volume": ui_volume,
		"audio_enabled": audio_enabled,
		"version": 1
	}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()


func load_audio_settings() -> void:
	"""Load audio settings"""
	if not FileAccess.file_exists(save_path):
		return

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data: Dictionary = file.get_var()
		file.close()

		master_volume = save_data.get("master_volume", 0.8)
		sfx_volume = save_data.get("sfx_volume", 0.7)
		music_volume = save_data.get("music_volume", 0.6)
		ui_volume = save_data.get("ui_volume", 0.8)
		audio_enabled = save_data.get("audio_enabled", true)

		_apply_volumes()

		print("[Audio] Settings loaded")
