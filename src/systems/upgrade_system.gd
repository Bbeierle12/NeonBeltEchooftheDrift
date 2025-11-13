extends Node
class_name UpgradeSystem
## UpgradeSystem - Manages run-based upgrades
##
## Features:
## - Track active upgrades during run
## - Apply upgrade effects to weapons and ship
## - Stack upgrades (with diminishing returns where appropriate)
## - Query upgrade status

signal upgrade_applied(upgrade_id: String, level: int)
signal upgrade_removed(upgrade_id: String)

# Active upgrades (upgrade_id -> level)
var active_upgrades: Dictionary = {}

# Upgrade definitions
var upgrade_data: Dictionary = {
	"pierce": {
		"name": "Pierce",
		"description": "Projectiles pierce through targets",
		"max_level": 3,
		"effects": {
			1: {"pierce_count": 1},
			2: {"pierce_count": 2},
			3: {"pierce_count": -1}  # Infinite pierce at level 3
		}
	},
	"ricochet": {
		"name": "Ricochet",
		"description": "Projectiles bounce to nearby targets",
		"max_level": 3,
		"effects": {
			1: {"ricochet_count": 1, "ricochet_range": 150.0},
			2: {"ricochet_count": 2, "ricochet_range": 200.0},
			3: {"ricochet_count": 3, "ricochet_range": 250.0}
		}
	},
	"chain": {
		"name": "Chain Lightning",
		"description": "Energy weapons chain to nearby targets",
		"max_level": 3,
		"effects": {
			1: {"chain_count": 2, "chain_range": 180.0, "chain_damage_mult": 0.7},
			2: {"chain_count": 3, "chain_range": 220.0, "chain_damage_mult": 0.8},
			3: {"chain_count": 5, "chain_range": 280.0, "chain_damage_mult": 0.9}
		}
	},
	"split": {
		"name": "Split Shot",
		"description": "Projectiles split into multiple shots",
		"max_level": 2,
		"effects": {
			1: {"split_count": 2, "split_angle": 30.0, "split_damage_mult": 0.6},
			2: {"split_count": 3, "split_angle": 45.0, "split_damage_mult": 0.7}
		}
	},
	"magnet": {
		"name": "Scrap Magnet",
		"description": "Attract loot from greater distance",
		"max_level": 3,
		"effects": {
			1: {"magnet_radius": 150.0},
			2: {"magnet_radius": 250.0},
			3: {"magnet_radius": 400.0}
		}
	},
	"overdrive_plus": {
		"name": "Overdrive+",
		"description": "Extended Overdrive duration",
		"max_level": 3,
		"effects": {
			1: {"overdrive_duration_bonus": 1.0},  # +1 second
			2: {"overdrive_duration_bonus": 2.0},  # +2 seconds
			3: {"overdrive_duration_bonus": 3.5}   # +3.5 seconds
		}
	},
	"heat_sink": {
		"name": "Heat Sink",
		"description": "Reduced heat generation",
		"max_level": 3,
		"effects": {
			1: {"heat_reduction": 0.15},  # 15% less heat
			2: {"heat_reduction": 0.25},  # 25% less heat
			3: {"heat_reduction": 0.40}   # 40% less heat
		}
	},
	"rapid_vent": {
		"name": "Rapid Vent",
		"description": "Faster heat dissipation",
		"max_level": 3,
		"effects": {
			1: {"vent_rate_bonus": 0.5},   # +50% vent rate
			2: {"vent_rate_bonus": 1.0},   # +100% vent rate
			3: {"vent_rate_bonus": 1.5}    # +150% vent rate
		}
	},
	"shield_boost": {
		"name": "Shield Boost",
		"description": "Increased maximum shields",
		"max_level": 3,
		"effects": {
			1: {"shield_bonus": 20.0},
			2: {"shield_bonus": 40.0},
			3: {"shield_bonus": 70.0}
		}
	},
	"hull_plating": {
		"name": "Hull Plating",
		"description": "Increased maximum hull",
		"max_level": 3,
		"effects": {
			1: {"hull_bonus": 15.0},
			2: {"hull_bonus": 30.0},
			3: {"hull_bonus": 50.0}
		}
	}
}


func _ready() -> void:
	# Connect to run events
	GameManager.game_started.connect(_on_run_started)
	GameManager.game_over.connect(_on_run_ended)


func _on_run_started() -> void:
	"""Clear upgrades at start of new run"""
	active_upgrades.clear()


