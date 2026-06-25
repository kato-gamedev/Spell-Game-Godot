@tool
extends EditorPlugin

var snap_button: Button
var editor_selection: EditorSelection

func _enter_tree():
	# 1. Create the button but HIDE it by default
	snap_button = Button.new()
	snap_button.text = "Snap to Floor (or 0)"
	snap_button.hide() 
	
	# 2. Connect the button click
	snap_button.pressed.connect(snap_selected)
	
	# 3. Add to the 3D viewport toolbar
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, snap_button)
	
	# 4. Get the editor selection and listen for when you click on different things
	editor_selection = get_editor_interface().get_selection()
	editor_selection.selection_changed.connect(_on_selection_changed)

func _exit_tree():
	# Clean up when disabling the plugin
	if snap_button:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, snap_button)
		snap_button.queue_free()
		
	if editor_selection:
		editor_selection.selection_changed.disconnect(_on_selection_changed)

# --- This runs every time you click an object in the editor ---
func _on_selection_changed():
	var selected_nodes = editor_selection.get_selected_nodes()
	var show_button = false
	
	# Check if you have at least one 3D Node selected
	for node in selected_nodes:
		if node is Node3D:
			show_button = true
			break
			
	# Show or hide the button based on what you clicked
	snap_button.visible = show_button

# --- This runs when you click the "Snap to Floor" button ---
func snap_selected():
	var selected_nodes = editor_selection.get_selected_nodes()
	if selected_nodes.is_empty(): return
	
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Snap to Floor or 0")
	
	for node in selected_nodes:
		if not node is Node3D: continue
		
		# 1. Find the lowest bounding box point 
		# (Handles both raw MeshInstances and imported GLTF Node3D roots)
		var lowest_local_y = 0.0
		var mesh_instance = _get_mesh_from_node(node)
		
		if mesh_instance and mesh_instance.mesh:
			var aabb = mesh_instance.mesh.get_aabb()
			if node == mesh_instance:
				lowest_local_y = aabb.position.y * node.scale.y
			else:
				# If the mesh is a child of the root node
				lowest_local_y = (mesh_instance.position.y + (aabb.position.y * mesh_instance.scale.y)) * node.scale.y
		
		# 2. Shoot a physics ray downwards to find the floor
		var floor_y = 0.0 # Default to 0 if we hit nothing
		var space_state = node.get_world_3d().direct_space_state
		
		# We start the raycast 0.01 units BELOW the object so it doesn't accidentally hit itself!
		var bottom_of_object_world_y = node.global_position.y + lowest_local_y
		var ray_start = Vector3(node.global_position.x, bottom_of_object_world_y - 0.01, node.global_position.z)
		var ray_end = ray_start + Vector3(0, -1000, 0) # Cast 1000 meters down
		
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		var hit = space_state.intersect_ray(query)
		
		if hit:
			floor_y = hit.position.y
		
		# 3. Apply the movement
		var target_y = floor_y - lowest_local_y
		undo_redo.add_do_property(node, "global_position:y", target_y)
		undo_redo.add_undo_property(node, "global_position:y", node.global_position.y)

	undo_redo.commit_action()

# Helper function to find a mesh, even if the user clicked the GLTF Root node
func _get_mesh_from_node(node: Node3D) -> MeshInstance3D:
	if node is MeshInstance3D: return node
	for child in node.get_children():
		if child is MeshInstance3D: return child
	return null
