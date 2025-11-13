extends Node
class_name ShopSystem
## ShopSystem - Handles between-wave shopping
##
## Features:
## - Generate random shop inventory
## - Buy/sell weapons
## - Purchase upgrades
## - Repair hull/shields
## - Reroll shop inventory

signal shop_opened()
signal shop_closed()
signal item_purchased(item_type: String, item_id: String, cost: int)
signal item_sold(item_type: String, item_id: String, value: int)
signal shop_rerolled(cost: int)

enum ItemType { WEAPON, UPGRADE, REPAIR, AMMO }

# Shop inventory
var current_inventory: Array[Dictionary] = []

# Shop config
var weapon_slots: int = 3
var upgrade_slots: int = 3
var always_show_repairs: bool = true

# Pricing
var reroll_cost: int = 50
var reroll_cost_increase: int = 25
var current_reroll_cost: int = 50

var hull_repair_cost_per_point: float = 2.0
var shield_repair_cost_per_point: float = 1.5
var ammo_cost_kinetic: int = 20
var ammo_cost_explosive: int = 30

# Shop state
var is_open: bool = false
var times_rerolled: int = 0


func _ready() -> void:
	# Connect to game events
	GameManager.game_started.connect(_on_run_started)
	GameManager.wave_started.connect(_on_wave_started)


func _on_run_started() -> void:
	"""Reset shop at start of run"""
	current_inventory.clear()
	times_rerolled = 0
	current_reroll_cost = reroll_cost
	is_open = false


func _on_wave_started(_wave: int) -> void:
	"""Close shop when wave starts"""
	if is_open:
		close_shop()


func open_shop() -> void:
	"""Open shop and generate inventory"""
	if is_open:
		return

	is_open = true

	# Generate new inventory if empty
	if current_inventory.is_empty():
		generate_inventory()

	shop_opened.emit()
	print("[Shop] Opened - ", current_inventory.size(), " items available")


func close_shop() -> void:
	"""Close shop"""
	if not is_open:
		return

	is_open = false
	shop_closed.emit()
	print("[Shop] Closed")


func generate_inventory() -> void:
	"""Generate random shop inventory"""
	current_inventory.clear()

	# Add weapons
	var available_weapons: Array[String] = ["autocannon", "beam_lance", "rocket", "railgun", "flak", "mines"]
	for i in range(weapon_slots):
		var weapon_id: String = available_weapons[randi() % available_weapons.size()]
		var weapon_data: Dictionary = DataLoader.get_weapon(weapon_id)

		if weapon_data.is_empty():
			continue

		current_inventory.append({
			"type": ItemType.WEAPON,
			"id": weapon_id,
			"name": weapon_data.get("name", weapon_id),
			"cost": weapon_data.get("shop_price", 500),
			"description": weapon_data.get("description", "")
		})

	# Add upgrades
	if has_node("/root/UpgradeSystem"):
		var upgrade_system: UpgradeSystem = get_node("/root/UpgradeSystem")
		var available_upgrades: Array[String] = upgrade_system.get_available_upgrades()

		# Shuffle and pick random upgrades
		available_upgrades.shuffle()

		for i in range(min(upgrade_slots, available_upgrades.size())):
			var upgrade_id: String = available_upgrades[i]
			var upgrade_info: Dictionary = upgrade_system.get_upgrade_info(upgrade_id)

			if upgrade_info.is_empty():
				continue

			# Skip if already at max level
			if not upgrade_system.can_upgrade(upgrade_id):
				continue

			var level: int = upgrade_system.get_upgrade_level(upgrade_id)
			var cost: int = 150 + (level * 100)  # Increases with level

			current_inventory.append({
				"type": ItemType.UPGRADE,
				"id": upgrade_id,
				"name": upgrade_info.get("name", upgrade_id),
				"cost": cost,
				"description": upgrade_info.get("description", ""),
				"current_level": level,
				"max_level": upgrade_info.get("max_level", 1)
			})

	# Add repair options
	if always_show_repairs:
		_add_repair_options()

	print("[Shop] Generated inventory: ", current_inventory.size(), " items")


func _add_repair_options() -> void:
	"""Add hull and shield repair options"""
	var ships: Array = get_tree().get_nodes_in_group("player")
	if ships.size() == 0:
		return

	var ship: Ship = ships[0]

	# Hull repair
	var hull_missing: float = ship.max_hull - ship.current_hull
	if hull_missing > 0:
		var hull_repair_cost: int = int(hull_missing * hull_repair_cost_per_point)
		current_inventory.append({
			"type": ItemType.REPAIR,
			"id": "hull_repair",
			"name": "Full Hull Repair",
			"cost": hull_repair_cost,
			"description": "Repair %.0f hull damage" % hull_missing,
			"repair_amount": hull_missing
		})

	# Shield repair
	var shield_missing: float = ship.max_shields - ship.current_shields
	if shield_missing > 0:
		var shield_repair_cost: int = int(shield_missing * shield_repair_cost_per_point)
		current_inventory.append({
			"type": ItemType.REPAIR,
			"id": "shield_repair",
			"name": "Full Shield Repair",
			"cost": shield_repair_cost,
			"description": "Restore %.0f shields" % shield_missing,
			"repair_amount": shield_missing
		})

	# Ammo refills
	current_inventory.append({
		"type": ItemType.AMMO,
		"id": "ammo_kinetic",
		"name": "Kinetic Ammo",
		"cost": ammo_cost_kinetic,
		"description": "Refill kinetic weapons"
	})

	current_inventory.append({
		"type": ItemType.AMMO,
		"id": "ammo_explosive",
		"name": "Explosive Ammo",
		"cost": ammo_cost_explosive,
		"description": "Refill explosive weapons"
	})


