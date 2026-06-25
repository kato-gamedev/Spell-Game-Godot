class_name VoxelVFX extends MultiMeshInstance3D

@export var GRID_SIZE := Vector3(40, 10, 40) # Covers 40cm x 10cm x 40cm
@export var VOXEL_SIZE := 0.01 # 1cm voxels

func _ready() -> void:
	# Initialize the high-performance instance grid
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = int(GRID_SIZE.x * GRID_SIZE.y * GRID_SIZE.z)
	
	var box := BoxMesh.new()
	box.size = Vector3.ONE * VOXEL_SIZE
	multimesh.mesh = box
	
	var idx := 0
	var offset := GRID_SIZE / 2.0
	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			for z in range(GRID_SIZE.z):
				var pos := (Vector3(x, y, z) - offset) * VOXEL_SIZE
				multimesh.set_instance_transform(idx, Transform3D(Basis(), pos))
				idx += 1

func _process(_delta: float) -> void:
	# Provide the shader with inverse transform to check boundaries in local space
	if material_override is ShaderMaterial:
		material_override.set_shader_parameter("NodeInverseTransform", global_transform.affine_inverse())
