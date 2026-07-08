shader_type canvas_item;

float inverse_lerp(float min_val, float max_val, float value) {
    return (value - min_val) / (max_val - min_val);
}

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float step = 12.0;
	vec2 value = floor(FRAGCOORD.xy / step) * step;
	float new_value = random(value);

	COLOR = vec4(new_value, new_value, new_value, 1.0);
}