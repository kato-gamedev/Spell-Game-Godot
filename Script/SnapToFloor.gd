@tool
extends EditorScript

# This function runs when you click File -> Run in the script editor
func _run():
	# Get all the nodes you currently have selected in the 3D viewport
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	
	for node in selected_nodes:
		if node is MeshInstance3D and node.mesh:
			# Get the bounding box of the mesh
			var aabb = node.mesh.get_aabb()
			
			# aabb.position.y is the lowest local point of the mesh.
			# We multiply by scale just in case you resized the object.
			var lowest_point = aabb.position.y * node.scale.y
			
			# Move the object up or down so its lowest point rests exactly on Y = 0
			node.global_position.y = -lowest_point
			print("Snapped bounding box of ", node.name, " to Y=0")
		else:
			print(node.name, " is not a MeshInstance3D.")
