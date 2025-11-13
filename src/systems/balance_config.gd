extends Node
class_name BalanceConfig
## BalanceConfig - Centralized balance configuration
##
## Features:
## - All game balance values in one place
## - Hot-reloadable from JSON
## - Different difficulty presets
## - Easy tuning without code changes

signal balance_reloaded()

# Balance configuration
var config: Dictionary = {}

# Config file path
var config_path: String = "res://config/balance.json"

# Default balance values
var default_config: Dictionary = {
	"player": {
		"base_speed": 220.0,
		"base_acceleration": 700.0,
		"base_turn_rate": 320.0,
		"hypershift_cooldown": 5.0,
		"hypershift_duration": 0.3,
		"overdrive_cooldown": 15.0,
		"overdrive_duration": 3.0,
		"overdrive_damage_mult": 2.0
	},
	"weapons": {
		"autocannon": {
			"fire_rate": 8.0,
			"damage": 12.0,
			"heat": 0.5,
			"ammo": 200
		},
		"beam_lance": {
			"dps_base": 40.0,
			"dps_ramp": 110.0,
			"ramp_time": 1.5,
			"heat_per_sec": 18.0
		},
		"rocket": {
			"damage_direct": 120.0,
			"damage_aoe": 40.0,
			"aoe_radius": 80.0,
			"ammo": 6,
			"fire_rate": 1.5
		},
		"railgun": {
			"damage_min": 200.0,
			"damage_max": 600.0,
			"charge_time": 1.5,
			"ammo": 40
		},
		"flak": {
			"damage_direct": 30.0,
			"damage_aoe": 50.0,
			"fire_rate": 4.0,
			"ammo": 120
		},
		"mines": {
			"damage": 180.0,
			"proximity_radius": 60.0,
			"max_mines": 12,
			"ammo": 24
		}
	},
	"asteroids": {
		"basalt": {
			"large_hp": 120.0,
			"medium_hp": 60.0,
			"small_hp": 30.0,
			"speed_mult": 1.0
		},
		"crystal": {
			"large_hp": 100.0,
			"medium_hp": 50.0,
			"kinetic_mult": 1.5,
			"energy_mult": 0.5
		},
		"volatile": {
			"large_timer": 8.0,
			"explosion_radius": 200.0,
			"explosion_damage": 150.0
		},
		"armored": {
			"large_hp": 200.0,
			"ricochet_chance": 0.8,
			"kinetic_mult": 0.2,
			"explosive_mult": 1.5
		}
	},
	"economy": {
		"scrap_drop_chance": 0.6,
		"scrap_min": 5,
		"scrap_max": 20,
		"ammo_drop_chance": 0.3,
		"ammo_amount": 10,
		"hull_drop_chance": 0.15,
		"hull_amount": 15.0
	},
	"progression": {
		"wave_hp_budget_base": 500.0,
		"wave_hp_budget_per_wave": 150.0,
		"wave_speed_mult_per_wave": 0.05,
		"shop_weapon_cost_range": [500, 800],
		"shop_upgrade_base_cost": 150,
		"shop_upgrade_cost_per_level": 100
	},
	"bosses": {
		"quarrymind": {
			"core_hp": 5000.0,
			"armor_hp": 800.0,
			"armor_count": 4,
			"summon_interval": 8.0,
			"pull_radius": 400.0
		},
		"ion_wyrm": {
			"segment_hp": 1200.0,
			"segment_count": 5,
			"lightning_damage": 80.0,
			"lightning_interval": 3.0,
			"emp_radius": 300.0
		},
		"archivist": {
			"hp": 8000.0,
			"reflection_chance": 0.7,
			"teleport_interval": 6.0,
			"duplicate_hp": 2000.0
		}
	},
	"difficulty": {
		"easy": {
			"damage_taken_mult": 0.75,
			"damage_dealt_mult": 1.25,
			"scrap_mult": 1.5
		},
		"normal": {
			"damage_taken_mult": 1.0,
			"damage_dealt_mult": 1.0,
			"scrap_mult": 1.0
		},
		"hard": {
			"damage_taken_mult": 1.5,
			"damage_dealt_mult": 0.85,
			"scrap_mult": 0.8
		}
	}
}


func _ready() -> void:
	load_config()


func load_config() -> void:
	"""Load balance config from file"""
	# Try to load from JSON file
	if FileAccess.file_exists(config_path):
		var file: FileAccess = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()

			var json: = JSON.new()
			var parse_result: = json.parse(json_string)

			if parse_result == OK:
				config = json.get_data()
				print("[Balance] Config loaded from: ", config_path)
				balance_reloaded.emit()
				return

	# Fallback to default config
	config = default_config.duplicate(true)
	print("[Balance] Using default config")


func save_config() -> void:
	"""Save current config to file"""
	var json_string: String = JSON.stringify(config, "\t")

	var file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[Balance] Config saved to: ", config_path)


func reload_config() -> void:
	"""Reload config from file"""
	load_config()
	print("[Balance] Config reloaded")


## Getters

func get_value(path: String, default_value: Variant = null) -> Variant:
	"""Get config value by path (e.g., \"player.base_speed\")"""
	var keys: PackedStringArray = path.split(".")
	var current: Variant = config

	for key in keys:
		if current is Dictionary and current.has(key):
			current = current[key]
		else:
			return default_value

	return current


func get_player_stat(stat_name: String) -> Variant:
	"""Get player stat"""
	return get_value("player." + stat_name)


func get_weapon_stat(weapon_id: String, stat_name: String) -> Variant:
	"""Get weapon stat"""
	return get_value("weapons." + weapon_id + "." + stat_name)


func get_asteroid_stat(asteroid_id: String, stat_name: String) -> Variant:
	"""Get asteroid stat"""
	return get_value("asteroids." + asteroid_id + "." + stat_name)


func get_boss_stat(boss_id: String, stat_name: String) -> Variant:
	"""Get boss stat"""
	return get_value("bosses." + boss_id + "." + stat_name)


func get_difficulty_mult(difficulty: String, mult_name: String) -> float:
	"""Get difficulty multiplier"""
	var value: Variant = get_value("difficulty." + difficulty + "." + mult_name, 1.0)
	return value if value is float else 1.0


## Setters (for runtime tuning)

func set_value(path: String, value: Variant) -> void:
	"""Set config value by path"""
	var keys: PackedStringArray = path.split(".")
	var current: Dictionary = config

	for i in range(keys.size() - 1):
		var key: String = keys[i]
		if not current.has(key):
			current[key] = {}
		current = current[key]

	current[keys[-1]] = value

	print("[Balance] Set ", path, " = ", value)


## Presets

func apply_difficulty_preset(difficulty: String) -> void:
	"""Apply difficulty preset modifiers"""
	if not config.get("difficulty", {}).has(difficulty):
		push_error("[Balance] Unknown difficulty: ", difficulty)
		return

	print("[Balance] Applied difficulty: ", difficulty)


func reset_to_defaults() -> void:
	"""Reset to default balance values"""
	config = default_config.duplicate(true)
	print("[Balance] Reset to defaults")
	balance_reloaded.emit()


## Export for tuning

func export_config_template() -> void:
	"""Export current config as JSON template"""
	save_config()
	print("[Balance] Config template exported to: ", config_path)
