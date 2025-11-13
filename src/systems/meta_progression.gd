extends Node
class_name MetaProgression
## MetaProgression - Persistent progression between runs
##
## Features:
## - Research Data collection (meta currency)
## - Unlock tree with permanent upgrades
## - Row bonuses for unlock milestones
## - Save/load progression data

signal research_earned(amount: int)
signal unlock_purchased(unlock_id: String)
signal row_completed(row: int)

# Meta currency
var total_research_data: int = 0
var research_data_lifetime: int = 0

# Unlocks (unlock_id -> unlocked)
var unlocked_items: Dictionary = {}

# Unlock tree structure
var unlock_tree: Dictionary = {
	# Row 1: Starting unlocks (cheap, always available)
	"row_1": {
		"unlocks": {
			"extra_starting_scrap": {
				"name": "Starting Capital",
				"description": "Start runs with +50 scrap",
				"cost": 20,
				"effect": {"starting_scrap": 50}
			},
			"unlock_railgun": {
				"name": "Railgun Schematic",
				"description": "Unlock Railgun weapon for all runs",
				"cost": 30,
				"effect": {"weapon_unlock": "railgun"}
			},
			"unlock_flak": {
				"name": "Flak Cannon Schematic",
				"description": "Unlock Flak weapon for all runs",
				"cost": 30,
				"effect": {"weapon_unlock": "flak"}
			}
		},
		"row_bonus": {
			"name": "Salvage Expert",
			"description": "+10% scrap from all sources",
			"effect": {"scrap_multiplier": 1.1}
		},
		"required_unlocks": 2
	},

	# Row 2: Mid-tier unlocks
	"row_2": {
		"unlocks": {
			"starting_hull_boost": {
				"name": "Reinforced Frame",
				"description": "Start with +20 max hull",
				"cost": 50,
				"effect": {"starting_hull": 20}
			},
			"starting_shield_boost": {
				"name": "Shield Generator",
				"description": "Start with +15 max shields",
				"cost": 50,
				"effect": {"starting_shields": 15}
			},
			"unlock_miner_ship": {
				"name": "Prospect S Blueprint",
				"description": "Unlock Miner ship",
				"cost": 60,
				"effect": {"ship_unlock": "miner"}
			},
			"discount_shop": {
				"name": "Trade Network",
				"description": "10% discount on all shop purchases",
				"cost": 45,
				"effect": {"shop_discount": 0.1}
			}
		},
		"row_bonus": {
			"name": "Efficient Salvager",
			"description": "+1 maximum weapon slot",
			"effect": {"weapon_slots": 1}
		},
		"required_unlocks": 3,
		"prerequisites": ["row_1"]
	},

	# Row 3: Advanced unlocks
	"row_3": {
		"unlocks": {
			"permanent_pierce": {
				"name": "Ballistic Penetrator",
				"description": "Start all runs with Pierce I",
				"cost": 80,
				"effect": {"starting_upgrade": "pierce"}
			},
			"permanent_magnet": {
				"name": "Salvage Magnet",
				"description": "Start all runs with Magnet I",
				"cost": 70,
				"effect": {"starting_upgrade": "magnet"}
			},
			"reroll_discount": {
				"name": "Market Analyst",
				"description": "Shop rerolls cost 50% less",
				"cost": 75,
				"effect": {"reroll_discount": 0.5}
			},
			"unlock_gunship": {
				"name": "Anvil-4 Blueprint",
				"description": "Unlock Gunship ship",
				"cost": 90,
				"effect": {"ship_unlock": "gunship"}
			}
		},
		"row_bonus": {
			"name": "Master Salvager",
			"description": "Start runs with 2 random upgrades",
			"effect": {"starting_upgrades": 2}
		},
		"required_unlocks": 3,
		"prerequisites": ["row_2"]
	}
}

# Row completion tracking
var completed_rows: Array[String] = []

# Save file path
var save_path: String = "user://meta_progression.save"


func _ready() -> void:
	load_progression()

	# Connect to game events
	GameManager.game_over.connect(_on_run_ended)


func _on_run_ended(reason: String) -> void:
	"""Award research data at end of run"""
	var run_data: Dictionary = GameManager.current_run

	# Calculate research data earned
	var research_earned: int = _calculate_research_earned(run_data)

	if research_earned > 0:
		earn_research_data(research_earned)
		print("[Meta] Earned ", research_earned, " Research Data")

	# Auto-save progression
	save_progression()


func _calculate_research_earned(run_data: Dictionary) -> int:
	"""Calculate research data from run performance"""
	var base_amount: int = 0

	# Base amount from waves completed
	var waves: int = run_data.get("waves_completed", 0)
	base_amount += waves * 5

	# Bonus for sectors completed
	var sectors: int = run_data.get("sectors_completed", 0)
	base_amount += sectors * 20

	# Bonus for boss kills
	var bosses: int = run_data.get("bosses_killed", 0)
	base_amount += bosses * 50

	# Score-based bonus (1 research per 1000 score)
	var score: int = run_data.get("score", 0)
	base_amount += int(score / 1000.0)

	return base_amount


func earn_research_data(amount: int) -> void:
	"""Earn research data"""
	total_research_data += amount
	research_data_lifetime += amount
	research_earned.emit(amount)


