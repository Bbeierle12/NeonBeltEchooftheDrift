extends Weapon
class_name GravSling
## GravSling - Exotic gravity manipulation weapon
##
## Features:
## - Create gravity wells that pull asteroids together
## - Wells last 2.5 seconds
## - Asteroids collide and damage each other
## - Launch asteroids when well collapses

# Grav well stats
var well_duration: float = 2.5
var well_radius: float = 180.0
var pull_strength: float = 250.0
var launch_damage_mult: float = 0.5

# Active wells
var active_wells: Array[GravWell] = []
var max_wells: int = 3


func initialize(weapon_type: String) -> void:
	"""Initialize grav sling from data"""
	weapon_id = weapon_type
	weapon_data = DataLoader.get_weapon(weapon_type)

	if weapon_data.is_empty():
		push_error("[GravSling] Failed to load weapon data: ", weapon_type)
		return

	# Load stats
	fire_rate = weapon_data.get("fire_rate", 1.5)
	well_duration = weapon_data.get("well_duration", 2.5)
	well_radius = weapon_data.get("well_radius", 180.0)
	pull_strength = weapon_data.get("pull_strength", 250.0)
	launch_damage_mult = weapon_data.get("launch_damage_mult", 0.5)
	heat_per_shot = weapon_data.get("heat_per_shot", 25.0)

	# Energy weapon - no ammo
	uses_ammo = false

	print("[GravSling] Initialized: ", weapon_data.get("name", weapon_id))


func _spawn_projectile(direction: Vector2) -> void:
	"""Spawn gravity well"""
	# Check well limit
	if active_wells.size() >= max_wells:
		# Remove oldest well
		if active_wells.size() > 0 and is_instance_valid(active_wells[0]):
			active_wells[0].collapse_early()
		active_wells.pop_front()

	# Create gravity well
	var well: GravWell = GravWell.new()
	get_tree().root.add_child(well)

	# Position ahead of ship
	var spawn_pos: Vector2 = ship.global_position + direction * 100

	# Initialize well
	well.initialize_well(spawn_pos, well_duration, well_radius, pull_strength, launch_damage_mult)
	well.shooter = ship

	# Track active well
	active_wells.append(well)
	well.tree_exited.connect(_on_well_destroyed.bind(well))

	fired.emit(well)


func _on_well_destroyed(well: GravWell) -> void:
	"""Remove well from tracking"""
	active_wells.erase(well)


