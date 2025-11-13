extends Node
class_name DailySeedSystem
## DailySeedSystem - Daily challenge with fixed seed
##
## Features:
## - Generate daily seed based on date
## - Track daily runs and best scores
## - Leaderboard integration
## - One attempt per day (optional)

signal daily_seed_generated(seed_value: int, date: String)
signal daily_run_completed(score: int, rank: int)

# Daily seed
var current_daily_seed: int = 0
var current_date: String = ""
var seed_base: int = 12345  # Base seed for generation

# Daily run tracking
var daily_runs: Dictionary = {}  # date -> {seed, attempts, best_score, completed}
var max_daily_attempts: int = 0  # 0 = unlimited, 1 = one attempt

# Save path
var save_path: String = "user://daily_seeds.save"


func _ready() -> void:
	load_daily_data()
	generate_daily_seed()


func generate_daily_seed() -> void:
	"""Generate seed for current date"""
	var date_dict: Dictionary = Time.get_date_dict_from_system()
	current_date = "%04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]

	# Generate deterministic seed from date
	var year: int = date_dict.year
	var month: int = date_dict.month
	var day: int = date_dict.day

	# Combine date components into seed
	current_daily_seed = seed_base + (year * 10000) + (month * 100) + day

	print("[Daily] Seed for ", current_date, ": ", current_daily_seed)

	daily_seed_generated.emit(current_daily_seed, current_date)

	# Initialize daily run data if not exists
	if not daily_runs.has(current_date):
		daily_runs[current_date] = {
			"seed": current_daily_seed,
			"attempts": 0,
			"best_score": 0,
			"completed": false,
			"best_wave": 0
		}


func start_daily_run() -> bool:
	"""Start a daily seed run"""
	# Check if already completed today
	var today_data: Dictionary = daily_runs.get(current_date, {})

	if max_daily_attempts > 0:
		if today_data.get("attempts", 0) >= max_daily_attempts:
			print("[Daily] Maximum attempts reached for today")
			return false

	# Increment attempts
	today_data["attempts"] = today_data.get("attempts", 0) + 1
	daily_runs[current_date] = today_data

	# Start run with daily seed
	GameManager.start_new_run("interceptor", "normal", current_daily_seed)
	GameManager.current_run["daily_seed"] = true
	GameManager.current_run["daily_date"] = current_date

	print("[Daily] Starting daily run (Attempt ", today_data["attempts"], ")")

	save_daily_data()
	return true


func complete_daily_run(score: int, waves_completed: int) -> void:
	"""Complete daily run and update records"""
	var today_data: Dictionary = daily_runs.get(current_date, {})

	# Update best score
	if score > today_data.get("best_score", 0):
		today_data["best_score"] = score
		print("[Daily] New personal best: ", score)

	# Update best wave
	if waves_completed > today_data.get("best_wave", 0):
		today_data["best_wave"] = waves_completed

	# Mark as completed if full run
	if waves_completed >= 10:
		today_data["completed"] = true

	daily_runs[current_date] = today_data

	# Save data
	save_daily_data()

	# TODO: Submit to leaderboard
	var rank: int = _get_leaderboard_rank(score)
	daily_run_completed.emit(score, rank)


func get_daily_seed() -> int:
	"""Get current daily seed"""
	return current_daily_seed


func get_today_data() -> Dictionary:
	"""Get today's run data"""
	return daily_runs.get(current_date, {})


func can_start_daily_run() -> bool:
	"""Check if player can start daily run"""
	if max_daily_attempts == 0:
		return true

	var today_data: Dictionary = get_today_data()
	return today_data.get("attempts", 0) < max_daily_attempts


func get_attempts_remaining() -> int:
	"""Get remaining attempts for today"""
	if max_daily_attempts == 0:
		return -1  # Unlimited

	var today_data: Dictionary = get_today_data()
	return max_daily_attempts - today_data.get("attempts", 0)


func get_daily_leaderboard() -> Array:
	"""Get daily leaderboard (mock data for now)"""
	# TODO: Implement actual leaderboard integration
	return [
		{"rank": 1, "player": "Player1", "score": 50000, "waves": 10},
		{"rank": 2, "player": "Player2", "score": 45000, "waves": 10},
		{"rank": 3, "player": "Player3", "score": 40000, "waves": 9},
	]


func _get_leaderboard_rank(score: int) -> int:
	"""Calculate player rank on leaderboard"""
	var leaderboard: Array = get_daily_leaderboard()
	var rank: int = leaderboard.size() + 1

	for i in range(leaderboard.size()):
		if score > leaderboard[i].score:
			rank = i + 1
			break

	return rank


func save_daily_data() -> void:
	"""Save daily run data"""
	var save_data: Dictionary = {
		"daily_runs": daily_runs,
		"version": 1
	}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("[Daily] Data saved")
	else:
		push_error("[Daily] Failed to save data")


func load_daily_data() -> void:
	"""Load daily run data"""
	if not FileAccess.file_exists(save_path):
		print("[Daily] No save file found")
		return

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data: Dictionary = file.get_var()
		file.close()

		daily_runs = save_data.get("daily_runs", {})
		print("[Daily] Data loaded: ", daily_runs.size(), " dates tracked")
	else:
		push_error("[Daily] Failed to load data")


func get_seed_for_date(date: String) -> int:
	"""Get seed for a specific date"""
	if daily_runs.has(date):
		return daily_runs[date].get("seed", 0)
	return 0


func get_history() -> Dictionary:
	"""Get all daily run history"""
	return daily_runs


func verify_seed(seed: int) -> bool:
	"""Verify that a seed matches today's daily seed"""
	return seed == current_daily_seed
