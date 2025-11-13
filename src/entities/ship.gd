extends CharacterBody2D
class_name Ship
## Ship - Player ship with flight physics and combat systems
##
## Implements:
## - Twin-stick flight model (thrust, drift, rotation)
## - Heat management
## - Weapon systems
## - Shield/hull damage
## - Hypershift dash
## - Overdrive ability
## - Screen wrapping

signal died(death_cause: String)
signal hull_changed(current: float, maximum: float)
signal shields_changed(current: float, maximum: float)
signal heat_changed(current: float, maximum: float)
signal hypershift_ready()
signal overdrive_ready()

# Ship data
var ship_data: Dictionary = {}

# Stats (loaded from JSON)
var max_hull: float = 100.0
var max_shields: float = 75.0
var max_speed: float = 220.0
var turn_rate: float = 340.0
var acceleration: float = 800.0
var max_heat: float = 100.0
var heat_dissipation: float = 12.0

# Current state
var current_hull: float = 100.0
var current_shields: float = 75.0
var current_heat: float = 0.0
var is_alive: bool = true

# Flight physics
var thrust_input: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT
var angular_velocity: float = 0.0

# Abilities
var hypershift_cooldown: float = 0.0
var hypershift_duration: float = 0.0
var hypershift_invuln_duration: float = 0.2
const HYPERSHIFT_COOLDOWN: float = 1.2
const HYPERSHIFT_SPEED_MULT: float = 3.0

var overdrive_cooldown: float = 0.0
var overdrive_duration: float = 0.0
const OVERDRIVE_COOLDOWN: float = 12.0
const OVERDRIVE_DURATION: float = 3.0

var is_venting_heat: bool = false
var shields_disabled: bool = false
var shields_disabled_timer: float = 0.0

# Input state
var using_mouse_aim: bool = true

# Weapons
var weapon_slot_a: Weapon = null
var weapon_slot_b: Weapon = null
var active_weapon: Weapon = null

# Screen bounds
var screen_size: Vector2


func _ready() -> void:
	screen_size = get_viewport_rect().size
	add_to_group("player")


func initialize(ship_id: String) -> void:
	"""Initialize ship from data"""
	ship_data = DataLoader.get_ship(ship_id)

	if ship_data.is_empty():
		push_error("[Ship] Failed to load ship data: ", ship_id)
		return

	# Load stats
	var stats: Dictionary = ship_data.get("stats", {})
	max_hull = stats.get("hull", 100.0)
	max_shields = stats.get("shields", 75.0)
	max_speed = stats.get("speed", 220.0)
	turn_rate = stats.get("turnRate", 340.0)
	acceleration = stats.get("acceleration", 800.0)
	max_heat = stats.get("heatCapacity", 100.0)
	heat_dissipation = stats.get("heatDissipation", 12.0)

	# Initialize current values
	current_hull = max_hull
	current_shields = max_shields
	current_heat = 0.0

	# Equip starter weapons
	equip_weapon("autocannon", "A")
	equip_weapon("beam_lance", "B")

	print("[Ship] Initialized: ", ship_data.get("displayName", ship_id))


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_process_input()
	_process_flight(delta)
	_process_cooldowns(delta)
	_process_heat(delta)
	_process_screen_wrap()
	_update_rotation()

	move_and_slide()


func _process_input() -> void:
	"""Process player input"""
	# Movement input (WASD or left stick)
	thrust_input = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if thrust_input.length() > 1.0:
		thrust_input = thrust_input.normalized()

	# Aim input (Mouse or right stick or arrow keys)
	var aim_stick: Vector2 = Vector2(
		Input.get_axis("aim_left", "aim_right"),
		Input.get_axis("aim_up", "aim_down")
	)

	if aim_stick.length() > 0.2:
		aim_direction = aim_stick.normalized()
		using_mouse_aim = false
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("fire"):
		var mouse_pos: Vector2 = get_global_mouse_position()
		aim_direction = (mouse_pos - global_position).normalized()
		using_mouse_aim = true

	# Abilities
	if Input.is_action_just_pressed("hypershift"):
		_activate_hypershift()

	if Input.is_action_just_pressed("overdrive"):
		_activate_overdrive()

	if Input.is_action_just_pressed("vent_heat"):
		_start_heat_vent()

	# Weapon firing
	if Input.is_action_just_pressed("fire"):
		# Start charging for charge weapons
		if active_weapon and active_weapon is Railgun:
			active_weapon.start_charging()

	if Input.is_action_pressed("fire"):
		if active_weapon:
			# Update charge for charge weapons
			if active_weapon is Railgun:
				active_weapon.update_charge(delta)
			# Regular firing for other weapons (skip if beam is already active)
			elif not (active_weapon is BeamLance and active_weapon.is_beam_active) and not (active_weapon is PlasmaCutter and active_weapon.is_beam_active):
				active_weapon.fire(aim_direction)
	else:
		# Release charged shot
		if active_weapon and active_weapon is Railgun:
			active_weapon.release_shot(aim_direction)
		# Stop beam weapons when fire is released
		if active_weapon and active_weapon is BeamLance:
			active_weapon.stop_firing()
		if active_weapon and active_weapon is PlasmaCutter:
			active_weapon.stop_firing()


