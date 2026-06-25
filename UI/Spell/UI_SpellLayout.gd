extends Control
class_name UI_SpellLayout

const SPELL = preload("uid://mu0ri3uwl7n")
@onready var player: Player = $".."
@onready var spell_bar: HBoxContainer = $SpellBar
@onready var all_spell_container: GridContainer = $AllSpellContainer
@export var ALL_SPELL_INVENTORY: SpellInventory = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	all_spell_container.visible = false
	


	await get_tree().process_frame
	# Connect staff to the refresh function
	player.magic_staff.staff_changed.connect(refresh)
	# Refresh to setup
	refresh()

func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	# Toggle pause state
	if event.is_action_pressed("inventory"):
		var tree: SceneTree = get_tree()
		all_spell_container.visible = !tree.paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if !tree.paused else Input.MOUSE_MODE_CAPTURED
		tree.paused = !tree.paused

func refresh():
	# Refresh all spell
	for child in all_spell_container.get_children():
		child.queue_free()
	
	for i in ALL_SPELL_INVENTORY._SPELLS.size():
		var new_spell_ui: UI_SpellSlot = SPELL.instantiate()
		all_spell_container.add_child(new_spell_ui)
		new_spell_ui.initialize(ALL_SPELL_INVENTORY, i)
	
	# Refresh staff
	var magic_staff: MagicStaff =  player.magic_staff
	# Remove all child
	for child in spell_bar.get_children():
		child.queue_free()
	
	for i in magic_staff.CAPACITY:
		# Create empty slots
		var new_spell_slot: UI_SpellSlot = SPELL.instantiate()
		spell_bar.add_child(new_spell_slot)
		
		# Initialize the slot with spell in it
		new_spell_slot.initialize(magic_staff.SPELL_INVENTORY, i)
		
		# Add highlight
		if i in range(magic_staff.current_spell_range.x, magic_staff.current_spell_range.y + 1):
			new_spell_slot.set_highlight(true)
