extends Weapon
class_name ArcHarpoon
## ArcHarpoon - Exotic tether weapon with chain lightning
##
## Features:
## - Harpoon projectiles tether to targets
## - Tethered targets take constant arc damage
## - Lightning chains between nearby tethered targets
## - Maximum 3 tethers active

# Arc harpoon stats
var damage_initial: float = 80.0
var damage_arc: float = 40.0
var arc_damage_per_sec: float = 60.0
var tether_duration: float = 4.0
var max_tethers: int = 3
var chain_range: float = 200.0

# Active tethers
var active_tethers: Array[ArcTether] = []


func initialize(weapon_type: String) -> void:
	"""Initialize arc harpoon from data"""
	weapon_id = weapon_type
	weapon_data = DataLoader.get_weapon(weapon_type)

	if weapon_data.is_empty():
		push_error("[ArcHarpoon] Failed to load weapon data: ", weapon_type)
		return

	# Load stats
	fire_rate = weapon_data.get("fire_rate", 2.0)
	damage_initial = weapon_data.get("damage_initial", 80.0)
	damage_arc = weapon_data.get("damage_arc", 40.0)
	arc_damage_per_sec = weapon_data.get("arc_damage_per_sec", 60.0)
	tether_duration = weapon_data.get("tether_duration", 4.0)
	max_tethers = weapon_data.get("max_tethers", 3)
	chain_range = weapon_data.get("chain_range", 200.0)
	heat_per_shot = weapon_data.get("heat_per_shot", 20.0)
	projectile_speed = weapon_data.get("projectile_speed", 1200.0)

	# Energy weapon - no ammo
	uses_ammo = false

	print("[ArcHarpoon] Initialized: ", weapon_data.get("name", weapon_id))


func _spawn_projectile(direction: Vector2) -> void:
	"""Spawn harpoon projectile"""
	var harpoon: HarpoonProjectile = HarpoonProjectile.new()
	get_tree().root.add_child(harpoon)

	# Position ahead of ship
	harpoon.global_position = ship.global_position + direction * 30

	# Calculate damage (with Overdrive bonus if active)
	var dmg: float = damage_initial
	if ship and ship.is_overdriving():
		dmg *= 2.0

	# Initialize projectile
	var velocity: Vector2 = direction.normalized() * projectile_speed
	harpoon.initialize_harpoon(dmg, velocity, self)
	harpoon.shooter = ship

	fired.emit(harpoon)


func create_tether(target: Node2D, hit_position: Vector2) -> void:
	"""Create arc tether on target"""
	# Check tether limit
	if active_tethers.size() >= max_tethers:
		# Remove oldest tether
		if active_tethers.size() > 0 and is_instance_valid(active_tethers[0]):
			active_tethers[0].break_tether()
		active_tethers.pop_front()

	# Create tether
	var tether: ArcTether = ArcTether.new()
	get_tree().root.add_child(tether)

	# Initialize tether
	tether.initialize_tether(target, hit_position, tether_duration, arc_damage_per_sec, chain_range, active_tethers)
	tether.tether_broken.connect(_on_tether_broken.bind(tether))

	# Track tether
	active_tethers.append(tether)

	print("[ArcHarpoon] Tether created on ", target.name)


func _on_tether_broken(tether: ArcTether) -> void:
	"""Remove broken tether from tracking"""
	active_tethers.erase(tether)


## HarpoonProjectile - Projectile that creates tethers
class HarpoonProjectile extends Projectile:
	var harpoon_weapon: ArcHarpoon = null

	func initialize_harpoon(dmg: float, vel: Vector2, weapon: ArcHarpoon) -> void:
		"""Initialize harpoon projectile"""
		damage = dmg
		damage_type = "energy"
		velocity = vel
		lifetime = 3.0
		harpoon_weapon = weapon

		# Visual: Yellow/white electric projectile
		modulate = Color(1.0, 1.0, 0.3)  # Electric yellow

	func _on_body_entered(body: Node2D) -> void:
		"""Hit target and create tether"""
		if body == shooter:
			return

		if body.has_method("take_damage"):
			# Deal initial impact damage
			body.take_damage(damage, damage_type)
			hit_target.emit(body, damage)

			# Create tether
			if harpoon_weapon:
				harpoon_weapon.create_tether(body, global_position)

		# Destroy projectile
		queue_free()


