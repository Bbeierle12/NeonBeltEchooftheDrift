extends Ship
class_name Gunship
## Gunship (Anvil-4) - Heavy weapons platform
##
## Signature: Overcharge - Doubles rate-of-fire for 3s, triples heat generation
## Passive: Internal Ammo Bay - +20% ammo capacity
## Playstyle: Sustained DPS, tankier but slower

# Overcharge ability
var overcharge_active: bool = false
var overcharge_duration: float = 3.0
var overcharge_max_duration: float = 3.0
var overcharge_cooldown_time: float = 12.0
var overcharge_cooldown: float = 0.0
var overcharge_rof_mult: float = 2.0
var overcharge_heat_mult: float = 3.0

# Stats (overriding base Ship)
var gunship_max_hull: float = 140.0
var gunship_max_shields: float = 100.0
var gunship_max_speed: float = 180.0
var gunship_acceleration: float = 600.0
var gunship_turn_rate: float = 260.0
var gunship_max_heat: float = 140.0
var gunship_heat_dissipation: float = 10.0


func _ready() -> void:
	# Override base stats
	max_hull = gunship_max_hull
	current_hull = gunship_max_hull
	max_shields = gunship_max_shields
	current_shields = gunship_max_shields
	max_speed = gunship_max_speed
	acceleration = gunship_acceleration
	turn_rate = gunship_turn_rate
	max_heat = gunship_max_heat
	heat_dissipation_rate = gunship_heat_dissipation

	super._ready()

	print("[Gunship] Anvil-4 initialized - Heavy weapons platform")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Update overcharge duration
	if overcharge_active:
		overcharge_duration -= delta
		if overcharge_duration <= 0:
			_deactivate_overcharge()

	# Update overcharge cooldown
	if overcharge_cooldown > 0:
		overcharge_cooldown -= delta


func _process_input(delta: float) -> void:
	super._process_input(delta)

	# Overcharge input (replace overdrive)
	if Input.is_action_just_pressed("overdrive"):
		_activate_overcharge()


func _activate_overcharge() -> void:
	"""Activate Overcharge ability"""
	if overcharge_cooldown > 0 or overcharge_active:
		return

	overcharge_active = true
	overcharge_duration = overcharge_max_duration

	print("[Gunship] Overcharge activated! 2x RoF, 3x Heat")

	# Apply weapon modifiers
	_apply_overcharge_to_weapons(true)


func _deactivate_overcharge() -> void:
	"""Deactivate Overcharge"""
	if not overcharge_active:
		return

	overcharge_active = false
	overcharge_cooldown = overcharge_cooldown_time

	print("[Gunship] Overcharge ended. Cooldown: ", overcharge_cooldown, "s")

	# Remove weapon modifiers
	_apply_overcharge_to_weapons(false)


func _apply_overcharge_to_weapons(active: bool) -> void:
	"""Apply/remove Overcharge modifiers to equipped weapons"""
	if weapon_slot_a:
		_modify_weapon(weapon_slot_a, active)

	if weapon_slot_b:
		_modify_weapon(weapon_slot_b, active)


func _modify_weapon(weapon: Weapon, overcharge_on: bool) -> void:
	"""Modify weapon fire rate and heat"""
	if not weapon:
		return

	if overcharge_on:
		# Double fire rate, triple heat
		weapon.fire_rate *= overcharge_rof_mult
		weapon.heat_per_shot *= overcharge_heat_mult
	else:
		# Restore original values
		weapon.fire_rate /= overcharge_rof_mult
		weapon.heat_per_shot /= overcharge_heat_mult


func add_heat(amount: float) -> void:
	"""Override to apply Overcharge heat multiplier"""
	var modified_amount: float = amount
	if overcharge_active:
		modified_amount *= overcharge_heat_mult

	super.add_heat(modified_amount)


func equip_weapon(weapon_id: String, slot: String) -> void:
	"""Override to apply ammo capacity bonus"""
	super.equip_weapon(weapon_id, slot)

	# Apply ammo bay passive: +20% ammo capacity
	var weapon: Weapon = null
	if slot == "A":
		weapon = weapon_slot_a
	elif slot == "B":
		weapon = weapon_slot_b

	if weapon and weapon.uses_ammo:
		var ammo_bonus: int = int(weapon.max_ammo * 0.2)
		weapon.max_ammo += ammo_bonus
		weapon.current_ammo += ammo_bonus
		print("[Gunship] Ammo Bay bonus: +", ammo_bonus, " ammo for ", weapon_id)


func is_overcharging() -> bool:
	"""Check if Overcharge is active"""
	return overcharge_active


# Override to prevent standard Overdrive
func _activate_overdrive() -> void:
	# Gunship uses Overcharge instead
	pass


func is_overdriving() -> bool:
	"""Override to return Overcharge status for weapon damage calculations"""
	return overcharge_active
