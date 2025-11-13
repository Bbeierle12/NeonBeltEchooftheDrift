extends Node
class_name SectorSystem
## SectorSystem - Manages sector progression and biome mechanics
##
## Features:
## - Track current sector and progression
## - Apply sector-specific mechanics
## - Generate sector map with branching paths
## - Boss encounters at sector completion

signal sector_entered(sector_id: String)
signal sector_completed(sector_id: String)
signal boss_encounter_started(boss_id: String)

# Sector progression
var current_sector: String = "rustfields"
var sectors_completed: Array[String] = []
var sector_map: Array[Array] = []  # 2D map of sector nodes

# Sector definitions
var sector_data: Dictionary = {
	"rustfields": {
		"name": "The Rustfields",
		"description": "Derelict mining sector with standard asteroids",
		"waves": 10,
		"difficulty": 1.0,
		"asteroid_types": ["basalt"],
		"hazards": [],
		"boss": null,
		"theme_color": Color(0.6, 0.4, 0.2)  # Rusty brown
	},
	"prism_verge": {
		"name": "Prism Verge",
		"description": "Crystal formations refract energy weapons",
		"waves": 8,
		"difficulty": 1.3,
		"asteroid_types": ["basalt", "crystal"],
		"hazards": ["grav_lens"],
		"boss": "quarrymind",
		"theme_color": Color(0.3, 0.7, 1.0)  # Cyan
	},
	"stormtrack": {
		"name": "Stormtrack",
		"description": "Lightning storms and EMP hazards",
		"waves": 8,
		"difficulty": 1.5,
		"asteroid_types": ["basalt", "volatile"],
		"hazards": ["ion_storm"],
		"boss": "ion_wyrm",
		"theme_color": Color(0.7, 0.3, 0.9)  # Purple
	},
	"silent_archive": {
		"name": "Silent Archive",
		"description": "Mysterious alien structures",
		"waves": 10,
		"difficulty": 1.8,
		"asteroid_types": ["basalt", "armored"],
		"hazards": ["void_tear"],
		"boss": "archivist",
		"theme_color": Color(0.2, 0.9, 0.4)  # Green
	}
}


func _ready() -> void:
	# Connect to game events
	GameManager.game_started.connect(_on_run_started)


func _on_run_started() -> void:
	"""Initialize sector progression for new run"""
	current_sector = "rustfields"
	sectors_completed.clear()
	generate_sector_map()


func generate_sector_map() -> void:
	"""Generate branching sector map for run"""
	sector_map.clear()

	# Simple linear progression for now
	# TODO: Implement branching paths
	sector_map = [
		["rustfields"],
		["prism_verge", "stormtrack"],
		["silent_archive"]
	]

	print("[Sector] Generated map: ", sector_map)


func enter_sector(sector_id: String) -> bool:
	"""Enter a new sector"""
	if not sector_data.has(sector_id):
		push_error("[Sector] Unknown sector: ", sector_id)
		return false

	current_sector = sector_id
	var sector_info: Dictionary = sector_data[sector_id]

	print("[Sector] Entered: ", sector_info.name)
	sector_entered.emit(sector_id)

	# Apply sector modifiers
	_apply_sector_mechanics(sector_id)

	return true


func complete_sector(sector_id: String) -> void:
	"""Mark sector as completed"""
	if sector_id == current_sector:
		sectors_completed.append(sector_id)
		sector_completed.emit(sector_id)
		print("[Sector] Completed: ", sector_id)

		# Check for boss encounter
		var sector_info: Dictionary = sector_data[sector_id]
		if sector_info.has("boss") and sector_info.boss:
			_trigger_boss_encounter(sector_info.boss)


func _apply_sector_mechanics(sector_id: String) -> void:
	"""Apply sector-specific modifiers"""
	var sector_info: Dictionary = sector_data.get(sector_id, {})

	# Apply difficulty multiplier
	var difficulty: float = sector_info.get("difficulty", 1.0)
	GameManager.current_run["sector_difficulty"] = difficulty

	# Configure asteroid spawning
	var asteroid_types: Array = sector_info.get("asteroid_types", ["basalt"])
	if has_node("/root/WaveGenerator"):
		# TODO: Update wave generator with asteroid types
		pass

	# Activate hazards
	var hazards: Array = sector_info.get("hazards", [])
	for hazard in hazards:
		_activate_hazard(hazard)


func _activate_hazard(hazard_id: String) -> void:
	"""Activate environmental hazard"""
	print("[Sector] Activating hazard: ", hazard_id)

	match hazard_id:
		"grav_lens":
			# TODO: Spawn gravity lenses
			pass
		"ion_storm":
			# TODO: Create lightning effects
			pass
		"void_tear":
			# TODO: Spawn void tears
			pass


func _trigger_boss_encounter(boss_id: String) -> void:
	"""Start boss encounter"""
	print("[Sector] Boss encounter: ", boss_id)
	boss_encounter_started.emit(boss_id)

	# TODO: Spawn boss
	match boss_id:
		"quarrymind":
			_spawn_quarrymind()
		"ion_wyrm":
			_spawn_ion_wyrm()
		"archivist":
			_spawn_archivist()


func _spawn_quarrymind() -> void:
	"""Spawn Quarrymind boss"""
	# TODO: Implement boss spawning
	print("[Sector] Spawning Quarrymind boss")


func _spawn_ion_wyrm() -> void:
	"""Spawn Ion Wyrm boss"""
	print("[Sector] Spawning Ion Wyrm boss")


func _spawn_archivist() -> void:
	"""Spawn Archivist boss"""
	print("[Sector] Spawning Archivist boss")


func get_current_sector() -> Dictionary:
	"""Get current sector info"""
	return sector_data.get(current_sector, {})


func get_available_next_sectors() -> Array:
	"""Get available sectors to choose from"""
	# Find current depth
	var current_depth: int = -1
	for depth in range(sector_map.size()):
		if current_sector in sector_map[depth]:
			current_depth = depth
			break

	# Return next depth options
	if current_depth >= 0 and current_depth + 1 < sector_map.size():
		return sector_map[current_depth + 1]

	return []


func get_sector_info(sector_id: String) -> Dictionary:
	"""Get info for specific sector"""
	return sector_data.get(sector_id, {})
