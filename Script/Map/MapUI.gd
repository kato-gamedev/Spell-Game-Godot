extends Control

const MAP_GENERATOR_SCRIPT := preload("res://Script/Map/MapGenerator.gd")
const VISUAL_SCENE := preload("res://Script/Map/MapRoomVisual2.tscn")

const X_SPACING = 120
const Y_SPACING = 130
const BOTTOM_MARGIN = 100
const TOP_MARGIN = 100

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_canvas: ColorRect = $ScrollContainer/MarginContainer/ColorRect

func _ready() -> void:
	var map_generator = MAP_GENERATOR_SCRIPT.new()
	map_generator.generate_map()
	build_visual_map(map_generator.active_rooms)
	
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)

func build_visual_map(active_rooms: Array[MapRoom]) -> void:
	# Setup canvas size for 15 floors
	var required_height = (14 * Y_SPACING) + BOTTOM_MARGIN + TOP_MARGIN
	map_canvas.custom_minimum_size.y = required_height
	await get_tree().process_frame
	
	var total_grid_width = (MAP_GENERATOR_SCRIPT.MAP_WIDTH - 1) * X_SPACING
	var center_offset_x = (map_canvas.size.x - total_grid_width) / 2.0
	var icon_center_offset = Vector2(25, 25)
	var active_visuals = {}

	# Spawn visual nodes
	for logic_room in active_rooms:
		var visual_node: MapRoomVisual2 = VISUAL_SCENE.instantiate()
		map_canvas.add_child(visual_node)
		map_canvas.z_index = 1
		
		var pos_x = center_offset_x + (logic_room.x * X_SPACING) + randf_range(-15, 15)
		var pos_y = required_height - BOTTOM_MARGIN - (logic_room.y * Y_SPACING) + randf_range(-15, 15)
		
		visual_node.position = Vector2(pos_x, pos_y) - icon_center_offset
		visual_node.setup(logic_room)
		active_visuals[logic_room] = visual_node

	# Draw connection lines
	for logic_room in active_rooms:
		var start_visual = active_visuals[logic_room]
		for next_logic in logic_room.next_nodes:
			var end_visual = active_visuals[next_logic]
			var start_pos = start_visual.position + icon_center_offset
			var end_pos = end_visual.position + icon_center_offset
			draw_connection(start_pos, end_pos)

func draw_connection(start_pos: Vector2, end_pos: Vector2) -> void:
	var line = Line2D.new()
	line.add_point(start_pos)
	line.add_point(end_pos)
	line.width = 4.0
	line.default_color = Color(0.2, 0.2, 0.2, 0.6) 
	map_canvas.add_child(line)
	map_canvas.move_child(line, 0)