func _process_flight(delta: float) -> void:
	"""Process flight physics"""
	# Calculate desired velocity based on thrust input
	var desired_velocity: Vector2 = thrust_input * max_speed

	# Apply hypershift speed boost
	if hypershift_duration > 0:
		desired_velocity *= HYPERSHIFT_SPEED_MULT

	# Smoothly interpolate to desired velocity
	velocity = velocity.lerp(desired_velocity, acceleration * delta / max_speed)

	# Apply drag when not thrusting
	if thrust_input.length() < 0.1:
		velocity = velocity.lerp(Vector2.ZERO, 2.0 * delta)


func _update_rotation() -> void:
	"""Update ship rotation to face aim direction"""
	if aim_direction.length() > 0.1:
		var target_angle: float = aim_direction.angle()
		var current_angle: float = rotation
		var angle_diff: float = angle_difference(current_angle, target_angle)

		# Rotate towards target
		var turn_speed: float = deg_to_rad(turn_rate) * get_physics_process_delta_time()
		if abs(angle_diff) < turn_speed:
			rotation = target_angle
		else:
			rotation += sign(angle_diff) * turn_speed


func _process_cooldowns(delta: float) -> void:
	"""Update ability cooldowns"""
	# Hypershift
	if hypershift_cooldown > 0:
		hypershift_cooldown -= delta
		if hypershift_cooldown <= 0:
			hypershift_ready.emit()

	if hypershift_duration > 0:
		hypershift_duration -= delta

	# Overdrive
	if overdrive_cooldown > 0:
		overdrive_cooldown -= delta
		if overdrive_cooldown <= 0:
			overdrive_ready.emit()

	if overdrive_duration > 0:
		overdrive_duration -= delta

	# Shield disable
	if shields_disabled:
		shields_disabled_timer -= delta
		if shields_disabled_timer <= 0:
			shields_disabled = false
			print("[Ship] Shields re-enabled")


func _process_heat(delta: float) -> void:
	"""Process heat generation and dissipation"""
	# Dissipate heat over time
	if current_heat > 0:
		var dissipation_rate: float = heat_dissipation
		if is_venting_heat:
			dissipation_rate *= 3.0  # Faster dissipation when venting

		current_heat -= dissipation_rate * delta
		current_heat = max(0.0, current_heat)

		heat_changed.emit(current_heat, max_heat)

	# Stop venting when heat reaches 0
	if is_venting_heat and current_heat <= 0:
		is_venting_heat = false


func _process_screen_wrap() -> void:
	"""Wrap ship position at screen edges"""
	var margin: float = 50.0  # Wrap slightly offscreen

	if global_position.x < -margin:
		global_position.x = screen_size.x + margin
	elif global_position.x > screen_size.x + margin:
		global_position.x = -margin

	if global_position.y < -margin:
		global_position.y = screen_size.y + margin
	elif global_position.y > screen_size.y + margin:
		global_position.y = -margin


func _activate_hypershift() -> void:
	"""Activate Hypershift dash ability"""
	if hypershift_cooldown > 0:
		return

	hypershift_cooldown = HYPERSHIFT_COOLDOWN
	hypershift_duration = hypershift_invuln_duration

	# Add velocity boost in aim direction
	velocity += aim_direction * max_speed * 2.0

	print("[Ship] Hypershift activated!")


