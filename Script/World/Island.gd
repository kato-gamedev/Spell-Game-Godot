extends Node3D
class_name Island

@export_file("*.glb") var low_res_island_path: String
@export_file("*.glb") var high_res_island_path: String
@onready var low_res_island: Node3D = $"City in the sky 2 - low"
var high_res_island: Node3D = null

enum IslandType{
	LOWRES,
	HIGHRES
}

func _process(_delta):
	if not low_res_island_path or not high_res_island_path:
		return
	var distance = get_player().global_position.distance_to(global_position)
	
	# Load island if close and not already loaded
	if distance < 500 and high_res_island == null:
		load_island(IslandType.HIGHRES)
		unload_island(low_res_island)
		
	# Unload island if far away
	elif distance > 550 and low_res_island == null:
		load_island(IslandType.LOWRES)
		unload_island(high_res_island)
	
	#if high_res_island == null:
		#load_island(IslandType.HIGHRES)

func load_island(island_type: IslandType):
	# Use threaded loading to prevent lag
	# In a real game, you'd wait for the status to be 'LOADED' 
	# then call load_threaded_get()
	match island_type:
		IslandType.HIGHRES:
			ResourceLoader.load_threaded_request(high_res_island_path)
			var scene = ResourceLoader.load_threaded_get(high_res_island_path)
			high_res_island = scene.instantiate()
			add_child(high_res_island)
		IslandType.LOWRES:
			ResourceLoader.load_threaded_request(low_res_island_path)
			var scene = ResourceLoader.load_threaded_get(low_res_island_path)
			low_res_island = scene.instantiate()
			add_child(low_res_island)

func unload_island(island: Node3D):
	if (island):
		island.queue_free()
		island = null

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")
