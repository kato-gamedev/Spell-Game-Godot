extends Control
class_name UI_SpellSlot

enum Type { GENERIC_SLOT, STAFF_SLOT }

@onready var texture_rect: TextureRect = $TextureRect
@onready var highlight: Panel = $Highlight
var scale_while_hover: float = 1.15

# Source
var source_inventory: SpellInventory = null
var index: int = 0

func _ready() -> void:
	texture_rect.texture = null
	set_highlight(false)

func initialize(in_source_inventory: SpellInventory, in_index: int):
	source_inventory = in_source_inventory
	index = in_index
	var spell = in_source_inventory.get_spell(in_index)
	if spell:
		texture_rect.texture = spell.icon

func set_highlight(is_highlighted: bool):
	highlight.visible = is_highlighted

func _on_mouse_entered() -> void:
	texture_rect.scale = Vector2(scale_while_hover, scale_while_hover)

func _on_mouse_exited() -> void:
	texture_rect.scale = Vector2(1.0, 1.0)
	
func _get_drag_data(at_position: Vector2) -> Variant:
	# Create preview
	var preview = TextureRect.new()
	preview.texture = texture_rect.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = size
	
	# Center the preview on the mouse cursor
	var control = Control.new()
	control.add_child(preview)
	preview.position = -0.5 * size
	set_drag_preview(control)
	
	return self

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is UI_SpellSlot

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var dragged_slot: UI_SpellSlot = data as UI_SpellSlot
	if not dragged_slot:
		return
	
	var current_slot_temp_spell: Spell = self.source_inventory.get_spell(index)
	self.source_inventory.set_spell(self.index, dragged_slot.source_inventory.get_spell(dragged_slot.index))
	dragged_slot.source_inventory.set_spell(dragged_slot.index, current_slot_temp_spell)
	
	# Try to refresh the spell layout
	var spell_layout: UI_SpellLayout = FunctionLibrary.get_parent_of_type(self, UI_SpellLayout)
	if spell_layout:
		spell_layout.refresh()
