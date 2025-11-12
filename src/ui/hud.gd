extends CanvasLayer
## HUD - Heads-Up Display showing player stats
##
## Displays:
## - Hull and shields
## - Heat meter
## - Score
## - Ammo (for ammo-based weapons)
## - Combo multiplier (Phase 4)

# UI Elements
@onready var hull_bar: ProgressBar = $MarginContainer/VBoxContainer/Stats/HullBar
@onready var shields_bar: ProgressBar = $MarginContainer/VBoxContainer/Stats/ShieldsBar
@onready var heat_bar: ProgressBar = $MarginContainer/VBoxContainer/Stats/HeatBar
@onready var score_label: Label = $MarginContainer/VBoxContainer/Score/ScoreLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/Stats/AmmoLabel

# Reference to player ship
var player_ship: Ship = null


func _ready() -> void:
	# Find player ship
	await get_tree().create_timer(0.1).timeout  # Wait for scene to load
	player_ship = get_tree().get_first_node_in_group("player")

	if player_ship:
		# Connect signals
		player_ship.hull_changed.connect(_on_hull_changed)
		player_ship.shields_changed.connect(_on_shields_changed)
		player_ship.heat_changed.connect(_on_heat_changed)

		# Initialize values
		_on_hull_changed(player_ship.current_hull, player_ship.max_hull)
		_on_shields_changed(player_ship.current_shields, player_ship.max_shields)
		_on_heat_changed(player_ship.current_heat, player_ship.max_heat)
	else:
		push_warning("[HUD] Player ship not found")


func _process(_delta: float) -> void:
	# Update score
	score_label.text = "Score: %d" % GameManager.current_run.get("score", 0)

	# Update ammo if player has active weapon
	if player_ship and player_ship.active_weapon:
		var weapon: Weapon = player_ship.active_weapon
		if weapon.uses_ammo:
			ammo_label.text = "Ammo: %d / %d" % [weapon.current_ammo, weapon.max_ammo]
			ammo_label.visible = true
		else:
			ammo_label.visible = false


func _on_hull_changed(current: float, maximum: float) -> void:
	"""Update hull bar"""
	hull_bar.max_value = maximum
	hull_bar.value = current

	# Color based on percentage
	var percentage: float = current / maximum
	if percentage > 0.5:
		hull_bar.modulate = Color(0.4, 1.0, 0.4)  # Green
	elif percentage > 0.25:
		hull_bar.modulate = Color(1.0, 0.8, 0.2)  # Yellow
	else:
		hull_bar.modulate = Color(1.0, 0.3, 0.3)  # Red


func _on_shields_changed(current: float, maximum: float) -> void:
	"""Update shields bar"""
	shields_bar.max_value = maximum
	shields_bar.value = current

	# Blue for shields
	shields_bar.modulate = Color(0.4, 0.7, 1.0)


func _on_heat_changed(current: float, maximum: float) -> void:
	"""Update heat bar"""
	heat_bar.max_value = maximum
	heat_bar.value = current

	# Color based on percentage
	var percentage: float = current / maximum
	if percentage > 0.75:
		heat_bar.modulate = Color(1.0, 0.3, 0.3)  # Red (overheating)
	elif percentage > 0.5:
		heat_bar.modulate = Color(1.0, 0.6, 0.2)  # Orange
	else:
		heat_bar.modulate = Color(0.4, 1.0, 0.4)  # Green
