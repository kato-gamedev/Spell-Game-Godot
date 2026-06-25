extends RefCounted
class_name StaffContext 

var modifiers: Array[Modifier] = []

func _init(in_modifiers: Array[Modifier]) -> void:
	modifiers = in_modifiers

func apply_mod_to_damage(in_damage: float) -> float:
	var new_damage := in_damage
	for modifier in modifiers:
		new_damage = modifier.process_damage(new_damage)
	return new_damage
