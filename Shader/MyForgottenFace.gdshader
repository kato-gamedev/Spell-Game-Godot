shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// ALL UPPER CASE FOR EXPORT VARIABLES (UNIFORMS)
uniform vec4 BASE_STONE_COLOR : source_color = vec4(0.85, 0.85, 0.82, 1.0);
uniform vec4 MOSS_COLOR : source_color = vec4(0.28, 0.40, 0.15, 1.0);
uniform vec4 DIRT_COLOR : source_color = vec4(0.18, 0.15, 0.12, 1.0);
uniform sampler2D NOISE_TEXTURE : hint_default_white;
uniform sampler2D NORMAL_TEXTURE : hint_normal;
uniform float MOSS_SPREAD : hint_range(0.0, 1.0) = 0.6;
uniform float WEATHERING_INTENSITY : hint_range(0.0, 1.0) = 0.7;
uniform float ROUGHNESS_BASE : hint_range(0.0, 1.0) = 0.25;

// Variables inside math functions (use snake_case / lowercase)
float calculate_moss_mask(float noise_value, float up_factor, float spread_amount) {
	float raw_mask = noise_value * up_factor;
	float smoothed_mask = smoothstep(1.0 - spread_amount, 1.0, raw_mask);
	return smoothed_mask;
}

float calculate_dirt_mask(float noise_value, float intensity) {
	float calculated_dirt = noise_value * intensity;
	return clamp(calculated_dirt, 0.0, 1.0);
}

void fragment() {
	// PascalCase cho tất cả các biến (ngoại trừ các biến trong hàm toán học ở trên)
	vec2 BaseUv = UV;
	
	vec4 NoiseSample = texture(NOISE_TEXTURE, BaseUv);
	vec3 NormalSample = texture(NORMAL_TEXTURE, BaseUv).rgb;
	
	// Tính toán pháp tuyến không gian thế giới (World Normal) để rêu mọc trên đỉnh
	vec3 WorldNormal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float UpDirection = dot(WorldNormal, vec3(0.0, 1.0, 0.0));
	UpDirection = max(UpDirection, 0.0);
	
	// Tạo mặt nạ dựa trên các hàm toán học
	float MossMask = calculate_moss_mask(NoiseSample.r, UpDirection, MOSS_SPREAD);
	float DirtMask = calculate_dirt_mask(NoiseSample.g, WEATHERING_INTENSITY);
	
	// Pha trộn màu sắc: Đá nền -> Bụi bẩn -> Rêu xanh
	vec3 AlbedoColor = mix(BASE_STONE_COLOR.rgb, DIRT_COLOR.rgb, DirtMask);
	AlbedoColor = mix(AlbedoColor, MOSS_COLOR.rgb, MossMask);
	
	// Xử lý độ nhám: Rêu và bụi làm bề mặt nhám hơn so với đá cẩm thạch đã mài
	float FinalRoughness = mix(ROUGHNESS_BASE, 0.95, max(MossMask, DirtMask));
	
	// Gán vào các hằng số mặc định của Godot
	ALBEDO = AlbedoColor;
	ROUGHNESS = FinalRoughness;
	NORMAL_MAP = NormalSample;
}