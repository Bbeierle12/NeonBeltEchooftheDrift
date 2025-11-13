extends Node
class_name AchievementSystem
## AchievementSystem - Track and unlock achievements
##
## Features:
## - Achievement definitions
## - Progress tracking
## - Unlock notifications
## - Save/load achievement state
## - Statistics tracking

signal achievement_unlocked(achievement_id: String)
signal achievement_progress_updated(achievement_id: String, current: int, target: int)

# Achievement data
var achievements: Dictionary = {}
var unlocked_achievements: Array[String] = []
var achievement_progress: Dictionary = {}  # achievement_id -> current_progress

# Save path
var save_path: String = "user://achievements.save"

# Achievement definitions
var achievement_definitions: Dictionary = {
	# General achievements
	"first_blood": {
		"name": "First Blood",
		"description": "Destroy your first asteroid",
		"type": "instant",
		"hidden": false
	},
	"first_victory": {
		"name": "Survivor",
		"description": "Complete your first run",
		"type": "instant",
		"hidden": false
	},
	"asteroid_hunter": {
		"name": "Asteroid Hunter",
		"description": "Destroy 1,000 asteroids",
		"type": "cumulative",
		"target": 1000,
		"hidden": false
	},
	"scrap_collector": {
		"name": "Scrap Collector",
		"description": "Collect 10,000 scrap",
		"type": "cumulative",
		"target": 10000,
		"hidden": false
	},

	# Combat achievements
	"combo_master": {
		"name": "Combo Master",
		"description": "Reach a 50x combo",
		"type": "milestone",
		"target": 50,
		"hidden": false
	},
	"perfectionist": {
		"name": "Perfectionist",
		"description": "Complete a wave without taking damage",
		"type": "instant",
		"hidden": false
	},
	"arsenal": {
		"name": "Arsenal",
		"description": "Use all 10 weapon types",
		"type": "collection",
		"target": 10,
		"hidden": false
	},

	# Boss achievements
	"quarrymind_defeated": {
		"name": "Core Breach",
		"description": "Defeat Quarrymind",
		"type": "instant",
		"hidden": false
	},
	"ion_wyrm_defeated": {
		"name": "Storm Chaser",
		"description": "Defeat Ion Wyrm",
		"type": "instant",
		"hidden": false
	},
	"archivist_defeated": {
		"name": "Archive Terminated",
		"description": "Defeat the Archivist",
		"type": "instant",
		"hidden": false
	},
	"boss_rush_complete": {
		"name": "Boss Rush Champion",
		"description": "Complete Boss Rush mode",
		"type": "instant",
		"hidden": false
	},

	# Exotic achievements
	"volatile_expert": {
		"name": "Bomb Squad",
		"description": "Defuse 100 volatile asteroids",
		"type": "cumulative",
		"target": 100,
		"hidden": false
	},
	"ricochet_artist": {
		"name": "Ricochet Artist",
		"description": "Get 50 ricochet kills",
		"type": "cumulative",
		"target": 50,
		"hidden": false
	},
	"gravity_master": {
		"name": "Gravity Master",
		"description": "Get 10 kills from Grav Sling collisions",
		"type": "cumulative",
		"target": 10,
		"hidden": false
	},

	# Challenge achievements
	"speedrunner": {
		"name": "Speedrunner",
		"description": "Complete a run in under 15 minutes",
		"type": "instant",
		"hidden": false
	},
	"minimalist": {
		"name": "Minimalist",
		"description": "Complete a run using only starting weapons",
		"type": "instant",
		"hidden": false
	},
	"pacifist": {
		"name": "Peaceful Salvager",
		"description": "Complete a wave using only Grav Sling collisions",
		"type": "instant",
		"hidden": true
	},

	# Meta achievements
	"completionist": {
		"name": "Completionist",
		"description": "Unlock all meta-progression upgrades",
		"type": "instant",
		"hidden": false
	},
	"ship_collector": {
		"name": "Fleet Commander",
		"description": "Unlock all ships",
		"type": "collection",
		"target": 4,
		"hidden": false
	}
}


func _ready() -> void:
	load_achievements()


## Achievement Tracking

func unlock_achievement(achievement_id: String) -> bool:
	"""Unlock an achievement"""
	if not achievement_definitions.has(achievement_id):
		push_error("[Achievements] Unknown achievement: ", achievement_id)
		return false

	if achievement_id in unlocked_achievements:
		return false  # Already unlocked

	unlocked_achievements.append(achievement_id)

	var achievement: Dictionary = achievement_definitions[achievement_id]
	print("[Achievement Unlocked] ", achievement.name)

	achievement_unlocked.emit(achievement_id)

	# Save progress
	save_achievements()

	return true


