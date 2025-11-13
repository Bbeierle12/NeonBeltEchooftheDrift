extends Node
class_name LootSystem
## LootSystem - Manages loot drops and pickups
##
## Features:
## - Spawn loot from destroyed asteroids
## - Different loot types (scrap, ammo, hull repair, special)
## - Pickup detection and effects
## - Magnet upgrade support

signal loot_picked_up(loot_type: String, amount: int)

enum LootType {
	SCRAP,       # Currency
	AMMO_KIN,    # Kinetic ammo
	AMMO_EXP,    # Explosive ammo
	HULL_REPAIR, # Repairs hull
	UPGRADE      # Special upgrade pickup
}

# Loot drop rates (0.0 - 1.0)
var drop_chance_scrap: float = 0.6
var drop_chance_ammo: float = 0.3
var drop_chance_hull: float = 0.15

# Loot values
var scrap_min: int = 5
var scrap_max: int = 20
var ammo_amount: int = 10
var hull_repair_amount: float = 15.0

# Pickup radius
var pickup_radius: float = 40.0
var magnet_radius: float = 150.0
var magnet_enabled: bool = false

# Loot scene
var loot_pickup_scene: PackedScene = null


func _ready() -> void:
	# Create loot pickup scene if needed
	if not loot_pickup_scene:
		_create_loot_scene()


func spawn_loot(position: Vector2, asteroid_type: String, size: String) -> void:
	"""Spawn loot at position based on asteroid type/size"""
	# Determine what loot to drop
	var loot_rolls: Array[Dictionary] = []

	# Roll for scrap
	if randf() < drop_chance_scrap:
		var scrap_amount: int = randi_range(scrap_min, scrap_max)
		# Larger asteroids drop more scrap
		match size:
			"large":
				scrap_amount = int(scrap_amount * 1.5)
			"medium":
				scrap_amount = int(scrap_amount * 1.0)
			"small":
				scrap_amount = int(scrap_amount * 0.6)

		loot_rolls.append({"type": LootType.SCRAP, "amount": scrap_amount})

	# Roll for ammo
	if randf() < drop_chance_ammo:
		var ammo_type: LootType = LootType.AMMO_KIN if randf() < 0.5 else LootType.AMMO_EXP
		loot_rolls.append({"type": ammo_type, "amount": ammo_amount})

	# Roll for hull repair
	if randf() < drop_chance_hull:
		loot_rolls.append({"type": LootType.HULL_REPAIR, "amount": int(hull_repair_amount)})

	# Spawn loot pickups
	for loot_data in loot_rolls:
		_spawn_loot_pickup(position, loot_data.type, loot_data.amount)


func _spawn_loot_pickup(position: Vector2, type: LootType, amount: int) -> void:
	"""Spawn a single loot pickup"""
	var pickup: LootPickup = LootPickup.new()
	get_tree().root.add_child(pickup)

	# Randomize position slightly
	var offset: Vector2 = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	pickup.global_position = position + offset

	# Initialize pickup
	pickup.initialize(type, amount, pickup_radius, magnet_radius)
	pickup.collected.connect(_on_loot_collected)


func _on_loot_collected(type: LootType, amount: int) -> void:
	"""Handle loot collection"""
	print("[LootSystem] Collected: ", LootType.keys()[type], " x", amount)

	# Apply loot effects
	match type:
		LootType.SCRAP:
			GameManager.add_scrap(amount)
		LootType.AMMO_KIN:
			# TODO: Reload kinetic weapons
			pass
		LootType.AMMO_EXP:
			# TODO: Reload explosive weapons
			pass
		LootType.HULL_REPAIR:
			# TODO: Heal player ship
			pass

	loot_picked_up.emit(LootType.keys()[type], amount)


func enable_magnet(enabled: bool) -> void:
	"""Enable/disable magnet upgrade"""
	magnet_enabled = enabled

	# Update all active pickups
	for pickup in get_tree().get_nodes_in_group("loot_pickups"):
		if pickup is LootPickup:
			pickup.magnet_active = enabled


func _create_loot_scene() -> void:
	"""Create basic loot pickup scene"""
	# Placeholder - can be replaced with proper scene later
	pass


## LootPickup - Individual loot item that can be collected
class LootPickup extends Area2D:
	signal collected(type: LootType, amount: int)

	var loot_type: LootType = LootType.SCRAP
	var loot_amount: int = 10
	var pickup_radius: float = 40.0
	var magnet_radius: float = 150.0
	var magnet_active: bool = false

	var player_ship: Ship = null
	var is_collected: bool = false

	# Visual
	var visual: ColorRect = null
	var label: Label = null

	# Movement
	var velocity: Vector2 = Vector2.ZERO
	var magnet_speed: float = 300.0


	func initialize(type: LootType, amount: int, pickup_rad: float, magnet_rad: float) -> void:
		"""Initialize loot pickup"""
		loot_type = type
		loot_amount = amount
		pickup_radius = pickup_rad
		magnet_radius = magnet_rad

		add_to_group("loot_pickups")

		# Setup collision
		collision_layer = 0
		collision_mask = 1  # Player layer
		monitoring = true

		# Setup visual
		_setup_visual()

		# Connect signals
		body_entered.connect(_on_body_entered)

		# Setup collision shape
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = pickup_radius
		collision_shape.shape = circle
		add_child(collision_shape)


	func _setup_visual() -> void:
		"""Create visual representation"""
		visual = ColorRect.new()
		visual.size = Vector2(16, 16)
		visual.position = -visual.size / 2

		# Color based on type
		match loot_type:
			LootType.SCRAP:
				visual.color = Color(0.8, 0.8, 0.2)  # Yellow/gold
			LootType.AMMO_KIN:
				visual.color = Color(1.0, 0.5, 0.0)  # Orange
			LootType.AMMO_EXP:
				visual.color = Color(1.0, 0.2, 0.0)  # Red
			LootType.HULL_REPAIR:
				visual.color = Color(0.0, 1.0, 0.3)  # Green
			LootType.UPGRADE:
				visual.color = Color(0.5, 0.0, 1.0)  # Purple

		add_child(visual)

		# Amount label
		label = Label.new()
		label.text = str(loot_amount)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-10, -25)
		label.add_theme_font_size_override("font_size", 10)
		add_child(label)


	func _physics_process(delta: float) -> void:
		if is_collected:
			return

		# Find player ship
		if not player_ship or not is_instance_valid(player_ship):
			_find_player_ship()

		if not player_ship:
			return

		var distance_to_player: float = global_position.distance_to(player_ship.global_position)

		# Magnet pull
		if magnet_active and distance_to_player < magnet_radius:
			var direction: Vector2 = (player_ship.global_position - global_position).normalized()
			velocity = direction * magnet_speed
			global_position += velocity * delta

		# Auto-collect if very close
		if distance_to_player < pickup_radius:
			_collect()


	func _find_player_ship() -> void:
		"""Find player ship in scene"""
		var ships: Array = get_tree().get_nodes_in_group("player")
		if ships.size() > 0:
			player_ship = ships[0] as Ship


	func _on_body_entered(body: Node2D) -> void:
		"""Collect when player touches"""
		if body is Ship and not is_collected:
			_collect()


	func _collect() -> void:
		"""Collect this loot"""
		if is_collected:
			return

		is_collected = true
		collected.emit(loot_type, loot_amount)

		# Visual effect
		_play_collect_effect()

		# Remove pickup
		queue_free()


	func _play_collect_effect() -> void:
		"""Visual effect for collection"""
		# Simple flash effect
		if visual:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(visual, "scale", Vector2(2.0, 2.0), 0.2)
			tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.2)
