extends CharacterBody3D
class_name ExpDrop

@export var EXP_AMOUNT: int = 1
@export var POP_FORCE: float = 8.0
@export var POP_Y: float = 0.5
@export var DRAG_FACTOR: float = 3.0
@export var HOMING_ACCEL: float = 25.0

var target_node: Node3D
var is_collected: bool = false

func _physics_process(delta: float) -> void:
	if not is_collected or target_node == null:
		return
		
	# Apply drag to slowly kill the initial "pop away" momentum
	velocity = velocity.lerp(Vector3.ZERO, DRAG_FACTOR * delta)
		
	# Smoothly curve velocity toward the player
	var direction_to_target = (target_node.global_position - global_position).normalized()
	velocity += direction_to_target * HOMING_ACCEL * delta
	
	move_and_slide()

# Triggers the "pop away then fly back" animation
func initialize(target: Node3D) -> void:
	if is_collected:
		return
		
	is_collected = true
	target_node = target
	
	# Initial burst backwards and slightly upwards
	var away_dir = (global_position - target.global_position).normalized()
	away_dir.y = POP_Y
	velocity = away_dir.normalized() * POP_FORCE