func add_progress(achievement_id: String, amount: int = 1) -> void:
	"""Add progress to cumulative achievement"""
	if not achievement_definitions.has(achievement_id):
		return

	var achievement: Dictionary = achievement_definitions[achievement_id]

	# Only for cumulative/collection types
	if achievement.type not in ["cumulative", "collection", "milestone"]:
		return

	# Check if already unlocked
	if achievement_id in unlocked_achievements:
		return

	# Get current progress
	var current: int = achievement_progress.get(achievement_id, 0)
	current += amount
	achievement_progress[achievement_id] = current

	var target: int = achievement.get("target", 1)

	achievement_progress_updated.emit(achievement_id, current, target)

	# Check if completed
	if current >= target:
		unlock_achievement(achievement_id)

	# Save progress
	save_achievements()


func set_progress(achievement_id: String, value: int) -> void:
	"""Set progress to specific value"""
	if not achievement_definitions.has(achievement_id):
		return

	if achievement_id in unlocked_achievements:
		return

	achievement_progress[achievement_id] = value

	var achievement: Dictionary = achievement_definitions[achievement_id]
	var target: int = achievement.get("target", 1)

	achievement_progress_updated.emit(achievement_id, value, target)

	if value >= target:
		unlock_achievement(achievement_id)

	save_achievements()


## Getters

func is_unlocked(achievement_id: String) -> bool:
	"""Check if achievement is unlocked"""
	return achievement_id in unlocked_achievements


func get_progress(achievement_id: String) -> int:
	"""Get current progress"""
	return achievement_progress.get(achievement_id, 0)


func get_achievement_info(achievement_id: String) -> Dictionary:
	"""Get achievement info"""
	return achievement_definitions.get(achievement_id, {})


func get_all_achievements() -> Dictionary:
	"""Get all achievement definitions"""
	return achievement_definitions


func get_unlocked_achievements() -> Array[String]:
	"""Get list of unlocked achievements"""
	return unlocked_achievements


func get_unlock_percentage() -> float:
	"""Get percentage of achievements unlocked"""
	if achievement_definitions.is_empty():
		return 0.0

	return float(unlocked_achievements.size()) / float(achievement_definitions.size())


## Event Handlers (to be called by game systems)

func on_asteroid_destroyed() -> void:
	"""Track asteroid kills"""
	add_progress("asteroid_hunter", 1)


func on_scrap_collected(amount: int) -> void:
	"""Track scrap collection"""
	add_progress("scrap_collector", amount)


func on_combo_reached(combo: int) -> void:
	"""Track combo milestones"""
	if combo >= 50:
		unlock_achievement("combo_master")


func on_wave_completed_no_damage() -> void:
	"""Track perfect waves"""
	unlock_achievement("perfectionist")


func on_boss_defeated(boss_id: String) -> void:
	"""Track boss defeats"""
	match boss_id:
		"quarrymind":
			unlock_achievement("quarrymind_defeated")
		"ion_wyrm":
			unlock_achievement("ion_wyrm_defeated")
		"archivist":
			unlock_achievement("archivist_defeated")


func on_weapon_used(weapon_id: String) -> void:
	"""Track weapon usage"""
	# Would track unique weapons for arsenal achievement
	pass


func on_volatile_defused() -> void:
	"""Track volatile defuses"""
	add_progress("volatile_expert", 1)


func on_ricochet_kill() -> void:
	"""Track ricochet kills"""
	add_progress("ricochet_artist", 1)


func on_grav_sling_kill() -> void:
	"""Track Grav Sling collision kills"""
	add_progress("gravity_master", 1)


func on_run_completed(time: float) -> void:
	"""Track run completion"""
	unlock_achievement("first_victory")

	# Check speedrun
	if time < 900:  # 15 minutes
		unlock_achievement("speedrunner")


## Save/Load

func save_achievements() -> void:
	"""Save achievement state"""
	var save_data: Dictionary = {
		"unlocked": unlocked_achievements,
		"progress": achievement_progress,
		"version": 1
	}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()


func load_achievements() -> void:
	"""Load achievement state"""
	if not FileAccess.file_exists(save_path):
		return

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data: Dictionary = file.get_var()
		file.close()

		unlocked_achievements = save_data.get("unlocked", [])
		achievement_progress = save_data.get("progress", {})

		print("[Achievements] Loaded: ", unlocked_achievements.size(), " unlocked")
