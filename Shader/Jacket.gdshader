shader_type spatial;

// 1. Give the inspector a slot so you can put your character's texture back on!
uniform sampler2D albedo_texture : source_color;

// 2. Create sliders for shininess
// Roughness: 0.0 is mirror-smooth, 1.0 is completely matte.
uniform float custom_roughness : hint_range(0.0, 1.0) = 0.2; 

// Metallic: 0.0 is non-metal (plastic/leather), 1.0 is pure metal.
uniform float custom_metallic : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Read the original color from your texture file
	vec4 texture_color = texture(albedo_texture, UV);
	
	// Apply the original colors
	ALBEDO = texture_color.rgb;
	
	// Override the default material properties with our custom sliders
	ROUGHNESS = custom_roughness;
	METALLIC = custom_metallic;
}