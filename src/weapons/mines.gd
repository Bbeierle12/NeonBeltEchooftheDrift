extends Weapon
class_name Mines
## Mines - Deploy sticky or proximity mines
##
## Features:
## - Sticky mode: Attaches to asteroids
## - Proximity mode: Floats and detonates when enemies approach
## - Arm delay to prevent self-damage
## - Limited lifetime

# Mine stats
var damage_per_mine: float = 180.0
var proximity_radius: float = 60.0
var mine_lifetime: float = 20.0
var arm_time: float = 0.3
var deploy_velocity: float = 200.0

# Mode toggle
enum MineMode { STICKY, PROXIMITY }
var current_mode: MineMode = MineMode.STICKY

# Active mines tracking
var active_mines: Array[Mine] = []
var max_active_mines: int = 12


func initialize(weapon_type: String) -> void:
	"""Initialize mines from data"""
	weapon_id = weapon_type
	weapon_data = DataLoader.get_weapon(weapon_type)

	if weapon_data.is_empty():
		push_error("[Mines] Failed to load weapon data: ", weapon_type)
		return

	# Load stats
	fire_rate = weapon_data.get("deploy_rate", 2.0)
	damage_per_mine = weapon_data.get("damage", 180.0)
	proximity_radius = weapon_data.get("proximity_radius", 60.0)
	mine_lifetime = weapon_data.get("mine_lifetime", 20.0)
	arm_time = weapon_data.get("arm_time", 0.3)
	heat_per_shot = weapon_data.get("heat_per_shot", 5.0)

	# Ammo
	uses_ammo = true
	max_ammo = weapon_data.get("ammo_capacity", 24)
	current_ammo = max_ammo

	print("[Mines] Initialized: ", weapon_data.get("name", weapon_id))


func toggle_mode() -> void:
	"""Toggle between sticky and proximity modes"""
	if current_mode == MineMode.STICKY:
		current_mode = MineMode.PROXIMITY
		print("[Mines] Mode: Proximity")
	else:
		current_mode = MineMode.STICKY
		print("[Mines] Mode: Sticky")


func _spawn_projectile(direction: Vector2) -> void:
	"""Deploy a mine"""
	# Check mine limit
	if active_mines.size() >= max_active_mines:
		# Remove oldest mine
		if active_mines.size() > 0 and is_instance_valid(active_mines[0]):
			active_mines[0].queue_free()
		active_mines.pop_front()

	# Create mine
	var mine: Mine = Mine.new()
	get_tree().root.add_child(mine)

	# Position ahead of ship
	mine.global_position = ship.global_position + direction * 30

	# Calculate damage (with Overdrive bonus if active)
	var dmg: float = damage_per_mine
	if ship and ship.is_overdriving():
		dmg *= 2.0

	# Initialize mine
	var velocity: Vector2 = direction.normalized() * deploy_velocity
	mine.initialize_mine(dmg, "explosive", velocity, mine_lifetime, proximity_radius, arm_time, current_mode)
	mine.shooter = ship

	# Track active mine
	active_mines.append(mine)
	mine.tree_exited.connect(_on_mine_destroyed.bind(mine))

	fired.emit(mine)


func _on_mine_destroyed(mine: Mine) -> void:
	"""Remove mine from tracking when destroyed"""
	active_mines.erase(mine)


