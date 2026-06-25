@tool
extends BTAction

@export var stopping_distance: float = 1.5
@export var player_var: StringName = &"player"

# Called to generate a display name for the task (requires @tool).
func _generate_name() -> String:
	return "Move to Player"

# Called to initialize the task.
func _setup() -> void:
	pass

# Called when the task is entered.
func _enter() -> void:
	pass

# Called when the task is exited.
func _exit() -> void:
	pass

func _tick(_delta: float) -> Status:
	var enemy: Enemy = agent as Enemy
	var player: Node3D = enemy.player
	
	if not is_instance_valid(player):
		print("afaio")
		return Status.FAILURE
		
	var target_position: Vector3 = player.global_position
	
	# Check if we are close enough to the player to succeed
	if (enemy.global_position - target_position).length() <= stopping_distance:
		return Status.SUCCESS
		
	# Update the navigation target constantly since the player is moving
	enemy.set_navigation_target(target_position)
	
	# Optional: Keep your debug cylinder for visualization
	#Debug.draw_cylinder(target_position, target_position + Vector3(0, 0.2, 0), 0.1, Color.RED, 3)

	return Status.RUNNING
