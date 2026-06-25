extends Node
class_name MagicStaff

# Wand stats
@export var CAST_INTERVAL: float = 0.1 # sec
# make sure this is bigger than 0.1 because the input doesn't have threshold yet
@export var COOLDOWN: float = 0.5 # sec
@export var MANA_MAX: float = 80.0 # mana
@export var MANA_REGEN: float = 12.0 # mana/sec
@export var CAPACITY: int = 5 # slot
@export var SPREAD: float = 1.0 # degree
@export var SPELL_INVENTORY: SpellInventory = null

# Internal state
var current_mana: float
var current_spell_range: Vector2i = Vector2i(-1, -1) # from 0 to above

# State
enum StaffState { READY, INTERVAL, RELOAD }
var staff_state: StaffState = StaffState.READY
var timer: float = 0.0

signal staff_changed

func _ready() -> void:
	current_spell_range = get_first_spell_range()
	SPELL_INVENTORY.spell_changed.connect(force_reload)
	#SPELLS.resize(int(CAPACITY))

func _process(delta: float) -> void:
	# Regenerate mana over time
	if current_mana < MANA_MAX:
		current_mana = min(current_mana + MANA_REGEN * delta, MANA_MAX)
	
	match staff_state:
		StaffState.READY:
			_process_ready(delta)
		StaffState.INTERVAL:
			_process_interval(delta)
		StaffState.RELOAD:
			_process_reload(delta)
	
func change_state(new_state: StaffState):
	staff_state = new_state
	timer = 0.0
	staff_changed.emit()
	
func _process_ready(delta: float) -> void:
	pass
	
func _process_interval(delta: float) -> void:
	timer += delta
	# Play interval logic
	if timer >= CAST_INTERVAL:
		change_state(StaffState.READY)
	
func _process_reload(delta: float) -> void:
	timer += delta
	# Play reload logic
	if timer >= COOLDOWN:
		change_state(StaffState.READY)
	
func cast(caster_context: CasterContext):
	if staff_state != StaffState.READY:
		return
	if current_spell_range == Vector2i(-1, -1):
		return
	
	# Modifiers to add to staff context
	var modifiers: Array[Modifier] = []
	
	# Cast current spell
	for i in range(current_spell_range.x, current_spell_range.y + 1):
		var current_spell = SPELL_INVENTORY.get_spell(i)
		# If spell is modifier, add it to staff context
		if current_spell and current_spell.SPELL_TYPE == Spell.Type.MODIFIER:
			modifiers.append(current_spell)
		# If spell is attack, cast it and end loop
		elif current_spell and current_spell.SPELL_TYPE == Spell.Type.ATTACK:
			var staff_context = StaffContext.new(modifiers)
			current_spell.cast(caster_context, staff_context)
			break
	
	# Immediately switch to next spell
	current_spell_range = find_next_spell_range(current_spell_range)
	
	# If can't switch to next spell, reload the staff
	if current_spell_range == Vector2i(-1, -1):
		current_spell_range = get_first_spell_range()
		change_state(StaffState.RELOAD)
	else:
		change_state(StaffState.INTERVAL)
	
	# Refresh the UI
	staff_changed.emit()

func find_next_spell_range(current_range: Vector2i) -> Vector2i:
	# Find the next spell
	for i in range(current_range.y + 1, CAPACITY):
		var spell = SPELL_INVENTORY.get_spell(i)
		if spell and spell.SPELL_TYPE == Spell.Type.ATTACK:
			return Vector2i(current_range.y + 1, i)
	
	return Vector2i(-1, -1)

func get_first_spell_range() -> Vector2i:
	return find_next_spell_range(Vector2i(-1, -1))

func force_reload():
	current_spell_range = get_first_spell_range()
	change_state(StaffState.RELOAD)
	staff_changed.emit()
