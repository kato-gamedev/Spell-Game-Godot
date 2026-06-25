extends Node2D
class_name MapGenerator

const MAP_WIDTH = 7
const MAP_HEIGHT = 15
const PATHS_TO_GENERATE = 6

var grid: Array = []
var active_rooms: Array[MapRoom] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = hash("THE_SILENT_SEED_123")
	generate_map()
	queue_redraw()

func generate_map() -> void:
	# Initialize empty grid
	grid.clear()
	for x in range(MAP_WIDTH):
		var column = []
		for y in range(MAP_HEIGHT):
			column.append(MapRoom.new(x, y))
		grid.append(column)
		
	generate_paths()
	cull_unused_nodes()
	assign_room_types()

func generate_paths() -> void:
	for i in range(PATHS_TO_GENERATE):
		var current_x = rng.randi_range(0, MAP_WIDTH - 1)
		
		# Walk up floor by floor
		for y in range(MAP_HEIGHT - 1):
			var current_node: MapRoom = grid[current_x][y]
			var valid_next_x = []
			
			# Find paths that don't cross existing lines
			for dx in [-1, 0, 1]:
				var test_x = current_x + dx
				if test_x < 0 or test_x >= MAP_WIDTH:
					continue
					
				var is_crossing = false
				if dx == 1:
					if grid[current_x + 1][y].next_nodes.has(grid[current_x][y + 1]):
						is_crossing = true
				elif dx == -1:
					if grid[current_x - 1][y].next_nodes.has(grid[current_x][y + 1]):
						is_crossing = true
						
				if not is_crossing:
					valid_next_x.append(test_x)
			
			# Pick safe option and connect
			var next_x = valid_next_x[rng.randi() % valid_next_x.size()]
			var next_node: MapRoom = grid[next_x][y + 1]
			
			if not current_node.next_nodes.has(next_node):
				current_node.next_nodes.append(next_node)
				next_node.parents.append(current_node)
			current_x = next_x

func cull_unused_nodes() -> void:
	active_rooms.clear()
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var node: MapRoom = grid[x][y]
			if node.next_nodes.size() > 0 or node.parents.size() > 0:
				active_rooms.append(node)

func assign_room_types() -> void:
	var nodes_to_assign = []
	
	# Assign hardcoded floors
	for node in active_rooms:
		if node.y == 0: node.room_type = MapRoom.Type.MONSTER
		elif node.y == 8: node.room_type = MapRoom.Type.TREASURE
		elif node.y == 14: node.room_type = MapRoom.Type.REST
		else: nodes_to_assign.append(node)
			
	# Fill bucket with proportional room types
	var total = nodes_to_assign.size()
	var bucket = []
	for i in round(total * 0.22): bucket.append(MapRoom.Type.EVENT)
	for i in round(total * 0.12): bucket.append(MapRoom.Type.REST)
	for i in round(total * 0.08): bucket.append(MapRoom.Type.ELITE)
	for i in round(total * 0.05): bucket.append(MapRoom.Type.SHOP)
	while bucket.size() < total: bucket.append(MapRoom.Type.MONSTER)
		
	bucket_shuffle(bucket)

	# Assign from bucket honoring rules
	for node in nodes_to_assign:
		var assigned = false
		for i in range(bucket.size()):
			var candidate = bucket[i]
			if is_valid_room(node, candidate):
				node.room_type = candidate
				bucket.remove_at(i)
				assigned = true
				break
		# Failsafe if rules block all bucket options
		if not assigned:
			node.room_type = MapRoom.Type.MONSTER

func is_valid_room(node: MapRoom, type: MapRoom.Type) -> bool:
	if node.y < 5 and (type == MapRoom.Type.ELITE or type == MapRoom.Type.REST): return false
	if node.y == 13 and type == MapRoom.Type.REST: return false
		
	# Siblings cannot share room types
	for parent in node.parents:
		for sibling in parent.next_nodes:
			if sibling != node and sibling.room_type == type:
				return false
	return true

func bucket_shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp

# --- Debug Drawing Setup ---
const X_SPACING = 80
const Y_SPACING = -60

var colors = {
	MapRoom.Type.MONSTER: Color.GRAY,
	MapRoom.Type.ELITE: Color.RED,
	MapRoom.Type.REST: Color.ORANGE,
	MapRoom.Type.SHOP: Color.YELLOW,
	MapRoom.Type.EVENT: Color.CYAN,
	MapRoom.Type.TREASURE: Color.BROWN
}

func _draw() -> void:
	var start_pos = Vector2(100, 900)
	
	for node in active_rooms:
		var pos = start_pos + Vector2(node.x * X_SPACING, node.y * Y_SPACING)
		for next_node in node.next_nodes:
			var next_pos = start_pos + Vector2(next_node.x * X_SPACING, next_node.y * Y_SPACING)
			draw_line(pos, next_pos, Color.DARK_GRAY, 3.0)
			
	for node in active_rooms:
		var pos = start_pos + Vector2(node.x * X_SPACING, node.y * Y_SPACING)
		var color = colors.get(node.room_type, Color.WHITE)
		draw_circle(pos, 15.0, color)
		draw_arc(pos, 15.0, 0, TAU, 32, Color.BLACK, 2.0)

func _on_button_pressed() -> void:
	rng.randomize() 
	print("Generating new map with seed: ", rng.seed)
	generate_map()
	queue_redraw()
