extends Node

## Read intersect_ray()
func line_trace(caller: Node3D, layer: int, start: Vector3, end: Vector3) -> Dictionary:
	var space_state := caller.get_world_3d().direct_space_state
	
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.collision_mask = (1 << layer - 1) #| (1 << 3 - 1) | (1 << 4 - 1)
	
	var result = space_state.intersect_ray(query)
	return result

## Read intersect_shape()
func sphere_trace(caller: Node3D, layer: int, start: Vector3, end: Vector3, radius: float) -> Array[Dictionary]:
	var space_state := caller.get_world_3d().direct_space_state
	
	var shape = CapsuleShape3D.new()
	shape.radius = radius * 1
	shape.height = (end - start).length() # 10 #
	
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	
	var new_transform := Transform3D()
	new_transform.origin = (start + end) / 2 #start #Vector3.ZERO #
	new_transform = new_transform.looking_at(end, Vector3.UP)
	new_transform = new_transform.rotated_local(Vector3.RIGHT, PI/2)
	query.transform = new_transform
	
	query.collision_mask = (1 << layer - 1) #| (1 << 3 - 1) | (1 << 4 - 1)
	
	## Debug mesh
	## Create a MeshInstance to represent the query
	#var debug_mesh = MeshInstance3D.new()
	#debug_mesh.mesh = shape.get_debug_mesh()
	## Set the material so it looks like a collision shape
	#var mat = StandardMaterial3D.new()
	#mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#mat.albedo_color = Color(0, 1, 0, 0.3) # Semi-transparent green
	#mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	#debug_mesh.material_override = mat
	## Place it in the world
	#caller.get_tree().root.add_child(debug_mesh)
	#debug_mesh.global_transform = query.transform
	
	var result = space_state.intersect_shape(query)
	return result

## Recursively climbs the scene tree to find a parent of the specified type.
## Returns the parent node if found, or null if it reaches the top of the tree.
func get_parent_of_type(current_node: Node, target_type: Variant) -> Node:
	var parent = current_node.get_parent()
	
	# Base case: We hit the absolute top of the scene tree without finding it.
	if parent == null:
		return null
		
	# Check 1: Target type is a built-in Godot class passed as a String (e.g., "MarginContainer")
	if typeof(target_type) == TYPE_STRING and parent.is_class(target_type):
		return parent
		
	# Check 2: Target type is a custom class (class_name) or preloaded script
	if is_instance_of(parent, target_type):
		return parent
		
	# Recursive case: This parent isn't a match, so run the function again on THIS parent.
	return get_parent_of_type(parent, target_type)