## ArcTether - Electric tether between weapon and target
class ArcTether extends Node2D:
	signal tether_broken()

	var target: Node2D = null
	var tether_position: Vector2 = Vector2.ZERO
	var duration: float = 4.0
	var arc_damage_per_sec: float = 60.0
	var chain_range: float = 200.0
	var other_tethers: Array[ArcTether] = []

	var is_broken: bool = false
	var arc_timer: float = 0.0
	var arc_interval: float = 0.5  # Apply damage every 0.5s
	var chain_timer: float = 0.0
	var chain_interval: float = 0.25  # Chain every 0.25s

	# Visual
	var tether_line: Line2D = null
	var arc_particles: Array[Line2D] = []

	func initialize_tether(tgt: Node2D, pos: Vector2, dur: float, dps: float, chain_rng: float, tethers: Array[ArcTether]) -> void:
		"""Initialize arc tether"""
		target = tgt
		tether_position = pos
		duration = dur
		arc_damage_per_sec = dps
		chain_range = chain_rng
		other_tethers = tethers

		# Create tether visual
		_setup_visual()

	func _setup_visual() -> void:
		"""Create tether line visual"""
		tether_line = Line2D.new()
		tether_line.width = 2.0
		tether_line.default_color = Color(0.3, 0.7, 1.0, 0.8)  # Electric blue
		add_child(tether_line)

	func _physics_process(delta: float) -> void:
		if is_broken:
			return

		# Check if target still valid
		if not is_instance_valid(target):
			break_tether()
			return

		# Update position to follow target
		global_position = target.global_position

		# Lifetime countdown
		duration -= delta
		if duration <= 0:
			break_tether()
			return

		# Update tether visual
		_update_tether_visual()

		# Arc damage
		arc_timer += delta
		if arc_timer >= arc_interval:
			arc_timer = 0.0
			_apply_arc_damage(delta)

		# Chain lightning
		chain_timer += delta
		if chain_timer >= chain_interval:
			chain_timer = 0.0
			_chain_lightning()

	func _update_tether_visual() -> void:
		"""Update tether line to target"""
		if not tether_line or not is_instance_valid(target):
			return

		# Simple line for now (can add arc/wave effect later)
		tether_line.clear_points()
		tether_line.add_point(Vector2.ZERO)  # Tether point on target

		# Pulsing effect
		var pulse: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
		tether_line.default_color.a = pulse

	func _apply_arc_damage(_delta: float) -> void:
		"""Apply periodic arc damage to tethered target"""
		if not is_instance_valid(target):
			return

		if target.has_method("take_damage"):
			var damage: float = arc_damage_per_sec * arc_interval
			target.take_damage(damage, "energy")

	func _chain_lightning() -> void:
		"""Chain lightning to nearby tethered targets"""
		if not is_instance_valid(target):
			return

		# Find nearby tethered targets
		for other_tether in other_tethers:
			if other_tether == self or not is_instance_valid(other_tether):
				continue

			if not is_instance_valid(other_tether.target):
				continue

			var distance: float = target.global_position.distance_to(other_tether.target.global_position)

			if distance < chain_range:
				# Chain lightning!
				if other_tether.target.has_method("take_damage"):
					var chain_damage: float = arc_damage_per_sec * chain_interval * 0.7  # 70% damage on chain
					other_tether.target.take_damage(chain_damage, "energy")

				# Visual: Lightning arc
				_create_chain_visual(target.global_position, other_tether.target.global_position)

	func _create_chain_visual(from: Vector2, to: Vector2) -> void:
		"""Create visual lightning arc between targets"""
		var lightning: Line2D = Line2D.new()
		lightning.width = 2.0
		lightning.default_color = Color(1.0, 1.0, 0.3, 0.9)  # Bright yellow
		lightning.add_point(from)
		lightning.add_point(to)
		get_tree().root.add_child(lightning)

		# Fade out
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(lightning, "modulate:a", 0.0, 0.15)
		tween.tween_callback(lightning.queue_free)

	func break_tether() -> void:
		"""Break the tether"""
		if is_broken:
			return

		is_broken = true
		tether_broken.emit()
		queue_free()
