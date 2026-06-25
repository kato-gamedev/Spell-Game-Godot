shader_type canvas_item;

// The screen texture. Note: filter_nearest is used to keep pixel art crisp.
// If you are making a 3D/smooth game, you can change it to filter_linear.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// The palette texture. MUST be set to filter_nearest so colors don't blend.
uniform sampler2D palette : filter_nearest, repeat_disable;

// A standard weight vector used to calculate perceptual color distance.
// The human eye is most sensitive to green, then red, then blue.
const vec3 PERCEPTUAL_WEIGHTS = vec3(0.299, 0.587, 0.114);

void fragment() {
    // Get the original color from the screen
    vec3 original_color = texture(screen_texture, SCREEN_UV).rgb;
    
    // Get the width of the palette texture dynamically
    int palette_size = textureSize(palette, 0).x;
    
    vec3 closest_color = vec3(0.0);
    float min_distance = 9999.0;
    
    // Loop through every color in the palette.
    // Note: Shaders require a constant maximum loop limit for compatibility.
    // 256 is usually more than enough for palette swapping. Increase if needed.
    for (int i = 0; i < 256; i++) {
        if (i >= palette_size) {
            break; // Stop looping once we've checked all actual colors
        }
        
        // Calculate the UV coordinate to sample the exact center of the palette pixel
        float uv_x = (float(i) + 0.5) / float(palette_size);
        vec3 palette_color = texture(palette, vec2(uv_x, 0.5)).rgb;
        
        // Calculate the difference between the screen color and palette color
        vec3 diff = original_color - palette_color;
        
        // Calculate perceptual squared distance
        vec3 weighted_sq_diff = diff * diff * PERCEPTUAL_WEIGHTS;
        float dist = weighted_sq_diff.x + weighted_sq_diff.y + weighted_sq_diff.z;
        
        // If this is the closest color we've seen so far, save it
        if (dist < min_distance) {
            min_distance = dist;
            closest_color = palette_color;
        }
    }
    
    // Output the mapped color
    COLOR = vec4(closest_color, 1.0);
}