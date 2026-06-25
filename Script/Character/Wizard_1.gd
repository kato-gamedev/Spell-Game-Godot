extends Character
class_name Wizard

@export var LOCOMOTION_BLENDSPACE_RATE: float = 0.3 # From 0.0 - 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super(delta)
	# Locomotion
	if animation_tree:
		var current_blend_position: Vector2 = animation_tree["parameters/Locomotion/blend_position"]
		var target_blend_position := Vector2(0,0)
		if Vector2(velocity.x, velocity.z).length() > 0.1:
			target_blend_position = Vector2(0, 1)
		else:
			target_blend_position = Vector2(0, 0)
		animation_tree["parameters/Locomotion/blend_position"] = lerp(current_blend_position, target_blend_position, LOCOMOTION_BLENDSPACE_RATE)

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

func _on_ability_system_component_health_changed(old_health: float, new_health: float, old_max_health: float, new_max_health: float) -> void:
	$HealthBar.set_value(new_health / new_max_health * 100)
