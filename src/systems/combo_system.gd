extends Node
class_name ComboSystem
## ComboSystem - Combo multiplier and style bonuses
##
## Features:
## - Kill streak combo tracking
## - Combo multiplier for score
## - Combo timeout
## - Style bonuses (ricochet, refract, chain, etc.)
## - Combo meter UI feedback

signal combo_increased(combo: int, multiplier: float)
signal combo_broken()
signal style_bonus_earned(bonus_type: String, points: int)
signal combo_milestone_reached(milestone: int)

# Combo state
var current_combo: int = 0
var combo_multiplier: float = 1.0
var combo_timeout: float = 3.0  # Seconds without kill to break combo
var combo_timer: float = 0.0

# Multiplier scaling
var base_multiplier: float = 1.0
var multiplier_per_kill: float = 0.1  # +10% per kill
var max_multiplier: float = 5.0  # Cap at 5x

# Style bonus values
var style_bonuses: Dictionary = {
	"ricochet_kill": 50,
	"refract_kill": 75,
	"chain_kill": 100,
	"defuse_kill": 80,
	"perfect_timing": 30,
	"close_range": 40,
	"no_damage": 200,
	"multi_kill": 150
}

# Milestones
var milestones: Array[int] = [10, 25, 50, 100, 250, 500]
var reached_milestones: Array[int] = []


func _ready() -> void:
	# Connect to game events
	if has_node("/root/GameManager"):
		pass  # Can connect to kill events


func _process(delta: float) -> void:
	# Combo timeout
	if current_combo > 0:
		combo_timer += delta
		if combo_timer >= combo_timeout:
			break_combo()


func add_kill() -> void:
	"""Add a kill to combo"""
	current_combo += 1
	combo_timer = 0.0

	# Calculate multiplier
	_update_multiplier()

	# Check milestones
	_check_milestones()

	combo_increased.emit(current_combo, combo_multiplier)

	print("[Combo] ", current_combo, "x (", combo_multiplier, "x multiplier)")


func break_combo() -> void:
	"""Break the combo"""
	if current_combo == 0:
		return

	print("[Combo] Broken at ", current_combo, "x")

	current_combo = 0
	combo_multiplier = base_multiplier
	combo_timer = 0.0
	reached_milestones.clear()

	combo_broken.emit()


func _update_multiplier() -> void:
	"""Update score multiplier based on combo"""
	combo_multiplier = base_multiplier + (current_combo * multiplier_per_kill)
	combo_multiplier = min(combo_multiplier, max_multiplier)


func _check_milestones() -> void:
	"""Check if combo reached milestone"""
	for milestone in milestones:
		if current_combo == milestone and milestone not in reached_milestones:
			reached_milestones.append(milestone)
			combo_milestone_reached.emit(milestone)

			# Bonus score for milestone
			var milestone_bonus: int = milestone * 10
			GameManager.add_score(milestone_bonus, "Combo milestone: " + str(milestone) + "x")

			print("[Combo] Milestone reached: ", milestone, "x (+", milestone_bonus, " bonus)")


## Style Bonuses

func award_style_bonus(bonus_type: String) -> void:
	"""Award style bonus points"""
	if not style_bonuses.has(bonus_type):
		return

	var bonus_points: int = style_bonuses[bonus_type]

	# Apply combo multiplier
	bonus_points = int(bonus_points * combo_multiplier)

	# Award score
	GameManager.add_score(bonus_points, "Style: " + bonus_type)

	style_bonus_earned.emit(bonus_type, bonus_points)

	print("[Style] ", bonus_type, ": +", bonus_points)


func ricochet_kill() -> void:
	"""Award ricochet kill bonus"""
	award_style_bonus("ricochet_kill")


func refract_kill() -> void:
	"""Award beam refraction kill bonus"""
	award_style_bonus("refract_kill")


func chain_kill() -> void:
	"""Award chain lightning kill bonus"""
	award_style_bonus("chain_kill")


func defuse_kill() -> void:
	"""Award volatile defuse bonus"""
	award_style_bonus("defuse_kill")


func perfect_timing() -> void:
	"""Award perfect timing bonus (Pulse Laser)"""
	award_style_bonus("perfect_timing")


func close_range() -> void:
	"""Award close range kill bonus"""
	award_style_bonus("close_range")


func multi_kill(count: int) -> void:
	"""Award multi-kill bonus"""
	if count >= 3:
		award_style_bonus("multi_kill")


func no_damage_bonus() -> void:
	"""Award no damage taken bonus"""
	award_style_bonus("no_damage")


## Getters

func get_combo() -> int:
	"""Get current combo count"""
	return current_combo


func get_multiplier() -> float:
	"""Get current score multiplier"""
	return combo_multiplier


func get_combo_time_remaining() -> float:
	"""Get time remaining before combo breaks"""
	return max(0.0, combo_timeout - combo_timer)


func get_combo_percentage() -> float:
	"""Get combo timer as percentage (0-1)"""
	return 1.0 - (combo_timer / combo_timeout)


## Configuration

func set_combo_timeout(timeout: float) -> void:
	"""Set combo timeout duration"""
	combo_timeout = timeout


func set_max_multiplier(max_mult: float) -> void:
	"""Set maximum multiplier cap"""
	max_multiplier = max_mult


func reset() -> void:
	"""Reset combo system"""
	break_combo()
