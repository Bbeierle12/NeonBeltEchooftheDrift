extends Node
class_name BossRushMode
## BossRushMode - Fight all bosses in sequence
##
## Features:
## - Sequential boss fights
## - Shop between bosses
## - Time tracking
## - Leaderboard support
## - Unlock requirements

signal boss_rush_started()
signal boss_defeated(boss_id: String, time: float)
signal boss_rush_completed(total_time: float)
signal shop_opened_between_bosses()

enum RushState { NOT_STARTED, IN_PROGRESS, BETWEEN_BOSSES, COMPLETED, FAILED }

# Boss Rush state
var current_state: RushState = RushState.NOT_STARTED
var current_boss_index: int = 0
var total_time: float = 0.0
var boss_times: Array[float] = []

# Boss sequence
var boss_sequence: Array[Dictionary] = [
	{
		"id": "quarrymind",
		"name": "Quarrymind",
		"scene_path": "res://src/entities/quarrymind_boss.gd"
	},
	{
		"id": "ion_wyrm",
		"name": "Ion Wyrm",
		"scene_path": "res://src/entities/ion_wyrm_boss.gd"
	},
	{
		"id": "archivist",
		"name": "Archivist",
		"scene_path": "res://src/entities/archivist_boss.gd"
	}
]

# Settings
var starting_scrap: int = 500
var shop_between_bosses: bool = true
var heal_between_bosses: bool = true
var heal_percentage: float = 0.5  # 50% hull/shield restore

# Unlock requirements
var unlock_requirement_met: bool = false


func _ready() -> void:
	_check_unlock_requirements()


func _check_unlock_requirements() -> void:
	"""Check if Boss Rush is unlocked"""
	# Require all bosses defeated at least once
	# This would check meta-progression or achievement system
	unlock_requirement_met = true  # Placeholder


func is_unlocked() -> bool:
	"""Check if Boss Rush mode is available"""
	return unlock_requirement_met


func start_boss_rush() -> void:
	"""Start Boss Rush mode"""
	if not unlock_requirement_met:
		push_error("[BossRush] Mode not unlocked yet")
		return

	if current_state == RushState.IN_PROGRESS:
		return

	# Initialize
	current_state = RushState.IN_PROGRESS
	current_boss_index = 0
	total_time = 0.0
	boss_times.clear()

	# Give starting resources
	GameManager.start_new_run("interceptor", "boss_rush")
	GameManager.add_scrap(starting_scrap)

	boss_rush_started.emit()
	print("[BossRush] Started! Fight ", boss_sequence.size(), " bosses")

	# Start first boss
	_spawn_boss(current_boss_index)


func _process(delta: float) -> void:
	if current_state == RushState.IN_PROGRESS:
		total_time += delta


func _spawn_boss(index: int) -> void:
	"""Spawn boss at index"""
	if index >= boss_sequence.size():
		_complete_boss_rush()
		return

	var boss_info: Dictionary = boss_sequence[index]
	print("[BossRush] Spawning boss: ", boss_info.name)

	# TODO: Actually spawn boss entity
	# For now, this is a placeholder

	current_state = RushState.IN_PROGRESS


func on_boss_defeated() -> void:
	"""Called when current boss is defeated"""
	var boss_info: Dictionary = boss_sequence[current_boss_index]
	var boss_time: float = total_time - boss_times.reduce(func(sum, t): return sum + t, 0.0)
	boss_times.append(boss_time)

	boss_defeated.emit(boss_info.id, boss_time)
	print("[BossRush] ", boss_info.name, " defeated in ", boss_time, "s")

	# Move to next boss
	current_boss_index += 1

	if current_boss_index >= boss_sequence.size():
		_complete_boss_rush()
		return

	# Between bosses
	_between_bosses()


func _between_bosses() -> void:
	"""Handle intermission between bosses"""
	current_state = RushState.BETWEEN_BOSSES

	# Heal player
	if heal_between_bosses:
		_heal_player()

	# Open shop
	if shop_between_bosses:
		_open_shop()
	else:
		# Auto-continue to next boss
		_continue_to_next_boss()


func _heal_player() -> void:
	"""Heal player between bosses"""
	var player_ship: Ship = _find_player()
	if not player_ship:
		return

	var hull_heal: float = player_ship.max_hull * heal_percentage
	var shield_heal: float = player_ship.max_shields * heal_percentage

	player_ship.heal(hull_heal)
	player_ship.restore_shields(shield_heal)

	print("[BossRush] Healed: +", hull_heal, " hull, +", shield_heal, " shields")


func _open_shop() -> void:
	"""Open shop between bosses"""
	if has_node("/root/ShopSystem"):
		var shop_system: ShopSystem = get_node("/root/ShopSystem")
		shop_system.open_shop()

		shop_opened_between_bosses.emit()
		print("[BossRush] Shop opened")


func _continue_to_next_boss() -> void:
	"""Continue to next boss"""
	if current_boss_index >= boss_sequence.size():
		_complete_boss_rush()
		return

	current_state = RushState.IN_PROGRESS
	_spawn_boss(current_boss_index)


func _complete_boss_rush() -> void:
	"""Complete Boss Rush"""
	current_state = RushState.COMPLETED

	boss_rush_completed.emit(total_time)

	print("[BossRush] COMPLETED in ", total_time, "s")

	# Award rewards
	var bonus_score: int = 50000
	var bonus_scrap: int = 2000
	GameManager.add_score(bonus_score, "Boss Rush completed")
	GameManager.add_scrap(bonus_scrap)

	# Unlock achievement
	if has_node("/root/AchievementSystem"):
		var achievement_system: AchievementSystem = get_node("/root/AchievementSystem")
		achievement_system.unlock_achievement("boss_rush_complete")

	# TODO: Submit time to leaderboard


func fail_boss_rush() -> void:
	"""Fail Boss Rush (player died)"""
	current_state = RushState.FAILED
	print("[BossRush] Failed at boss ", current_boss_index + 1)


func _find_player() -> Ship:
	"""Find player ship"""
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Ship
	return null


## Getters

func get_current_boss() -> Dictionary:
	"""Get current boss info"""
	if current_boss_index < boss_sequence.size():
		return boss_sequence[current_boss_index]
	return {}


func get_total_time() -> float:
	"""Get total elapsed time"""
	return total_time


func get_boss_times() -> Array[float]:
	"""Get individual boss times"""
	return boss_times


func get_progress() -> float:
	"""Get completion progress (0-1)"""
	return float(current_boss_index) / float(boss_sequence.size())


func is_active() -> bool:
	"""Check if Boss Rush is active"""
	return current_state in [RushState.IN_PROGRESS, RushState.BETWEEN_BOSSES]
