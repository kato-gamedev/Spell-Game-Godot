extends Node
class_name EnemyStat

# Stat
@export var health: float = 100.0
@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var movement_speed: float = 300.0
@export var speed_multiplier: float = 0.01
# this variable have no use yet
@export var difficulty: float = 1.0

signal health_changed(old_health: float, new_health: float, old_max_health: float, new_max_health: float)
signal died

func _ready() -> void:
	# Initialize the UI
	await get_tree().process_frame
	health_changed.emit(health, health, max_health, max_health)

func initialize(in_difficulty: float):
	difficulty = in_difficulty
	health *= in_difficulty
	max_health *= in_difficulty
	damage *= in_difficulty
	movement_speed *= (1.0 + (in_difficulty - 1.0) / 5.0)
	
func get_health() -> float:
	return health
	
func get_movement_speed() -> float:
	return movement_speed * speed_multiplier

func set_health(value:float):
	var old_health = health
	health = value
	health_changed.emit(old_health, health, max_health, max_health)
	if health <= 0:
		died.emit()
	
func get_max_health() -> float:
	return max_health

func set_max_health(value:float):
	var old_max_health = max_health
	max_health = value
	health_changed.emit(health, health, old_max_health, max_health)
