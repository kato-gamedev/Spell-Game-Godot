extends Node3D
class_name PlayerStat

signal leveled_up(new_level: int)

@export var BASE_MAX_EXP: int = 10
@export var EXP_MULTIPLIER: float = 1.5
@onready var absorb_collision_shape: CollisionShape3D = $ExpAbsorbArea/AbsorbCollisionShape

@onready var stat_label: Label = $StatLabel
@onready var progress_bar: ProgressBar = $ProgressBar

var current_exp: float = 0
var max_exp: float = 10
var level: int = 1

func _ready() -> void:
	max_exp = BASE_MAX_EXP
	refresh_ui()

# Adds experience and handles multiple level-ups at once
func add_exp(amount: int) -> void:
	current_exp += amount
	while current_exp >= max_exp:
		level_up()
	refresh_ui()

# Process stat changes and notify other systems
func level_up() -> void:
	level += 1
	current_exp -= max_exp
	max_exp = int(max_exp * EXP_MULTIPLIER)
	leveled_up.emit(level)
	refresh_ui()

func refresh_ui():
	stat_label.text = "Level: %d | EXP: %d/%d" % [level, current_exp, max_exp]
	progress_bar.value = current_exp/max_exp * 100

# Big area: Detects orbs in magnet radius and starts the pull animation
func _on_magnet_area_body_entered(body: Node3D) -> void:
	if body is ExpDrop:
		body.initialize(absorb_collision_shape)

# Small area: Absorbs the orb when it touches the player
func _on_exp_absorb_area_body_entered(body: Node3D) -> void:
	if body is ExpDrop:
		add_exp(body.EXP_AMOUNT)
		body.queue_free()
