extends Asteroid
class_name VolatileAsteroid
## VolatileAsteroid - Unstable asteroid with explosion timer
##
## Features:
## - Countdown timer to explosion (8 seconds)
## - Can be defused by dealing damage
## - Explodes if timer reaches zero (massive AoE damage)
## - Visual warning as timer decreases
## - Bonus loot if defused successfully

signal defused()
signal exploding()

enum VolatileState { STABLE, WARNING, CRITICAL, DEFUSED, EXPLODING }

# Volatile properties
var explosion_timer: float = 8.0
var max_explosion_timer: float = 8.0
var explosion_radius: float = 200.0
var explosion_damage: float = 150.0
var defuse_threshold: float = 0.5  # 50% HP damage required to defuse
var is_defused: bool = false
var current_state: VolatileState = VolatileState.STABLE

# Visual
var warning_indicator: ColorRect = null
var timer_label: Label = null


func initialize(type: String, init_size: AsteroidSize, spawn_pos: Vector2, spawn_velocity: Vector2) -> void:
	"""Initialize volatile asteroid"""
	super.initialize(type, init_size, spawn_pos, spawn_velocity)

	# Set explosion timer based on size
	match size:
		AsteroidSize.LARGE:
			explosion_timer = 8.0
			explosion_radius = 250.0
			explosion_damage = 200.0
		AsteroidSize.MEDIUM:
			explosion_timer = 6.0
			explosion_radius = 180.0
			explosion_damage = 120.0
		AsteroidSize.SMALL:
			explosion_timer = 4.0
			explosion_radius = 120.0
			explosion_damage = 60.0

	max_explosion_timer = explosion_timer

	# Create warning visual
	_setup_warning_visual()


func _setup_warning_visual() -> void:
	"""Create visual indicators for volatile state"""
	# Warning border
	warning_indicator = ColorRect.new()
	warning_indicator.color = Color(1.0, 1.0, 0.0, 0.3)  # Yellow warning
	warning_indicator.size = Vector2(radius * 2.5, radius * 2.5)
	warning_indicator.position = -warning_indicator.size / 2
	add_child(warning_indicator)

	# Timer display
	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.position = Vector2(-15, -10)
	add_child(timer_label)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_defused or current_state == VolatileState.EXPLODING:
		return

	# Count down explosion timer
	explosion_timer -= delta

	# Update state based on timer
	_update_volatile_state()

	# Update visual
	_update_warning_visual()

	# Explode if timer reaches zero
	if explosion_timer <= 0:
		_trigger_explosion()


func _update_volatile_state() -> void:
	"""Update state based on remaining time"""
	var time_percent: float = explosion_timer / max_explosion_timer

	if time_percent > 0.5:
		current_state = VolatileState.STABLE
	elif time_percent > 0.25:
		current_state = VolatileState.WARNING
	else:
		current_state = VolatileState.CRITICAL


func _update_warning_visual() -> void:
	"""Update visual indicators based on state"""
	if not warning_indicator or not timer_label:
		return

	# Update color based on state
	match current_state:
		VolatileState.STABLE:
			warning_indicator.color = Color(1.0, 1.0, 0.0, 0.3)  # Yellow
		VolatileState.WARNING:
			warning_indicator.color = Color(1.0, 0.5, 0.0, 0.5)  # Orange
		VolatileState.CRITICAL:
			# Flash red
			var flash: float = sin(explosion_timer * 10.0) * 0.3 + 0.5
			warning_indicator.color = Color(1.0, 0.0, 0.0, flash)  # Red flash

	# Update timer text
	timer_label.text = "%.1f" % explosion_timer

	# Make timer more visible when critical
	if current_state == VolatileState.CRITICAL:
		timer_label.modulate = Color(1.0, 0.0, 0.0)  # Red
	else:
		timer_label.modulate = Color(1.0, 1.0, 1.0)  # White


func take_damage(amount: float, damage_type: String = "kinetic") -> void:
	"""Take damage and check for defuse"""
	if is_defused or current_state == VolatileState.EXPLODING:
		return

	# Calculate HP lost percentage
	var hp_before: float = current_hp
	super.take_damage(amount, damage_type)
	var hp_lost_percent: float = (hp_before - current_hp) / max_hp

	# Check if enough damage dealt to defuse
	if hp_lost_percent >= defuse_threshold and not is_defused:
		_defuse()
	elif current_hp <= 0 and not is_defused:
		# Destroyed before defused = explosion
		_trigger_explosion()


func _defuse() -> void:
	"""Successfully defuse the volatile asteroid"""
	is_defused = true
	current_state = VolatileState.DEFUSED

	print("[Volatile] Defused!")

	# Visual: Turn green
	if warning_indicator:
		warning_indicator.color = Color(0.0, 1.0, 0.0, 0.5)  # Green

	if timer_label:
		timer_label.text = "SAFE"
		timer_label.modulate = Color(0.0, 1.0, 0.0)

	# Bonus score for defusing
	GameManager.add_score(score_value * 2, "Volatile defused")

	# Now behaves like normal asteroid
	defused.emit()


func _trigger_explosion() -> void:
	"""Trigger massive explosion"""
	if current_state == VolatileState.EXPLODING:
		return

	current_state = VolatileState.EXPLODING
	print("[Volatile] EXPLODING!")

	exploding.emit()

	# Deal damage in large radius
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: = PhysicsShapeQueryParameters2D.new()
	var circle: = CircleShape2D.new()
	circle.radius = explosion_radius
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1 | 2 | 16  # Player + asteroids + enemies

	var results: Array[Dictionary] = space_state.intersect_shape(query, 64)
	for result in results:
		var body: Node2D = result.collider
		if body and body != self and body.has_method("take_damage"):
			# Distance-based damage falloff
			var distance: float = body.global_position.distance_to(global_position)
			var damage_mult: float = 1.0 - (distance / explosion_radius)
			var damage: float = explosion_damage * max(damage_mult, 0.3)  # Minimum 30% damage
			body.take_damage(damage, "explosive")

	# Visual: Large explosion
	_create_explosion_vfx()

	# Chain explosions to nearby volatiles
	_trigger_chain_reaction()

	# Destroy self
	queue_free()


func _create_explosion_vfx() -> void:
	"""Create large explosion visual"""
	var explosion: ColorRect = ColorRect.new()
	explosion.color = Color(1.0, 0.3, 0.0, 0.8)
	explosion.size = Vector2(explosion_radius * 2.5, explosion_radius * 2.5)
	explosion.position = -explosion.size / 2
	get_tree().root.add_child(explosion)
	explosion.global_position = global_position

	# Expand and fade
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(explosion, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(explosion, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(explosion.queue_free)


func _trigger_chain_reaction() -> void:
	"""Trigger chain explosions to nearby volatile asteroids"""
	var nearby_asteroids: Array = get_tree().get_nodes_in_group("asteroids")
	for asteroid in nearby_asteroids:
		if asteroid is VolatileAsteroid and asteroid != self:
			var distance: float = asteroid.global_position.distance_to(global_position)
			if distance < explosion_radius * 0.7:  # 70% of explosion radius
				# Trigger chain explosion
				asteroid._trigger_explosion()


func _destroy() -> void:
	"""Override destroy to trigger explosion if not defused"""
	if not is_defused:
		_trigger_explosion()
	else:
		# Normal destruction if defused
		super._destroy()
