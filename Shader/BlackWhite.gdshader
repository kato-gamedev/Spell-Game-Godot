shader_type canvas_item;

// Fetches the rendered screen behind this node
uniform sampler2D ScreenTexture : hint_screen_texture, filter_linear_mipmap;

// Controls how strong the black and white effect is (0.0 to 1.0)
uniform float BlendIntensity = 1.0;

float calculate_luminance(vec3 rgb_color) {
	// Standard mathematical weights for human eye light perception
	float calculated_luma = dot(rgb_color, vec3(0.299, 0.587, 0.114));
	return calculated_luma;
}

void fragment() {
	// 1. Get the original pixel from the screen
	vec4 OriginalColor = texture(ScreenTexture, SCREEN_UV);
	
	// 2. Calculate the brightness/luminance of that pixel
	float Luminance = calculate_luminance(OriginalColor.rgb);
	
	// 3. Create a monochrome version of the color
	vec3 GrayscaleColor = vec3(Luminance, Luminance, Luminance);
	
	// 4. Mix the original color with the grayscale color based on intensity
	COLOR.rgb = mix(OriginalColor.rgb, GrayscaleColor, BlendIntensity);
	
	// 5. Preserve original alpha
	COLOR.a = OriginalColor.a;
}