## GravWell - Gravity well that pulls asteroids
class GravWell extends Area2D:
	var lifetime: float = 2.5
	var radius: float = 180.0
	var pull_strength: float = 250.0
	var launch_damage_mult: float = 0.5
	var shooter: Node2D = null

	var is_collapsed: bool = false
	var trapped_bodies: Array[RigidBody2D] = []

	# Visual
	var visual_circle: Line2D = null
	var core_visual: ColorRect = null

	func initialize_well(pos: Vector2, duration: float, well_radius: float, strength: float, damage_mult: float) -> void:
		"""Initialize gravity well"""
		global_position = pos
		lifetime = duration
		radius = well_radius
		pull_strength = strength
		launch_damage_mult = damage_mult

		# Setup collision
		collision_layer = 0
		collision_mask = 2 | 16  # Asteroids + enemies
		monitoring = true

		# Visual
		_setup_visual()

		# Setup collision shape
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = radius
		collision_shape.shape = circle
		add_child(collision_shape)

		# Connect signals
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

	func _setup_visual() -> void:
		"""Create visual representation"""
		# Core
		core_visual = ColorRect.new()
		core_visual.color = Color(0.5, 0.0, 1.0, 0.8)  # Purple
		core_visual.size = Vector2(20, 20)
		core_visual.position = -core_visual.size / 2
		add_child(core_visual)

		# Radius indicator
		visual_circle = Line2D.new()
		visual_circle.width = 2.0
		visual_circle.default_color = Color(0.5, 0.0, 1.0, 0.4)  # Purple
		add_child(visual_circle)

		_update_circle_visual()

	func _update_circle_visual() -> void:
		"""Draw gravity well radius"""
		if not visual_circle:
			return

		visual_circle.clear_points()
		var segments: int = 32
		for i in range(segments + 1):
			var angle: float = (float(i) / float(segments)) * TAU
			var point: Vector2 = Vector2(cos(angle), sin(angle)) * radius
			visual_circle.add_point(point)

	func _physics_process(delta: float) -> void:
		if is_collapsed:
			return

		# Lifetime countdown
		lifetime -= delta
		if lifetime <= 0:
			_collapse()
			return

		# Visual pulsing
		if core_visual:
			var pulse: float = 0.6 + 0.4 * sin(lifetime * 8.0)
			core_visual.modulate.a = pulse

		# Pull trapped bodies
		for body in trapped_bodies:
			if not is_instance_valid(body):
				continue

			var direction: Vector2 = (global_position - body.global_position).normalized()
			var distance: float = global_position.distance_to(body.global_position)
			var pull_force: float = pull_strength * (1.0 - distance / radius)  # Stronger near center

			# Apply gravitational pull
			if body is RigidBody2D:
				body.apply_central_force(direction * pull_force)

		# Check for asteroid collisions
		_check_asteroid_collisions()

	func _on_body_entered(body: Node2D) -> void:
		"""Trap body in gravity well"""
		if body == shooter:
			return

		if body is RigidBody2D and body not in trapped_bodies:
			trapped_bodies.append(body)
			print("[GravWell] Trapped: ", body.name)

	func _on_body_exited(body: Node2D) -> void:
		"""Release body from gravity well"""
		trapped_bodies.erase(body)

	func _check_asteroid_collisions() -> void:
		"""Check if asteroids are colliding and damage them"""
		# Check pairs of trapped bodies for collisions
		for i in range(trapped_bodies.size()):
			if not is_instance_valid(trapped_bodies[i]):
				continue

			for j in range(i + 1, trapped_bodies.size()):
				if not is_instance_valid(trapped_bodies[j]):
					continue

				var body_a: RigidBody2D = trapped_bodies[i]
				var body_b: RigidBody2D = trapped_bodies[j]

				# Check distance
				var distance: float = body_a.global_position.distance_to(body_b.global_position)
				var collision_threshold: float = 50.0  # Approximate collision distance

				if distance < collision_threshold:
					# Asteroids collided - damage both
					if body_a.has_method("take_damage") and body_b.has_method("take_damage"):
						var collision_damage: float = 30.0
						body_a.take_damage(collision_damage, "kinetic")
						body_b.take_damage(collision_damage, "kinetic")
						print("[GravWell] Asteroid collision!")

	func _collapse() -> void:
		"""Collapse gravity well and launch asteroids"""
		if is_collapsed:
			return

		is_collapsed = true
		print("[GravWell] Collapsing!")

		# Launch all trapped asteroids outward
		for body in trapped_bodies:
			if not is_instance_valid(body):
				continue

			# Calculate launch direction (away from well)
			var direction: Vector2 = (body.global_position - global_position).normalized()
			var launch_velocity: Vector2 = direction * 400.0

			# Apply launch force
			if body is RigidBody2D:
				body.linear_velocity = launch_velocity

			# Deal launch damage
			if body.has_method("take_damage"):
				var damage: float = body.mass if "mass" in body else 50.0
				damage *= launch_damage_mult
				body.take_damage(damage, "kinetic")

		# Visual: Collapse effect
		_create_collapse_effect()

		# Remove well
		queue_free()

	func collapse_early() -> void:
		"""Force early collapse (when well limit reached)"""
		_collapse()

	func _create_collapse_effect() -> void:
		"""Visual effect for well collapse"""
		# Expanding ring
		var ring: Line2D = Line2D.new()
		ring.width = 3.0
		ring.default_color = Color(0.5, 0.0, 1.0, 0.8)
		get_tree().root.add_child(ring)
		ring.global_position = global_position

		# Draw circle
		var segments: int = 32
		for i in range(segments + 1):
			var angle: float = (float(i) / float(segments)) * TAU
			var point: Vector2 = Vector2(cos(angle), sin(angle)) * radius
			ring.add_point(point)

		# Animate collapse
		var tween: Tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector2(0.5, 0.5), 0.4)
		tween.tween_property(ring, "modulate:a", 0.0, 0.4)
		tween.chain().tween_callback(ring.queue_free)
