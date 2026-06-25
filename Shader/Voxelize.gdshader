shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform float VoxelSize : hint_range(0.01, 1.0, 0.01) = 0.1;
uniform sampler2D MainTexture : source_color, filter_nearest;

void vertex() {
	// Transform vertex to world space
	vec3 WorldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Snap to the global 3D grid
	vec3 SnappedWorldPos = round(WorldPos / VoxelSize) * VoxelSize;
	// Transform back to local space for rendering
	VERTEX = (inverse(MODEL_MATRIX) * vec4(SnappedWorldPos, 1.0)).xyz;
}

void fragment() {
	// Calculate screen-space derivatives to create flat, faceted shading
	vec3 XTangent = dFdx(VERTEX);
	vec3 YTangent = dFdy(VERTEX);
	vec3 FlatNormal = normalize(cross(YTangent, XTangent));
	
	// Apply normal and pixelated texture
	NORMAL = FlatNormal;
	vec4 SurfaceColor = texture(MainTexture, UV);
	ALBEDO = SurfaceColor.rgb;
}