extends Resource
class_name SpellInventory

@export var _SPELLS: Dictionary[int, Spell] = {}
signal spell_changed

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func get_spell(index: int) -> Spell:
	return _SPELLS.get(index)

func set_spell(index: int, spell: Spell):
	_SPELLS.set(index, spell)
	spell_changed.emit()
