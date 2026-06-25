extends TextureButton
class_name MapRoomVisual

## This class is for a more simple UI display

var logic_node: MapRoom # From our previous script
signal node_clicked(target_node)

func setup(data_node: MapRoom, icon_texture: Texture2D):
	logic_node = data_node
	texture_normal = icon_texture
	# Disable by default unless it's the starting row
	disabled = true

func _on_pressed():
	node_clicked.emit(logic_node)
