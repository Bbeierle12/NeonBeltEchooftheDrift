extends Node
class_name TutorialSystem
## TutorialSystem - Onboarding and tutorial sequences
##
## Features:
## - Step-by-step tutorial prompts
## - Objective tracking
## - Contextual hints
## - Skip option
## - Progress saving

signal tutorial_started()
signal tutorial_step_completed(step_id: String)
signal tutorial_completed()
signal hint_shown(hint_text: String)

enum TutorialState { NOT_STARTED, IN_PROGRESS, COMPLETED, SKIPPED }

# Tutorial state
var current_state: TutorialState = TutorialState.NOT_STARTED
var current_step: int = 0
var tutorial_completed_once: bool = false

# Tutorial steps
var tutorial_steps: Array[Dictionary] = [
	{
		"id": "welcome",
		"title": "Welcome to NEON BELT",
		"text": "Twin-stick shooter meets roguelite. Salvage asteroids, collect loot, upgrade your ship.",
		"objective": "Press SPACE to continue",
		"skippable": true
	},
	{
		"id": "movement",
		"title": "Movement",
		"text": "Use WASD to thrust. Your ship drifts - momentum matters!",
		"objective": "Move around the arena",
		"trigger": "moved",
		"skippable": false
	},
	{
		"id": "aiming",
		"title": "Aiming",
		"text": "Aim with your MOUSE. Fire with LEFT CLICK.",
		"objective": "Aim and shoot",
		"trigger": "fired",
		"skippable": false
	},
	{
		"id": "asteroids",
		"title": "Asteroids",
		"text": "Destroy asteroids for scrap and loot. Larger asteroids split into smaller ones.",
		"objective": "Destroy 3 asteroids",
		"trigger": "kill_count",
		"target": 3,
		"skippable": false
	},
	{
		"id": "heat",
		"title": "Heat Management",
		"text": "Weapons generate HEAT. At 100% heat, shields disable! Let heat vent naturally.",
		"objective": "Let heat reach 80%, then vent to 20%",
		"trigger": "heat_managed",
		"skippable": true
	},
	{
		"id": "hypershift",
		"title": "Hypershift Dash",
		"text": "Press SPACE for Hypershift - invulnerable dash with 5s cooldown.",
		"objective": "Use Hypershift dash",
		"trigger": "hypershift_used",
		"skippable": false
	},
	{
		"id": "overdrive",
		"title": "Overdrive",
		"text": "Press SHIFT for Overdrive - 2x damage for 3s. Use it wisely!",
		"objective": "Activate Overdrive",
		"trigger": "overdrive_used",
		"skippable": true
	},
	{
		"id": "loot",
		"title": "Loot System",
		"text": "Destroyed asteroids drop SCRAP (currency) and ammo. Fly through to collect.",
		"objective": "Collect 5 pieces of loot",
		"trigger": "loot_collected",
		"target": 5,
		"skippable": true
	},
	{
		"id": "complete",
		"title": "Tutorial Complete!",
		"text": "You're ready for the Neon Belt. Good luck, salvager.",
		"objective": "Press SPACE to begin",
		"skippable": false
	}
]

# Trigger tracking
var tutorial_progress: Dictionary = {
	"moved": false,
	"fired": false,
	"kill_count": 0,
	"heat_managed": false,
	"hypershift_used": false,
	"overdrive_used": false,
	"loot_collected": 0
}

# Save path
var save_path: String = "user://tutorial_state.save"


func _ready() -> void:
	load_tutorial_state()


func start_tutorial() -> void:
	"""Start tutorial sequence"""
	if current_state == TutorialState.IN_PROGRESS:
		return

	current_state = TutorialState.IN_PROGRESS
	current_step = 0

	tutorial_started.emit()
	_show_current_step()

	print("[Tutorial] Started")


func skip_tutorial() -> void:
	"""Skip tutorial"""
	current_state = TutorialState.SKIPPED
	tutorial_completed_once = true
	save_tutorial_state()

	print("[Tutorial] Skipped")


func complete_current_step() -> void:
	"""Complete current tutorial step"""
	if current_state != TutorialState.IN_PROGRESS:
		return

	if current_step >= tutorial_steps.size():
		return

	var step: Dictionary = tutorial_steps[current_step]
	tutorial_step_completed.emit(step.id)

	print("[Tutorial] Step completed: ", step.id)

	# Move to next step
	current_step += 1

	if current_step >= tutorial_steps.size():
		_complete_tutorial()
	else:
		_show_current_step()


