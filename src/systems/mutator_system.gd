extends Node
class_name MutatorSystem
## MutatorSystem - Gameplay modifiers for variety and challenge
##
## Features:
## - Enable/disable mutators
## - Stack multiple mutators
## - Score multipliers for challenge mutators
## - Unlock requirements
## - Save active mutator configuration

signal mutator_enabled(mutator_id: String)
signal mutator_disabled(mutator_id: String)

# Active mutators
var active_mutators: Array[String] = []

# Mutator definitions
var mutators: Dictionary = {
	# Fun mutators
	"low_friction": {
		"name": "Low Friction",
		"description": "Drifting intensifies. Maximum slide.",
		"type": "fun",
		"score_mult": 1.2,
		"effects": {
			"friction_mult": 0.5,
			"acceleration_mult": 1.3
		},
		"unlocked": true
	},
	"bullet_time": {
		"name": "Bullet Time",
		"description": "Everything runs at 75% speed. Matrix mode.",
		"type": "fun",
		"score_mult": 0.8,  # Easier, so reduced score
		"effects": {
			"time_scale": 0.75
		},
		"unlocked": true
	},
	"big_head_mode": {
		"name": "Big Asteroids",
		"description": "Asteroids are 50% larger. Easier to hit, but harder to dodge.",
		"type": "fun",
		"score_mult": 1.0,
		"effects": {
			"asteroid_size_mult": 1.5
		},
		"unlocked": true
	},

	# Challenge mutators
	"emp_drizzle": {
		"name": "EMP Drizzle",
		"description": "Random weapon malfunctions. Weapons disabled for 1s every 10s.",
		"type": "challenge",
		"score_mult": 1.5,
		"effects": {
			"emp_enabled": true,
			"emp_interval": 10.0,
			"emp_duration": 1.0
		},
		"unlocked": true
	},
	"glass_cannon": {
		"name": "Glass Cannon",
		"description": "3x damage dealt, but hull reduced to 1.",
		"type": "challenge",
		"score_mult": 2.0,
		"effects": {
			"damage_mult": 3.0,
			"hull_mult": 0.01,
			"shield_mult": 0.0
		},
		"unlocked": false
	},
	"ammo_famine": {
		"name": "Ammo Famine",
		"description": "No ammo pickups. Start with 50% ammo.",
		"type": "challenge",
		"score_mult": 1.8,
		"effects": {
			"ammo_drops_disabled": true,
			"starting_ammo_mult": 0.5
		},
		"unlocked": false
	},
	"volatile_overload": {
		"name": "Volatile Overload",
		"description": "50% of asteroids are volatile. Boom.",
		"type": "challenge",
		"score_mult": 1.6,
		"effects": {
			"volatile_chance": 0.5
		},
		"unlocked": false
	},
	"no_shields": {
		"name": "No Shields",
		"description": "Shields disabled. Hull only. Don't get hit.",
		"type": "challenge",
		"score_mult": 1.7,
		"effects": {
			"shield_mult": 0.0
		},
		"unlocked": false
	},

	# Chaos mutators
	"random_weapons": {
		"name": "Random Weapons",
		"description": "Weapons swap every 30 seconds.",
		"type": "chaos",
		"score_mult": 1.3,
		"effects": {
			"weapon_swap_enabled": true,
			"swap_interval": 30.0
		},
		"unlocked": false
	},
	"gravity_chaos": {
		"name": "Gravity Chaos",
		"description": "Random gravity pulses every 15s.",
		"type": "chaos",
		"score_mult": 1.4,
		"effects": {
			"gravity_pulses": true,
			"pulse_interval": 15.0
		},
		"unlocked": false
	},
	"mirror_mode": {
		"name": "Mirror Mode",
		"description": "Asteroids reflect projectiles.",
		"type": "chaos",
		"score_mult": 1.5,
		"effects": {
			"asteroid_reflection": true,
			"reflection_chance": 0.3
		},
		"unlocked": false
	},

	# Assist mutators (for accessibility)
	"extra_hp": {
		"name": "Extra HP",
		"description": "2x hull and shields. For learning.",
		"type": "assist",
		"score_mult": 0.5,  # Reduced score for assist
		"effects": {
			"hull_mult": 2.0,
			"shield_mult": 2.0
		},
		"unlocked": true
	},
	"infinite_ammo": {
		"name": "Infinite Ammo",
		"description": "Unlimited ammo for all weapons.",
		"type": "assist",
		"score_mult": 0.6,
		"effects": {
			"infinite_ammo": true
		},
		"unlocked": true
	},
	"auto_aim": {
		"name": "Auto-Aim Assist",
		"description": "Projectiles home towards enemies.",
		"type": "assist",
		"score_mult": 0.4,
		"effects": {
			"auto_aim": true,
			"homing_strength": 0.3
		},
		"unlocked": true
	}
}

