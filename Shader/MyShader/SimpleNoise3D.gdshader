shader_type spatial;
uniform sampler2D texture_x : source_color, repeat_enable;

void fragment() {
    vec4 world_coords = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 1.0)).xyz);
	vec3 adjusted_normal = abs(normal);
	vec3 weight = adjusted_normal / (adjusted_normal.x + adjusted_normal.y + adjusted_normal.z) * 3.0;
	
	vec2 uv_x = world_coords.zy;
	vec2 uv_y = world_coords.xz;
	vec2 uv_z = world_coords.xy;
	
	vec3 color_x = texture(texture_x, uv_x).rgb * weight.x;
	vec3 color_y = texture(texture_x, uv_y).rgb * weight.y;
	vec3 color_z = texture(texture_x, uv_z).rgb * weight.z;
	
	ALBEDO = (color_x + color_y + color_z) / 3.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}