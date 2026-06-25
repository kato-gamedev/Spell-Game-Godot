extends CharacterBody3D
class_name Character

## The tcsn children of this class must have components with exactly matched name
@onready var ASC: AbilitySystemComponent = $AbilitySystemComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

# GAS
const SPEED_MULTIPLIER: float = 0.01

# Rotation
@export var ROTATION_RATE: float = 6 # From 0 - 10
var is_turning_in_place: bool = false
var target_vector: Vector3 # Rotation

# GAS
var _casting := false
var disable_movement := false
func set_casting(state: bool):
	_casting = state
	disable_movement = state

func _physics_process(delta: float) -> void:
	pass

func play_one_shot_animation(speed_scale: float, animation_name: StringName, start_time: float, end_time: float):
	animation_tree["parameters/TimeScale/scale"] = speed_scale
	var root = animation_tree.tree_root
	var anim_node: AnimationNodeAnimation = root.get_node("OneShot_Animation")
	anim_node.animation = animation_name
	anim_node.use_custom_timeline = true
	anim_node.start_offset = start_time
	anim_node.timeline_length = end_time - start_time
	animation_tree["parameters/OneShot_Attack/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	pass
