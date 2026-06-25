extends Modifier
class_name StrengthMul

@export var multiplier: float = 1.1

## A modifier that add strength to next spell cast
func process_damage(in_damage: float) -> float:
	return in_damage * multiplier
