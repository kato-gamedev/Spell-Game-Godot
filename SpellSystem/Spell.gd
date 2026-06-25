extends Resource
class_name Spell

enum Type { ATTACK, STATIC, MODIFIER, MULTICAST, PASSIVE }

@export var SPELL_NAME: String = "Base Spell"
@export var SPELL_TYPE: Type = Type.ATTACK
@export var MANA_COST: float = 10.0
@export var icon: Texture2D

func cast(caster_context: CasterContext, staff_context: StaffContext):
	pass