func purchase_item(item_index: int) -> bool:
	"""Purchase an item from shop"""
	if item_index < 0 or item_index >= current_inventory.size():
		push_error("[Shop] Invalid item index: ", item_index)
		return false

	var item: Dictionary = current_inventory[item_index]
	var cost: int = item.get("cost", 0)

	# Check if player can afford
	if GameManager.get_scrap() < cost:
		print("[Shop] Not enough scrap. Need ", cost, ", have ", GameManager.get_scrap())
		return false

	# Process purchase
	var success: bool = false

	match item.type:
		ItemType.WEAPON:
			success = _purchase_weapon(item)
		ItemType.UPGRADE:
			success = _purchase_upgrade(item)
		ItemType.REPAIR:
			success = _purchase_repair(item)
		ItemType.AMMO:
			success = _purchase_ammo(item)

	if success:
		# Deduct scrap
		GameManager.spend_scrap(cost)
		item_purchased.emit(ItemType.keys()[item.type], item.id, cost)
		print("[Shop] Purchased ", item.name, " for ", cost, " scrap")

		# Remove consumable items from inventory
		if item.type in [ItemType.REPAIR, ItemType.AMMO]:
			current_inventory.remove_at(item_index)

	return success


func _purchase_weapon(item: Dictionary) -> bool:
	"""Purchase a weapon"""
	var weapon_id: String = item.id

	# TODO: Open weapon selection UI to choose slot and existing weapon to replace
	# For now, just add to player inventory
	print("[Shop] Weapon purchased: ", weapon_id)
	return true


func _purchase_upgrade(item: Dictionary) -> bool:
	"""Purchase an upgrade"""
	var upgrade_id: String = item.id

	if not has_node("/root/UpgradeSystem"):
		return false

	var upgrade_system: UpgradeSystem = get_node("/root/UpgradeSystem")
	return upgrade_system.apply_upgrade(upgrade_id)


func _purchase_repair(item: Dictionary) -> bool:
	"""Purchase repairs"""
	var ships: Array = get_tree().get_nodes_in_group("player")
	if ships.size() == 0:
		return false

	var ship: Ship = ships[0]
	var repair_amount: float = item.get("repair_amount", 0.0)

	match item.id:
		"hull_repair":
			ship.heal(repair_amount)
			return true
		"shield_repair":
			ship.restore_shields(repair_amount)
			return true

	return false


func _purchase_ammo(item: Dictionary) -> bool:
	"""Purchase ammo refill"""
	var ships: Array = get_tree().get_nodes_in_group("player")
	if ships.size() == 0:
		return false

	var ship: Ship = ships[0]

	# Refill all weapons of matching type
	var ammo_type: String = "kinetic" if item.id == "ammo_kinetic" else "explosive"
	var refilled_count: int = 0

	if ship.weapon_slot_a and ship.weapon_slot_a.uses_ammo:
		var weapon_data: Dictionary = ship.weapon_slot_a.weapon_data
		if weapon_data.get("type", "") == ammo_type:
			ship.weapon_slot_a.reload(ship.weapon_slot_a.max_ammo)
			refilled_count += 1

	if ship.weapon_slot_b and ship.weapon_slot_b.uses_ammo:
		var weapon_data: Dictionary = ship.weapon_slot_b.weapon_data
		if weapon_data.get("type", "") == ammo_type:
			ship.weapon_slot_b.reload(ship.weapon_slot_b.max_ammo)
			refilled_count += 1

	print("[Shop] Refilled ", refilled_count, " ", ammo_type, " weapons")
	return refilled_count > 0


func reroll_shop() -> bool:
	"""Reroll shop inventory for a cost"""
	if GameManager.get_scrap() < current_reroll_cost:
		print("[Shop] Not enough scrap to reroll. Need ", current_reroll_cost)
		return false

	# Deduct cost
	GameManager.spend_scrap(current_reroll_cost)

	# Increase future reroll cost
	times_rerolled += 1
	current_reroll_cost = reroll_cost + (times_rerolled * reroll_cost_increase)

	# Generate new inventory
	generate_inventory()

	shop_rerolled.emit(current_reroll_cost)
	print("[Shop] Rerolled for ", current_reroll_cost, " scrap")

	return true


func get_inventory() -> Array[Dictionary]:
	"""Get current shop inventory"""
	return current_inventory


func get_reroll_cost() -> int:
	"""Get current reroll cost"""
	return current_reroll_cost