# Save path
var save_path: String = "user://mutators.save"


func _ready() -> void:
	load_mutator_state()


func enable_mutator(mutator_id: String) -> bool:
	"""Enable a mutator"""
	if not mutators.has(mutator_id):
		push_error("[Mutators] Unknown mutator: ", mutator_id)
		return false

	if mutator_id in active_mutators:
		return false  # Already active

	var mutator: Dictionary = mutators[mutator_id]

	if not mutator.get("unlocked", false):
		print("[Mutators] Mutator locked: ", mutator_id)
		return false

	active_mutators.append(mutator_id)

	_apply_mutator_effects(mutator_id, true)

	mutator_enabled.emit(mutator_id)

	print("[Mutators] Enabled: ", mutator.name)

	save_mutator_state()

	return true


func disable_mutator(mutator_id: String) -> bool:
	"""Disable a mutator"""
	if mutator_id not in active_mutators:
		return false

	active_mutators.erase(mutator_id)

	_apply_mutator_effects(mutator_id, false)

	mutator_disabled.emit(mutator_id)

	print("[Mutators] Disabled: ", mutator_id)

	save_mutator_state()

	return true


func toggle_mutator(mutator_id: String) -> void:
	"""Toggle mutator on/off"""
	if is_active(mutator_id):
		disable_mutator(mutator_id)
	else:
		enable_mutator(mutator_id)


func _apply_mutator_effects(mutator_id: String, enable: bool) -> void:
	"""Apply or remove mutator effects"""
	var mutator: Dictionary = mutators.get(mutator_id, {})
	var effects: Dictionary = mutator.get("effects", {})

	# Apply effects to game systems
	# This is where mutators would actually modify gameplay
	# For now, this is a framework
	print("[Mutators] ", "Applying" if enable else "Removing", " effects for ", mutator_id)


func clear_all_mutators() -> void:
	"""Disable all mutators"""
	for mutator_id in active_mutators.duplicate():
		disable_mutator(mutator_id)


func is_active(mutator_id: String) -> bool:
	"""Check if mutator is active"""
	return mutator_id in active_mutators


func get_active_mutators() -> Array[String]:
	"""Get list of active mutators"""
	return active_mutators


func get_score_multiplier() -> float:
	"""Calculate total score multiplier from active mutators"""
	var total_mult: float = 1.0

	for mutator_id in active_mutators:
		var mutator: Dictionary = mutators.get(mutator_id, {})
		total_mult *= mutator.get("score_mult", 1.0)

	return total_mult


func get_mutator_info(mutator_id: String) -> Dictionary:
	"""Get mutator information"""
	return mutators.get(mutator_id, {})


func get_all_mutators() -> Dictionary:
	"""Get all mutator definitions"""
	return mutators


func get_mutators_by_type(type: String) -> Array[String]:
	"""Get mutators of specific type"""
	var result: Array[String] = []

	for mutator_id in mutators.keys():
		var mutator: Dictionary = mutators[mutator_id]
		if mutator.get("type", "") == type:
			result.append(mutator_id)

	return result


func unlock_mutator(mutator_id: String) -> void:
	"""Unlock a mutator"""
	if mutators.has(mutator_id):
		mutators[mutator_id]["unlocked"] = true
		save_mutator_state()
		print("[Mutators] Unlocked: ", mutator_id)


## Save/Load

func save_mutator_state() -> void:
	"""Save mutator state"""
	var unlocked_list: Array[String] = []

	for mutator_id in mutators.keys():
		if mutators[mutator_id].get("unlocked", false):
			unlocked_list.append(mutator_id)

	var save_data: Dictionary = {
		"unlocked": unlocked_list,
		"active": active_mutators,
		"version": 1
	}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()


func load_mutator_state() -> void:
	"""Load mutator state"""
	if not FileAccess.file_exists(save_path):
		return

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data: Dictionary = file.get_var()
		file.close()

		var unlocked_list: Array = save_data.get("unlocked", [])
		for mutator_id in unlocked_list:
			if mutators.has(mutator_id):
				mutators[mutator_id]["unlocked"] = true

		# Don't auto-enable saved mutators - let player choose
		print("[Mutators] Loaded: ", unlocked_list.size(), " unlocked")