func _show_current_step() -> void:
	"""Show current tutorial step"""
	if current_step >= tutorial_steps.size():
		return

	var step: Dictionary = tutorial_steps[current_step]

	# TODO: Show tutorial UI with step info
	print("[Tutorial] ", step.title, ": ", step.text)
	print("[Tutorial] Objective: ", step.objective)


func _complete_tutorial() -> void:
	"""Complete tutorial"""
	current_state = TutorialState.COMPLETED
	tutorial_completed_once = true

	tutorial_completed.emit()

	save_tutorial_state()

	print("[Tutorial] Completed!")


## Trigger Handlers

func on_player_moved() -> void:
	"""Track player movement"""
	if not tutorial_progress.moved:
		tutorial_progress.moved = true
		_check_trigger("moved")


func on_player_fired() -> void:
	"""Track player firing"""
	if not tutorial_progress.fired:
		tutorial_progress.fired = true
		_check_trigger("fired")


func on_asteroid_destroyed() -> void:
	"""Track asteroid kills"""
	tutorial_progress.kill_count += 1
	_check_trigger("kill_count")


func on_heat_managed() -> void:
	"""Track heat management"""
	if not tutorial_progress.heat_managed:
		tutorial_progress.heat_managed = true
		_check_trigger("heat_managed")


func on_hypershift_used() -> void:
	"""Track Hypershift use"""
	if not tutorial_progress.hypershift_used:
		tutorial_progress.hypershift_used = true
		_check_trigger("hypershift_used")


func on_overdrive_used() -> void:
	"""Track Overdrive use"""
	if not tutorial_progress.overdrive_used:
		tutorial_progress.overdrive_used = true
		_check_trigger("overdrive_used")


func on_loot_collected() -> void:
	"""Track loot collection"""
	tutorial_progress.loot_collected += 1
	_check_trigger("loot_collected")


func _check_trigger(trigger_name: String) -> void:
	"""Check if current step trigger is met"""
	if current_state != TutorialState.IN_PROGRESS:
		return

	if current_step >= tutorial_steps.size():
		return

	var step: Dictionary = tutorial_steps[current_step]

	if step.get("trigger", "") == trigger_name:
		# Check if target met (for count-based triggers)
		if step.has("target"):
			var progress: int = tutorial_progress.get(trigger_name, 0)
			if progress >= step.target:
				complete_current_step()
		else:
			# Boolean triggers
			complete_current_step()


## Contextual Hints

func show_hint(hint_id: String) -> void:
	"""Show contextual hint"""
	var hints: Dictionary = {
		"low_hull": "Hull critical! Find hull repair pickups or visit the shop.",
		"shields_disabled": "Heat too high! Shields disabled. Stop firing to cool down.",
		"out_of_ammo": "Out of ammo! Collect kinetic/explosive pickups or craft more.",
		"volatile_warning": "Volatile asteroid! Shoot it fast or it will explode!",
		"armored_hint": "Armored asteroid! Use explosives or wait for the weak point.",
		"boss_incoming": "Boss approaching! Prepare for a tough fight.",
		"shop_available": "Shop available! Spend scrap on weapons and upgrades.",
		"contract_offer": "Contract available! Complete for bonus rewards."
	}

	if hints.has(hint_id):
		hint_shown.emit(hints[hint_id])
		print("[Hint] ", hints[hint_id])


## Save/Load

func save_tutorial_state() -> void:
	"""Save tutorial completion state"""
	var save_data: Dictionary = {
		"completed": tutorial_completed_once,
		"version": 1
	}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()


func load_tutorial_state() -> void:
	"""Load tutorial completion state"""
	if not FileAccess.file_exists(save_path):
		return

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var save_data: Dictionary = file.get_var()
		file.close()

		tutorial_completed_once = save_data.get("completed", false)

		if tutorial_completed_once:
			current_state = TutorialState.COMPLETED


## Getters

func is_tutorial_completed() -> bool:
	"""Check if tutorial has been completed"""
	return tutorial_completed_once


func should_show_tutorial() -> bool:
	"""Check if tutorial should be shown"""
	return not tutorial_completed_once


func get_current_step_info() -> Dictionary:
	"""Get current step information"""
	if current_step < tutorial_steps.size():
		return tutorial_steps[current_step]
	return {}