func purchase_unlock(unlock_id: String) -> bool:
	"""Purchase an unlock from the tree"""
	# Find unlock in tree
	var unlock_data: Dictionary = _find_unlock(unlock_id)

	if unlock_data.is_empty():
		push_error("[Meta] Unknown unlock: ", unlock_id)
		return false

	# Check if already unlocked
	if unlocked_items.has(unlock_id):
		print("[Meta] Already unlocked: ", unlock_id)
		return false

	# Check prerequisites
	if not _check_prerequisites(unlock_id):
		print("[Meta] Prerequisites not met for: ", unlock_id)
		return false

	# Check cost
	var cost: int = unlock_data.get("cost", 0)
	if total_research_data < cost:
		print("[Meta] Not enough Research Data. Need ", cost, ", have ", total_research_data)
		return false

	# Purchase unlock
	total_research_data -= cost
	unlocked_items[unlock_id] = true

	print("[Meta] Unlocked: ", unlock_data.get("name", unlock_id))
	unlock_purchased.emit(unlock_id)

	# Check row completion
	_check_row_completion()

	# Save progression
	save_progression()

	return true


func _find_unlock(unlock_id: String) -> Dictionary:
	"""Find unlock data in tree"""
	for row_id in unlock_tree.keys():
		var row: Dictionary = unlock_tree[row_id]
		var unlocks: Dictionary = row.get("unlocks", {})
		if unlocks.has(unlock_id):
			return unlocks[unlock_id]
	return {}


func _check_prerequisites(unlock_id: String) -> bool:
	"""Check if unlock prerequisites are met"""
	# Find which row the unlock is in
	for row_id in unlock_tree.keys():
		var row: Dictionary = unlock_tree[row_id]
		var unlocks: Dictionary = row.get("unlocks", {})

		if unlocks.has(unlock_id):
			# Check row prerequisites
			var prerequisites: Array = row.get("prerequisites", [])
			for prereq_row in prerequisites:
				if not completed_rows.has(prereq_row):
					return false
			return true

	return false


func _check_row_completion() -> void:
	"""Check if any rows have been completed"""
	for row_id in unlock_tree.keys():
		if completed_rows.has(row_id):
			continue

		var row: Dictionary = unlock_tree[row_id]
		var unlocks: Dictionary = row.get("unlocks", {})
		var required_unlocks: int = row.get("required_unlocks", unlocks.size())

		# Count unlocked items in this row
		var unlocked_count: int = 0
		for unlock_id in unlocks.keys():
			if unlocked_items.has(unlock_id):
				unlocked_count += 1

		# Check if row completed
		if unlocked_count >= required_unlocks:
			completed_rows.append(row_id)
			print("[Meta] Completed ", row_id, "! Row bonus unlocked.")
			row_completed.emit(int(row_id.substr(4)))


func is_unlocked(unlock_id: String) -> bool:
	"""Check if item is unlocked"""
	return unlocked_items.has(unlock_id)


func get_row_bonus(row_id: String) -> Dictionary:
	"""Get row bonus if row is completed"""
	if not completed_rows.has(row_id):
		return {}

	var row: Dictionary = unlock_tree.get(row_id, {})
	return row.get("row_bonus", {})


func apply_meta_bonuses_to_run() -> void:
	"""Apply all meta unlocks to current run"""
	# Apply starting bonuses
	for unlock_id in unlocked_items.keys():
		var unlock_data: Dictionary = _find_unlock(unlock_id)
		var effect: Dictionary = unlock_data.get("effect", {})

		if effect.has("starting_scrap"):
			GameManager.add_scrap(effect.starting_scrap)

		if effect.has("starting_hull"):
			# TODO: Apply to ship
			pass

		if effect.has("starting_shields"):
			# TODO: Apply to ship
			pass

		if effect.has("starting_upgrade"):
			# TODO: Apply upgrade
			pass

	# Apply row bonuses
	for row_id in completed_rows:
		var bonus: Dictionary = get_row_bonus(row_id)
		# TODO: Apply row bonus effects


func save_progression() -> void:
	"""Save meta progression to disk"""
	var save_data: Dictionary = {
		"total_research_data": total_research_data,
		"research_data_lifetime": research_data_lifetime,
		"unlocked_items": unlocked_items,
		"completed_rows": completed_rows,
		"version": 1
	}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("[Meta] Progression saved")
	else:
		push_error("[Meta] Failed to save progression")


func load_progression() -> void:
	"""Load meta progression from disk"""
	if not FileAccess.file_exists(save_path):
		print("[Meta] No save file found, starting fresh")
		return

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data: Dictionary = file.get_var()
		file.close()

		total_research_data = save_data.get("total_research_data", 0)
		research_data_lifetime = save_data.get("research_data_lifetime", 0)
		unlocked_items = save_data.get("unlocked_items", {})
		completed_rows = save_data.get("completed_rows", [])

		print("[Meta] Progression loaded: ", total_research_data, " Research Data, ", unlocked_items.size(), " unlocks")
	else:
		push_error("[Meta] Failed to load progression")


func get_unlock_tree() -> Dictionary:
	"""Get full unlock tree"""
	return unlock_tree


func get_research_data() -> int:
	"""Get current research data"""
	return total_research_data
