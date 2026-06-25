@tool
extends BTAction

@export var range_min: float = 3.0
@export var range_max: float = 5.0

@export var position_var: StringName = &"posistion"

var target_position: Vector3
# Called to generate a display name for the task (requires @tool).
func _generate_name() -> String:
	return "Move to random point"

# Called to initialize the task.
func _setup() -> void:
	#print("setup")
	pass

# Called when the task is entered.
func _enter() -> void:
	#print("enter")
	var enemy: Enemy = agent as Enemy
	var random_direction = Vector3(
		randf_range(-1, 1), 
		enemy.global_position.y, 
		randf_range(-1, 1)
		).normalized()
	target_position = enemy.global_position + random_direction * randf_range(range_min, range_max)
	enemy.set_navigation_target(target_position)
	Debug.draw_cylinder(target_position, target_position+Vector3(0, 0.2, 0), 0.1, Color.PURPLE, 3)

# Called when the task is exited.
func _exit() -> void:
	pass

func _tick(delta: float) -> Status:
	var enemy: Enemy = agent as Enemy
	if (enemy.global_position - target_position).length() <= 0.5:
		#print("sucess")
		return Status.SUCCESS
	blackboard.set_var(position_var, target_position)
	#print("running")
	return Status.RUNNING
