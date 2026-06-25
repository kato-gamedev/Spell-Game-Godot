extends RefCounted
class_name CasterContext 

# Player references and aiming data
var caster_node: Node3D # Change to CharacterBody3D/2D depending on your game
var parent_staff: MagicStaff
var aim_location: Vector3
var wand_tip_position: Vector3

# Initialize the struct with required data
func _init(in_parent_staff: MagicStaff, caster: Node3D, aim: Vector3, tip: Vector3) -> void:
	parent_staff = in_parent_staff
	caster_node = caster
	aim_location = aim
	wand_tip_position = tip
