extends Node3D

func draw_line(pos1: Vector3, pos2: Vector3, color: Color = Color.WHITE, duration: float = 0.01):
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	get_tree().root.add_child(mesh_instance)

	if duration > 0:
		await get_tree().create_timer(duration).timeout
		mesh_instance.queue_free()

func draw_cylinder(pos1: Vector3, pos2: Vector3, radius: float = 0.05, color: Color = Color.WHITE, duration: float = 0.01):
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	var material = StandardMaterial3D.new()

	# 1. Configure the Mesh
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = pos1.distance_to(pos2)
	cylinder_mesh.radial_segments = 8 # Lower for performance, higher for smoothness
	
	mesh_instance.mesh = cylinder_mesh

	# 2. Configure the Material
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh_instance.material_override = material

	# 3. Placement and Rotation
	get_tree().root.add_child(mesh_instance)
	
	# Position at the midpoint
	var midpoint = (pos1 + pos2) / 2.0
	mesh_instance.global_position = midpoint
	
	# Orient the cylinder
	# By default, cylinders are Y-up. We point the -Z axis at the target, 
	# then rotate 90 degrees on X to align the Y-axis.
	if pos1.distance_to(pos2) > 0.001:
		mesh_instance.look_at(pos2, Vector3.UP)
		mesh_instance.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(90))

	# 4. Cleanup
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		mesh_instance.queue_free()

func draw_sphere(pos: Vector3, radius: float = 0.05, color: Color = Color.WHITE, duration: float = 0.01):
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	var material = StandardMaterial3D.new()

	# 1. Configure the Mesh
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 8 # Lower for performance, higher for smoothness
	
	mesh_instance.mesh = sphere_mesh

	# 2. Configure the Material
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh_instance.material_override = material

	# 3. Placement and Rotation
	get_tree().root.add_child(mesh_instance)
	
	# Position
	mesh_instance.global_position = pos

	# 4. Cleanup
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		mesh_instance.queue_free()
