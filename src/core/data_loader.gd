extends Node
## Data Loader - Loads and manages JSON game data
##
## Autoloaded singleton that loads all game content from JSON files:
## - Weapons
## - Asteroids
## - Ships
## - Upgrades
## - Sectors
## - Enemies
## - Contracts

signal data_loaded
signal data_load_failed(error: String)

var weapons: Dictionary = {}
var asteroids: Dictionary = {}
var ships: Dictionary = {}
var upgrades: Dictionary = {}
var sectors: Dictionary = {}
var enemies: Dictionary = {}
var contracts: Dictionary = {}

var is_loaded: bool = false


func _ready() -> void:
	print("[DataLoader] Starting data load...")
	_load_all_data()


func _load_all_data() -> void:
	"""Load all game data from JSON files"""
	var success: bool = true

	success = success and _load_category("weapons", "res://data/weapons/")
	success = success and _load_category("asteroids", "res://data/asteroids/")
	success = success and _load_category("ships", "res://data/ships/")
	success = success and _load_category("upgrades", "res://data/upgrades/")
	success = success and _load_category("sectors", "res://data/sectors/")

	# Enemies and contracts will be added in Phase 2
	# success = success and _load_category("enemies", "res://data/enemies/")
	# success = success and _load_category("contracts", "res://data/contracts/")

	if success:
		is_loaded = true
		_print_data_summary()
		data_loaded.emit()
		print("[DataLoader] ✅ All data loaded successfully")
	else:
		data_load_failed.emit("Failed to load some data files")
		push_error("[DataLoader] ❌ Failed to load some data files")


func _load_category(category: String, path: String) -> bool:
	"""Load all JSON files from a category directory"""
	var dir: = DirAccess.open(path)
	if dir == null:
		push_warning("[DataLoader] Directory not found: ", path)
		return true  # Not an error if directory doesn't exist yet

	var files: PackedStringArray = dir.get_files()
	var loaded_count: int = 0

	for file_name in files:
		if not file_name.ends_with(".json"):
			continue

		var file_path: String = path + file_name
		var data: Dictionary = _load_json_file(file_path)

		if data.is_empty():
			push_error("[DataLoader] Failed to load: ", file_path)
			return false

		var id: String = data.get("id", "")
		if id == "":
			push_error("[DataLoader] Missing 'id' field in: ", file_path)
			return false

		# Store in appropriate dictionary
		match category:
			"weapons":
				weapons[id] = data
			"asteroids":
				asteroids[id] = data
			"ships":
				ships[id] = data
			"upgrades":
				upgrades[id] = data
			"sectors":
				sectors[id] = data
			"enemies":
				enemies[id] = data
			"contracts":
				contracts[id] = data

		loaded_count += 1

	print("[DataLoader] Loaded ", loaded_count, " ", category)
	return true


func _load_json_file(path: String) -> Dictionary:
	"""Load and parse a JSON file"""
	var file: = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Cannot open file: ", path, " (Error: ", FileAccess.get_open_error(), ")")
		return {}

	var json_string: String = file.get_as_text()
	file.close()

	var json: = JSON.new()
	var parse_result: = json.parse(json_string)

	if parse_result != OK:
		push_error("[DataLoader] JSON parse error in ", path, " at line ", json.get_error_line(), ": ", json.get_error_message())
		return {}

	var data = json.get_data()
	if not data is Dictionary:
		push_error("[DataLoader] JSON root must be a dictionary in: ", path)
		return {}

	return data


func get_weapon(weapon_id: String) -> Dictionary:
	"""Get weapon data by ID"""
	if not weapons.has(weapon_id):
		push_warning("[DataLoader] Weapon not found: ", weapon_id)
		return {}
	return weapons[weapon_id]


func get_asteroid(asteroid_id: String) -> Dictionary:
	"""Get asteroid data by ID"""
	if not asteroids.has(asteroid_id):
		push_warning("[DataLoader] Asteroid not found: ", asteroid_id)
		return {}
	return asteroids[asteroid_id]


func get_ship(ship_id: String) -> Dictionary:
	"""Get ship data by ID"""
	if not ships.has(ship_id):
		push_warning("[DataLoader] Ship not found: ", ship_id)
		return {}
	return ships[ship_id]


func get_upgrade(upgrade_id: String) -> Dictionary:
	"""Get upgrade data by ID"""
	if not upgrades.has(upgrade_id):
		push_warning("[DataLoader] Upgrade not found: ", upgrade_id)
		return {}
	return upgrades[upgrade_id]


func get_sector(sector_id: String) -> Dictionary:
	"""Get sector data by ID"""
	if not sectors.has(sector_id):
		push_warning("[DataLoader] Sector not found: ", sector_id)
		return {}
	return sectors[sector_id]


func _print_data_summary() -> void:
	"""Print summary of loaded data"""
	print("[DataLoader] === Data Summary ===")
	print("  Weapons:   ", weapons.size())
	print("  Asteroids: ", asteroids.size())
	print("  Ships:     ", ships.size())
	print("  Upgrades:  ", upgrades.size())
	print("  Sectors:   ", sectors.size())
	print("  Enemies:   ", enemies.size())
	print("  Contracts: ", contracts.size())
	print("[DataLoader] ====================")
