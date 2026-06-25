shader_type spatial;

// 1. Your original character texture
uniform sampler2D albedo_texture : source_color;

// 2. Fake Gloss Controls
uniform vec4 gloss_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White reflection
uniform float gloss_intensity : hint_range(0.0, 5.0) = 1.0; // How bright the shine is
uniform float gloss_sharpness : hint_range(1.0, 150.0) = 40.0; // Higher = tighter, wetter look. Lower = duller look.

void fragment() {
	// Read the original color
	vec4 texture_color = texture(albedo_texture, UV);
	ALBEDO = texture_color.rgb;
	
	// --- THE ALGORITHM (Fake Blinn-Phong Specular) ---
	
	// Create a "fake light source" attached to the camera. 
	// (0.5, 0.5, 1.0) means it comes from slightly above and to the right of the camera lens.
	vec3 fake_light_dir = normalize(vec3(0.5, 0.5, 1.0));
	
	// Calculate the "Half Vector" (the exact middle angle between the camera and the fake light)
	vec3 half_vector = normalize(fake_light_dir + VIEW);
	
	// Calculate how closely the model's surface normal matches that Half Vector
	// max(..., 0.0) prevents weird black glitches on the back of the model
	float specular_math = max(dot(NORMAL, half_vector), 0.0);
	
	// pow() takes that math and shrinks it into a tight, sharp circle
	float final_gloss = pow(specular_math, gloss_sharpness);
	
	// Add the gloss directly to Emission so it shines brightly regardless of scene lighting
	EMISSION = gloss_color.rgb * final_gloss * gloss_intensity;
}