func _activate_overdrive() -> void:
	"""Activate Overdrive ability"""
	if overdrive_cooldown > 0:
		return

	overdrive_cooldown = OVERDRIVE_COOLDOWN
	overdrive_duration = OVERDRIVE_DURATION

	print("[Ship] Overdrive activated!")


func _start_heat_vent() -> void:
	"""Manually vent heat (disables shields temporarily)"""
	if is_venting_heat or current_heat <= 0:
		return

	is_venting_heat = true
	shields_disabled = true
	shields_disabled_timer = 1.0

	print("[Ship] Venting heat - shields disabled!")


func add_heat(amount: float) -> void:
	"""Add heat to the ship"""
	current_heat += amount
	current_heat = min(current_heat, max_heat)

	heat_changed.emit(current_heat, max_heat)

	if current_heat >= max_heat:
		print("[Ship] ⚠️ Overheated!")


func take_damage(amount: float, source: String = "unknown") -> void:
	"""Take damage to shields first, then hull"""
	if not is_alive:
		return

	# Invulnerable during hypershift
	if hypershift_duration > 0:
		return

	var remaining_damage: float = amount

	# Damage shields first (if not disabled)
	if not shields_disabled and current_shields > 0:
		var shield_damage: float = min(remaining_damage, current_shields)
		current_shields -= shield_damage
		remaining_damage -= shield_damage
		shields_changed.emit(current_shields, max_shields)

	# Damage hull with remaining damage
	if remaining_damage > 0:
		current_hull -= remaining_damage
		hull_changed.emit(current_hull, max_hull)

		if current_hull <= 0:
			_die(source)

	print("[Ship] Took ", amount, " damage (", source, ") - Hull: ", current_hull, " | Shields: ", current_shields)


func heal(amount: float) -> void:
	"""Heal hull"""
	current_hull = min(current_hull + amount, max_hull)
	hull_changed.emit(current_hull, max_hull)


func restore_shields(amount: float) -> void:
	"""Restore shields"""
	if shields_disabled:
		return

	current_shields = min(current_shields + amount, max_shields)
	shields_changed.emit(current_shields, max_shields)


func _die(death_cause: String) -> void:
	"""Handle ship death"""
	if not is_alive:
		return

	is_alive = false
	velocity = Vector2.ZERO

	print("[Ship] ☠️ Died - Cause: ", death_cause)

	died.emit(death_cause)

	# TODO: Play death VFX/SFX
	# TODO: Spawn wreckage


func is_overdriving() -> bool:
	"""Check if Overdrive is active"""
	return overdrive_duration > 0.0


func get_heat_percentage() -> float:
	"""Get heat as percentage (0-1)"""
	return current_heat / max_heat


func equip_weapon(weapon_id: String, slot: String) -> void:
	"""Equip a weapon to a slot"""
	var weapon: Weapon = null

	# Create appropriate weapon instance
	match weapon_id:
		"autocannon":
			weapon = preload("res://src/weapons/autocannon.gd").new()
		"beam_lance":
			weapon = preload("res://src/weapons/beam_lance.gd").new()
		"rocket":
			weapon = preload("res://src/weapons/rocket.gd").new()
		"railgun":
			weapon = preload("res://src/weapons/railgun.gd").new()
		"flak":
			weapon = preload("res://src/weapons/flak.gd").new()
		"mines":
			weapon = preload("res://src/weapons/mines.gd").new()
		"grav_sling":
			weapon = preload("res://src/weapons/grav_sling.gd").new()
		"arc_harpoon":
			weapon = preload("res://src/weapons/arc_harpoon.gd").new()
		"pulse_laser":
			weapon = preload("res://src/weapons/pulse_laser.gd").new()
		"plasma_cutter":
			weapon = preload("res://src/weapons/plasma_cutter.gd").new()
		_:
			push_error("[Ship] Unknown weapon: ", weapon_id)
			return

	# Add to scene tree
	add_child(weapon)

	# Initialize weapon
	weapon.initialize(weapon_id)

	# Assign to slot
	match slot:
		"A":
			if weapon_slot_a:
				weapon_slot_a.queue_free()
			weapon_slot_a = weapon
			active_weapon = weapon  # Default to slot A
		"B":
			if weapon_slot_b:
				weapon_slot_b.queue_free()
			weapon_slot_b = weapon

	print("[Ship] Equipped ", weapon_id, " to slot ", slot)
