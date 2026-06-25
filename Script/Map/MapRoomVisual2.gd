extends TextureRect
class_name MapRoomVisual2

var icon_textures = {
	MapRoom.Type.MONSTER: preload("res://Script/Map/Icon/orc-head.png"),
	MapRoom.Type.ELITE: preload("res://Script/Map/Icon/ogre.png"),
	MapRoom.Type.REST: preload("res://Script/Map/Icon/campfire.png"),
	MapRoom.Type.SHOP: preload("res://Script/Map/Icon/shop.png"),
	MapRoom.Type.EVENT: preload("res://Script/Map/Icon/uncertainty.png"),
	MapRoom.Type.TREASURE: preload("res://Script/Map/Icon/chest.png")
}

var logic_room: MapRoom 
signal room_clicked(room_data: MapRoom)

func _ready() -> void:
	# 1. CRITICAL: Force the TextureRect to detect the mouse
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 2. Duplicate material so they don't all highlight at the same time
	if material:
		material = material.duplicate()
	else:
		push_error("No ShaderMaterial found on this TextureRect! Please add it in the Inspector.")

func setup(data: MapRoom) -> void:
	logic_room = data
	if icon_textures.has(logic_room.room_type):
		texture = icon_textures[logic_room.room_type]

# 3. TextureRects use _gui_input for clicks, NOT _pressed()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		room_clicked.emit(logic_room)
		print("Clicked on a ", MapRoom.Type.find_key(logic_room.room_type), " room at floor ", logic_room.y + 1)

func _on_mouse_entered() -> void:
	if material:
		material.set_shader_parameter("IsHovered", true)

func _on_mouse_exited() -> void:
	if material:
		material.set_shader_parameter("IsHovered", false)
