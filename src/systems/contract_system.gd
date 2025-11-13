extends Node
class_name ContractSystem
## ContractSystem - Side objectives and challenges
##
## Features:
## - Generate random contracts each wave
## - Track progress towards objectives
## - Award bonus rewards on completion
## - Optional challenges for skilled players

signal contract_offered(contract: Dictionary)
signal contract_accepted(contract_id: String)
signal contract_progress_updated(contract_id: String, current: int, target: int)
signal contract_completed(contract_id: String, reward: Dictionary)
signal contract_failed(contract_id: String)

# Active contracts
var active_contracts: Array[Dictionary] = []
var completed_contracts: Array[String] = []

# Contract types
var contract_templates: Dictionary = {
	"kill_count": {
		"name": "Extermination",
		"description": "Destroy %d asteroids this wave",
		"targets": [10, 15, 20, 25],
		"rewards": {"scrap": 100, "bonus_mult": 1.5}
	},
	"no_damage": {
		"name": "Perfect Defense",
		"description": "Complete wave without taking hull damage",
		"rewards": {"scrap": 150, "bonus_mult": 2.0}
	},
	"time_limit": {
		"name": "Speed Run",
		"description": "Clear wave in under %d seconds",
		"time_limits": [45, 40, 35, 30],
		"rewards": {"scrap": 120, "bonus_mult": 1.75}
	},
	"weapon_specific": {
		"name": "Weapon Mastery",
		"description": "Destroy %d asteroids using only %s",
		"targets": [8, 10, 12],
		"weapons": ["autocannon", "beam_lance", "rocket"],
		"rewards": {"scrap": 130, "bonus_mult": 1.6}
	},
	"defuse_volatile": {
		"name": "Bomb Squad",
		"description": "Defuse %d volatile asteroids",
		"targets": [2, 3, 4],
		"rewards": {"scrap": 140, "bonus_mult": 1.8}
	},
	"no_overdrive": {
		"name": "Self-Reliance",
		"description": "Complete wave without using Overdrive",
		"rewards": {"scrap": 110, "bonus_mult": 1.5}
	},
	"chain_kills": {
		"name": "Combo Master",
		"description": "Achieve %dx combo multiplier",
		"targets": [5, 8, 10],
		"rewards": {"scrap": 160, "bonus_mult": 2.0}
	}
}


func _ready() -> void:
	# Connect to game events
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)


func _on_wave_started(wave: int) -> void:
	"""Generate contracts for new wave"""
	generate_wave_contracts(wave)


func _on_wave_completed(wave: int) -> void:
	"""Check contract completion at wave end"""
	_check_active_contracts()


func generate_wave_contracts(wave: int) -> void:
	"""Generate 1-2 random contracts for the wave"""
	# Clear previous wave contracts
	active_contracts.clear()

	# Number of contracts increases with wave
	var contract_count: int = 1 if wave < 5 else 2

	# Get random contract types
	var available_types: Array = contract_templates.keys()
	available_types.shuffle()

	for i in range(min(contract_count, available_types.size())):
		var contract_type: String = available_types[i]
		var contract: Dictionary = _create_contract(contract_type, wave)

		if not contract.is_empty():
			active_contracts.append(contract)
			contract_offered.emit(contract)
			print("[Contract] Offered: ", contract.name)


func _create_contract(contract_type: String, wave: int) -> Dictionary:
	"""Create a contract from template"""
	if not contract_templates.has(contract_type):
		return {}

	var template: Dictionary = contract_templates[contract_type]
	var contract: Dictionary = {
		"id": _generate_contract_id(),
		"type": contract_type,
		"name": template.name,
		"wave": wave,
		"accepted": false,
		"completed": false,
		"failed": false,
		"progress": 0,
		"target": 0,
		"rewards": template.get("rewards", {}).duplicate()
	}

	# Fill in description with specific values
	match contract_type:
		"kill_count":
			var difficulty_index: int = min(wave / 3, template.targets.size() - 1)
			contract.target = template.targets[difficulty_index]
			contract.description = template.description % contract.target

		"no_damage":
			contract.description = template.description
			contract.target = 1

		"time_limit":
			var difficulty_index: int = min(wave / 3, template.time_limits.size() - 1)
			contract.target = template.time_limits[difficulty_index]
			contract.description = template.description % contract.target

		"weapon_specific":
			var difficulty_index: int = min(wave / 3, template.targets.size() - 1)
			contract.target = template.targets[difficulty_index]
			var weapon: String = template.weapons[randi() % template.weapons.size()]
			contract.weapon_required = weapon
			contract.description = template.description % [contract.target, weapon]

		"defuse_volatile":
			var difficulty_index: int = min(wave / 3, template.targets.size() - 1)
			contract.target = template.targets[difficulty_index]
			contract.description = template.description % contract.target

		"no_overdrive":
			contract.description = template.description
			contract.target = 1

		"chain_kills":
			var difficulty_index: int = min(wave / 3, template.targets.size() - 1)
			contract.target = template.targets[difficulty_index]
			contract.description = template.description % contract.target

	return contract