func _on_run_ended(_reason: String) -> void:
	"""Clear upgrades when run ends"""
	active_upgrades.clear()


func apply_upgrade(upgrade_id: String) -> bool:
	"""Apply or level up an upgrade"""
	if not upgrade_data.has(upgrade_id):
		push_error("[UpgradeSystem] Unknown upgrade: ", upgrade_id)
		return false

	var upgrade_info: Dictionary = upgrade_data[upgrade_id]
	var current_level: int = active_upgrades.get(upgrade_id, 0)
	var max_level: int = upgrade_info.get("max_level", 1)

	# Check if can upgrade
	if current_level >= max_level:
		print("[UpgradeSystem] ", upgrade_id, " already at max level")
		return false

	# Level up
	var new_level: int = current_level + 1
	active_upgrades[upgrade_id] = new_level

	print("[UpgradeSystem] Applied ", upgrade_id, " (Level ", new_level, ")")

	# Apply effects
	_apply_upgrade_effects(upgrade_id, new_level)

	upgrade_applied.emit(upgrade_id, new_level)
	return true


func remove_upgrade(upgrade_id: String) -> void:
	"""Remove an upgrade"""
	if active_upgrades.has(upgrade_id):
		active_upgrades.erase(upgrade_id)
		upgrade_removed.emit(upgrade_id)
		print("[UpgradeSystem] Removed ", upgrade_id)


func get_upgrade_level(upgrade_id: String) -> int:
	"""Get current level of an upgrade"""
	return active_upgrades.get(upgrade_id, 0)


func has_upgrade(upgrade_id: String) -> bool:
	"""Check if upgrade is active"""
	return active_upgrades.has(upgrade_id)


func get_upgrade_effect(upgrade_id: String, effect_key: String) -> Variant:
	"""Get specific effect value for an upgrade"""
	if not has_upgrade(upgrade_id):
		return null

	var level: int = get_upgrade_level(upgrade_id)
	var upgrade_info: Dictionary = upgrade_data.get(upgrade_id, {})
	var effects: Dictionary = upgrade_info.get("effects", {})
	var level_effects: Dictionary = effects.get(level, {})

	return level_effects.get(effect_key, null)


func get_all_active_upgrades() -> Array:
	"""Get list of all active upgrade IDs"""
	return active_upgrades.keys()


func _apply_upgrade_effects(upgrade_id: String, level: int) -> void:
	"""Apply upgrade effects to game systems"""
	match upgrade_id:
		"magnet":
			# Enable loot magnet
			if has_node("/root/LootSystem"):
				var loot_system: LootSystem = get_node("/root/LootSystem")
				loot_system.enable_magnet(true)
				var magnet_radius: float = get_upgrade_effect("magnet", "magnet_radius")
				loot_system.magnet_radius = magnet_radius

		"overdrive_plus":
			# Apply to player ship
			var ships: Array = get_tree().get_nodes_in_group("player")
			if ships.size() > 0:
				var ship: Ship = ships[0]
				var bonus: float = get_upgrade_effect("overdrive_plus", "overdrive_duration_bonus")
				# TODO: Add overdrive duration bonus to ship

		"shield_boost", "hull_plating":
			# Apply to player ship
			var ships: Array = get_tree().get_nodes_in_group("player")
			if ships.size() > 0:
				var ship: Ship = ships[0]
				if upgrade_id == "shield_boost":
					var bonus: float = get_upgrade_effect("shield_boost", "shield_bonus")
					ship.max_shields += bonus
					ship.current_shields += bonus
				elif upgrade_id == "hull_plating":
					var bonus: float = get_upgrade_effect("hull_plating", "hull_bonus")
					ship.max_hull += bonus
					ship.current_hull += bonus


func get_upgrade_info(upgrade_id: String) -> Dictionary:
	"""Get full info for an upgrade"""
	return upgrade_data.get(upgrade_id, {})


func get_available_upgrades() -> Array[String]:
	"""Get list of all upgrade IDs"""
	return upgrade_data.keys()


func can_upgrade(upgrade_id: String) -> bool:
	"""Check if upgrade can be applied/leveled"""
	if not upgrade_data.has(upgrade_id):
		return false

	var current_level: int = get_upgrade_level(upgrade_id)
	var max_level: int = upgrade_data[upgrade_id].get("max_level", 1)

	return current_level < max_level
