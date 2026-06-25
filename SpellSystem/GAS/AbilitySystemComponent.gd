extends Node
class_name AbilitySystemComponent

# Must have
@export var character: Node3D
@export var animation_tree: AnimationTree

@export var _health: float = 100
@export var _max_health: float = 100
@export var MANA: float = 50
@export var MAX_MANA: float = 50
@export var MOVEMENT_SPEED: float = 300.0
@export var DAMAGE: float = 10.0

signal health_changed(old_health: float, new_health: float, old_max_health: float, new_max_health: float)
signal died

func _ready() -> void:
	# Initialize the UI
	await get_tree().process_frame
	health_changed.emit(_health, _health, _max_health, _max_health)

func get_health() -> float:
	return _health

func set_health(value:float):
	var old_health = _health
	_health = value
	health_changed.emit(old_health, _health, _max_health, _max_health)
	if _health <= 0:
		died.emit()
	
func get_max_health() -> float:
	return _max_health

func set_max_health(value:float):
	var old_max_health = _max_health
	_max_health = value
	health_changed.emit(_health, _health, old_max_health, _max_health)