func accept_contract(contract_id: String) -> bool:
	"""Accept a contract"""
	for contract in active_contracts:
		if contract.id == contract_id and not contract.accepted:
			contract.accepted = true
			contract_accepted.emit(contract_id)
			print("[Contract] Accepted: ", contract.name)
			return true

	return false


func update_contract_progress(contract_type: String, amount: int = 1) -> void:
	"""Update progress on active contracts"""
	for contract in active_contracts:
		if not contract.accepted or contract.completed or contract.failed:
			continue

		if contract.type == contract_type:
			contract.progress += amount
			contract_progress_updated.emit(contract.id, contract.progress, contract.target)

			# Check completion
			if contract.progress >= contract.target:
				_complete_contract(contract)


func fail_contract(contract_type: String) -> void:
	"""Fail a contract (e.g., took damage on no_damage contract)"""
	for contract in active_contracts:
		if not contract.accepted or contract.completed or contract.failed:
			continue

		if contract.type == contract_type:
			contract.failed = true
			contract_failed.emit(contract.id)
			print("[Contract] Failed: ", contract.name)


func _complete_contract(contract: Dictionary) -> void:
	"""Complete a contract and award rewards"""
	if contract.completed:
		return

	contract.completed = true
	completed_contracts.append(contract.id)

	# Award rewards
	var rewards: Dictionary = contract.rewards
	if rewards.has("scrap"):
		GameManager.add_scrap(rewards.scrap)

	if rewards.has("bonus_mult"):
		# Apply score multiplier (TODO: implement)
		pass

	contract_completed.emit(contract.id, rewards)
	print("[Contract] Completed: ", contract.name, " | Rewards: ", rewards)


func _check_active_contracts() -> void:
	"""Check all active contracts at wave end"""
	for contract in active_contracts:
		if contract.accepted and not contract.completed and not contract.failed:
			# Auto-fail incomplete contracts
			if contract.progress < contract.target:
				fail_contract(contract.type)


func get_active_contracts() -> Array[Dictionary]:
	"""Get all active contracts"""
	return active_contracts


func get_contract(contract_id: String) -> Dictionary:
	"""Get specific contract by ID"""
	for contract in active_contracts:
		if contract.id == contract_id:
			return contract
	return {}


func _generate_contract_id() -> String:
	"""Generate unique contract ID"""
	return "contract_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 10000)


# Contract event hooks (called by game systems)
func on_asteroid_destroyed(asteroid_type: String, weapon_used: String = "") -> void:
	"""Track asteroid kills for contracts"""
	# Kill count
	update_contract_progress("kill_count", 1)

	# Weapon-specific kills
	for contract in active_contracts:
		if contract.type == "weapon_specific" and contract.has("weapon_required"):
			if weapon_used == contract.weapon_required:
				update_contract_progress("weapon_specific", 1)


func on_hull_damage_taken() -> void:
	"""Track hull damage for no-damage contracts"""
	fail_contract("no_damage")


func on_overdrive_used() -> void:
	"""Track Overdrive use"""
	fail_contract("no_overdrive")


func on_volatile_defused() -> void:
	"""Track volatile defuses"""
	update_contract_progress("defuse_volatile", 1)


func on_combo_achieved(combo_level: int) -> void:
	"""Track combo achievements"""
	for contract in active_contracts:
		if contract.type == "chain_kills":
			if combo_level >= contract.target:
				contract.progress = contract.target
				_complete_contract(contract)