## Mine - Sticky or proximity explosive
class Mine extends Area2D:
	var damage: float = 180.0
	var damage_type: String = "explosive"
	var velocity: Vector2 = Vector2.ZERO
	var lifetime: float = 20.0
	var proximity_radius: float = 60.0
	var arm_time: float = 0.3
	var mode: MineMode = MineMode.STICKY
	var shooter: Node2D = null

	var is_armed: bool = false
	var is_attached: bool = false
	var attached_body: Node2D = null
	var has_detonated: bool = false

	# Visual
	var sprite: ColorRect = null
	var proximity_indicator: Line2D = null

	func initialize_mine(dmg: float, dmg_type: String, vel: Vector2, life: float, prox_rad: float, arm: float, mine_mode: MineMode) -> void:
		"""Initialize mine parameters"""
		damage = dmg
		damage_type = dmg_type
		velocity = vel
		lifetime = life
		proximity_radius = prox_rad
		arm_time = arm
		mode = mine_mode

		# Setup collision
		collision_layer = 0
		collision_mask = 2 | 16  # Asteroids + enemies
		monitoring = false  # Don't monitor until armed

		# Visual
		sprite = ColorRect.new()
		sprite.color = Color(1.0, 0.0, 0.0, 0.8) if mode == MineMode.STICKY else Color(1.0, 0.5, 0.0, 0.8)
		sprite.size = Vector2(12, 12)
		sprite.position = -sprite.size / 2
		add_child(sprite)

		# Proximity indicator
		if mode == MineMode.PROXIMITY:
			proximity_indicator = Line2D.new()
			proximity_indicator.width = 1.0
			proximity_indicator.default_color = Color(1.0, 0.5, 0.0, 0.3)
			add_child(proximity_indicator)
			_update_proximity_circle()

		# Connect signals
		body_entered.connect(_on_body_entered)

	func _physics_process(delta: float) -> void:
		# Arm after delay
		if not is_armed:
			arm_time -= delta
			if arm_time <= 0:
				is_armed = true
				monitoring = true
				sprite.color.a = 1.0  # Full opacity when armed

		# Lifetime
		lifetime -= delta
		if lifetime <= 0:
			queue_free()
			return

		# Movement
		if not is_attached:
			global_position += velocity * delta

			# Sticky mode: Check for attachment
			if mode == MineMode.STICKY and is_armed:
				_check_sticky_attachment()
		else:
			# Follow attached body
			if is_instance_valid(attached_body):
				global_position = attached_body.global_position
			else:
				is_attached = false

		# Proximity detection
		if mode == MineMode.PROXIMITY and is_armed and not is_attached:
			_check_proximity_detonation()

	func _check_sticky_attachment() -> void:
		"""Check if mine should stick to an asteroid"""
		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query: = PhysicsPointQueryParameters2D.new()
		query.position = global_position
		query.collision_mask = 2  # Asteroids only

		var results: Array[Dictionary] = space_state.intersect_point(query, 1)
		if results.size() > 0:
			attached_body = results[0].collider
			is_attached = true
			velocity = Vector2.ZERO

	func _check_proximity_detonation() -> void:
		"""Check if any enemies are in proximity range"""
		if has_detonated:
			return

		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query: = PhysicsShapeQueryParameters2D.new()
		var circle: = CircleShape2D.new()
		circle.radius = proximity_radius
		query.shape = circle
		query.transform = Transform2D(0, global_position)
		query.collision_mask = 2 | 16  # Asteroids + enemies

		var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
		for result in results:
			var body: Node2D = result.collider
			if body and body != shooter:
				_detonate()
				return

	func _on_body_entered(body: Node2D) -> void:
		"""Detonate on direct contact"""
		if not is_armed or body == shooter or has_detonated:
			return

		_detonate()

	func _detonate() -> void:
		"""Explode and damage nearby targets"""
		if has_detonated:
			return

		has_detonated = true

		# Deal damage in radius
		var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		var query: = PhysicsShapeQueryParameters2D.new()
		var circle: = CircleShape2D.new()
		circle.radius = proximity_radius * 1.5  # Larger damage radius
		query.shape = circle
		query.transform = Transform2D(0, global_position)
		query.collision_mask = 2 | 16  # Asteroids + enemies

		var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
		for result in results:
			var body: Node2D = result.collider
			if body and body != shooter and body.has_method("take_damage"):
				body.take_damage(damage, damage_type)

		# Visual: Explosion
		_create_explosion_vfx()

		# Remove mine
		queue_free()

	func _create_explosion_vfx() -> void:
		"""Create explosion visual"""
		var explosion: ColorRect = ColorRect.new()
		explosion.color = Color(1.0, 0.3, 0.0, 0.7)
		explosion.size = Vector2(proximity_radius * 3, proximity_radius * 3)
		explosion.position = -explosion.size / 2
		get_tree().root.add_child(explosion)
		explosion.global_position = global_position

		var tween: Tween = get_tree().create_tween()
		tween.tween_property(explosion, "modulate:a", 0.0, 0.4)
		tween.tween_callback(explosion.queue_free)

	func _update_proximity_circle() -> void:
		"""Draw proximity detection radius"""
		if not proximity_indicator:
			return

		proximity_indicator.clear_points()
		var segments: int = 24
		for i in range(segments + 1):
			var angle: float = (float(i) / float(segments)) * TAU
			var point: Vector2 = Vector2(cos(angle), sin(angle)) * proximity_radius
			proximity_indicator.add_point(point)
