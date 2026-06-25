extends CharacterBody3D
class_name FlyingProjectile

@export var ROTATION_RATE: float = 3
@export var FLY_SPEED: float = 10
# For init
var damage: float = 0.0

@onready var damage_area: Area3D = $DamageArea

var team_type: Enum.TeamType
var target_character: Character = null

var targeting_type := Enum.TargetingType.NO_TARGET

func _ready() -> void:
	# Set collision mask
	if (team_type == Enum.TeamType.ALLY):
		damage_area.set_collision_mask_value(4, true)
		damage_area.set_collision_mask_value(5, false)
	if (team_type == Enum.TeamType.ENEMY):
		damage_area.set_collision_mask_value(5, true)
		damage_area.set_collision_mask_value(4, false)
	
	await get_tree().create_timer(1.75, false).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if (targeting_type == Enum.TargetingType.TARGET_UNIT and target_character):
		velocity = (target_character.global_position - global_position).normalized() * FLY_SPEED * Vector3(1, 0, 1)
	
	# Rotation
	if velocity.length() > 0:
		var target_vector = velocity.normalized()
		var forward_vector = -transform.basis.z
		var angle_to_target = forward_vector.signed_angle_to(target_vector, Vector3.UP)
		var angle = lerp_angle(0, angle_to_target, ROTATION_RATE * delta)
		rotate(Vector3.UP, angle)
	move_and_slide()

# Must set
func initialize(in_targeting_type: Enum.TargetingType, in_team_type: Enum.TeamType, target_location: Vector3, in_target_character: Character):
	team_type = in_team_type
	targeting_type = in_targeting_type
	
	if in_targeting_type == Enum.TargetingType.DIRECTION:
		velocity = (target_location - global_position).normalized() * FLY_SPEED
		look_at(target_location)
	if in_targeting_type == Enum.TargetingType.TARGET_UNIT:
		target_character = in_target_character
	
# Must set
func initialize_stat(in_damage: float):
	damage = in_damage

func _on_damage_area_body_entered(body: Node3D) -> void:
	var enemy_stat = body.find_children("*", "EnemyStat").get(0)
	if enemy_stat:
		enemy_stat.set_health(enemy_stat.get_health() - damage)
		print(damage)
		die()
	
func die():
	var my_trail_1: Node3D = $MyTrail1
	if my_trail_1:
		my_trail_1.reparent(get_tree().current_scene)
	queue_free()
