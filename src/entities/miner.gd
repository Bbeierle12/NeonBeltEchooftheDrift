extends Ship
class_name Miner
## Miner (Prospect S) - Utility and economy ship
##
## Signature: Deploy Drone - Spawn collector, defuser, or gun drones
## Passive: Salvage Expert - +30% scrap, increased magnet range
## Playstyle: Economy focus, tactical drone use

# Drone system
enum DroneType { COLLECTOR, DEFUSER, GUN }
var current_drone_type: DroneType = DroneType.COLLECTOR
var active_drones: Array[Node2D] = []
var max_drones: int = 3
var drone_cooldown: float = 2.0
var drone_cooldown_timer: float = 0.0
var drone_duration: float = 30.0

# Stats
var miner_max_hull: float = 100.0
var miner_max_shields: float = 90.0
var miner_max_speed: float = 210.0
var miner_acceleration: float = 650.0
var miner_turn_rate: float = 300.0
var miner_max_heat: float = 100.0
var miner_heat_dissipation: float = 12.0

# Passive bonuses
var scrap_bonus: float = 0.3  # +30%
var magnet_range_bonus: float = 50.0


func _ready() -> void:
	# Override base stats
	max_hull = miner_max_hull
	current_hull = miner_max_hull
	max_shields = miner_max_shields
	current_shields = miner_max_shields
	max_speed = miner_max_speed
	acceleration = miner_acceleration
	turn_rate = miner_turn_rate
	max_heat = miner_max_heat
	heat_dissipation_rate = miner_heat_dissipation

	super._ready()

	# Apply scrap bonus to GameManager (would need integration)
	print("[Miner] Prospect S initialized - Economy specialist (+30% scrap)")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Update drone cooldown
	if drone_cooldown_timer > 0:
		drone_cooldown_timer -= delta

	# Clean up destroyed drones
	_cleanup_drones()


func _process_input(delta: float) -> void:
	super._process_input(delta)

	# Cycle drone type (R key - would need input mapping)
	# For now, using overdrive key as placeholder
	if Input.is_action_just_pressed("overdrive"):
		_deploy_drone()


func _deploy_drone() -> void:
	"""Deploy a drone of current type"""
	if drone_cooldown_timer > 0:
		print("[Miner] Drone on cooldown: ", drone_cooldown_timer, "s")
		return

	if active_drones.size() >= max_drones:
		print("[Miner] Max drones deployed")
		return

	# Create drone based on type
	var drone: Node2D = null
	match current_drone_type:
		DroneType.COLLECTOR:
			drone = _create_collector_drone()
		DroneType.DEFUSER:
			drone = _create_defuser_drone()
		DroneType.GUN:
			drone = _create_gun_drone()

	if drone:
		get_tree().root.add_child(drone)
		drone.global_position = global_position
		active_drones.append(drone)

		drone_cooldown_timer = drone_cooldown
		print("[Miner] Deployed ", DroneType.keys()[current_drone_type], " drone")


func _create_collector_drone() -> Node2D:
	"""Create collector drone (auto-collects loot)"""
	var drone: Area2D = Area2D.new()

	# Visual
	var visual: ColorRect = ColorRect.new()
	visual.color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow
	visual.size = Vector2(16, 16)
	visual.position = -visual.size / 2
	drone.add_child(visual)

	# Collision for loot collection
	drone.collision_layer = 0
	drone.collision_mask = 0  # Would detect loot layer

	# TODO: Add actual collector logic
	# For now, it's a visual placeholder
	return drone


func _create_defuser_drone() -> Node2D:
	"""Create defuser drone (auto-defuses volatiles)"""
	var drone: Area2D = Area2D.new()

	# Visual
	var visual: ColorRect = ColorRect.new()
	visual.color = Color(0.0, 1.0, 1.0, 0.8)  # Cyan
	visual.size = Vector2(16, 16)
	visual.position = -visual.size / 2
	drone.add_child(visual)

	# TODO: Add volatile detection and defuse logic
	return drone


func _create_gun_drone() -> Node2D:
	"""Create gun drone (attacks nearby enemies)"""
	var drone: Area2D = Area2D.new()

	# Visual
	var visual: ColorRect = ColorRect.new()
	visual.color = Color(1.0, 0.0, 0.0, 0.8)  # Red
	visual.size = Vector2(16, 16)
	visual.position = -visual.size / 2
	drone.add_child(visual)

	# TODO: Add enemy detection and firing logic
	return drone


func _cleanup_drones() -> void:
	"""Remove destroyed drones from tracking"""
	var valid_drones: Array[Node2D] = []
	for drone in active_drones:
		if is_instance_valid(drone):
			valid_drones.append(drone)

	active_drones = valid_drones


func cycle_drone_type() -> void:
	"""Cycle to next drone type"""
	current_drone_type = (current_drone_type + 1) % 3
	print("[Miner] Drone type: ", DroneType.keys()[current_drone_type])


# Override to prevent standard Overdrive
func _activate_overdrive() -> void:
	# Miner uses drone deployment instead
	_deploy_drone()
