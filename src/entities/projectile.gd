extends Area2D
class_name Projectile
## Projectile - Base class for all projectiles (bullets, beams, missiles, etc.)
##
## Handles:
## - Movement
## - Damage application
## - Lifetime
## - Screen wrapping
## - Hit detection

signal hit_target(target: Node2D, damage: float)

# Projectile properties
var damage: float = 10.0
var damage_type: String = "kinetic"  # kinetic, energy, explosive
var speed: float = 500.0
var lifetime: float = 3.0
var piercing: bool = false
var pierce_count: int = 0
var max_pierces: int = 0

# Movement
var velocity: Vector2 = Vector2.ZERO
var lifetime_timer: float = 0.0

# Screen wrapping
var screen_size: Vector2
var margin: float = 50.0

# Owner tracking (for telemetry)
var shooter: Node = null


func _ready() -> void:
	screen_size = get_viewport_rect().size
	add_to_group("projectiles")

	# Set collision layers
	collision_layer = 4  # projectiles_player layer
	collision_mask = 2 | 16  # asteroids + enemies

	# Connect hit signal
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func initialize(init_damage: float, init_type: String, init_velocity: Vector2, init_lifetime: float = 3.0) -> void:
	"""Initialize projectile"""
	damage = init_damage
	damage_type = init_type
	velocity = init_velocity
	speed = velocity.length()
	lifetime = init_lifetime
	lifetime_timer = lifetime


func _physics_process(delta: float) -> void:
	# Move projectile
	position += velocity * delta

	# Update lifetime
	lifetime_timer -= delta
	if lifetime_timer <= 0:
		queue_free()
		return

	# Screen wrapping
	_process_screen_wrap()


func _process_screen_wrap() -> void:
	"""Wrap projectile at screen edges or destroy if too far"""
	# For projectiles, we'll destroy them if they go too far offscreen
	if position.x < -margin or position.x > screen_size.x + margin:
		queue_free()
	elif position.y < -margin or position.y > screen_size.y + margin:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with area (other projectiles, etc.)"""
	# Ignore for now
	pass


func _on_body_entered(body: Node2D) -> void:
	"""Handle collision with body (asteroids, enemies)"""
	if body.has_method("take_damage"):
		body.take_damage(damage, damage_type)
		hit_target.emit(body, damage)

		# Handle piercing
		if piercing and pierce_count < max_pierces:
			pierce_count += 1
			# Continue through
		else:
			# Destroy projectile
			queue_free()
	else:
		queue_free()


func enable_piercing(max_pierce: int) -> void:
	"""Enable piercing with a maximum pierce count"""
	piercing = true
	max_pierces = max_pierce
