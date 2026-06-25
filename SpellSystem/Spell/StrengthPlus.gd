extends Modifier
class_name StrengthPlus

@export var damage_add: float = 1.0

## A modifier that add strength to next spell cast
func process_damage(in_damage: float) -> float:
	return in_damage + damage_add
