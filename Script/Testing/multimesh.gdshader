shader_type spatial;
render_mode shadows_disabled, skip_vertex_transform;

uniform mat4 NodeInverseTransform;
uniform float VoxelSize = 0.01;
uniform vec3 BaseColor : source_color = vec3(0.0, 0.8, 1.0);

// Math function uses lowercase variables
float sdfTorus(vec3 p, vec2 t) {
	vec2 q = vec2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
}

void vertex() {
	// Extract the absolute world center of this specific MultiMesh instance
	vec3 CenterWorld = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	
	// Snap it to the global 3D grid
	vec3 SnappedWorld = floor(CenterWorld / VoxelSize + 0.5) * VoxelSize;
	
	// Convert the snapped world position back to local space to check the shape
	vec3 LocalPos = (NodeInverseTransform * vec4(SnappedWorld, 1.0)).xyz;
	
	// Check if this grid position is inside the boomerang shape
	float Dist = sdfTorus(LocalPos, vec2(0.15, 0.02));
	
	// Combine snapped world position with the local cube vertex (strips all rotation)
	vec3 FinalWorldVertex = SnappedWorld + VERTEX;
	
	// Hide the voxel if it is outside the shape by collapsing it to a point
	if (Dist > 0.0) {
		FinalWorldVertex = SnappedWorld;
	}
	
	// Manually apply the camera view transform (required by skip_vertex_transform)
	VERTEX = (VIEW_MATRIX * vec4(FinalWorldVertex, 1.0)).xyz;
	NORMAL = (VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	ALBEDO = BaseColor;
	EMISSION = BaseColor * 2.0;
	ROUGHNESS = 0.2;
}