shader_type canvas_item;

uniform vec4 OutlineColor : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float OutlineWidth : hint_range(0.0, 10.0) = 2.0;
uniform bool IsHovered = false;

// How much to shrink the image to make room for the outline (1.2 = shrink by 20%)
uniform float PaddingScale : hint_range(1.0, 2.0) = 1.2;
// How dark a pixel needs to be to be considered "black background"
uniform float BlackThreshold : hint_range(0.0, 1.0) = 0.1;

// Helper function to check if a pixel is the actual white icon
bool is_solid(vec4 color) {
	// If the color is bright enough (not black), it's part of the icon
	return length(color.rgb) > BlackThreshold && color.a > 0.1;
}

void fragment() {
	// 1. Scale UVs from the center to create artificial padding
	vec2 uv_centered = UV - vec2(0.5);
	vec2 padded_uv = uv_centered * PaddingScale + vec2(0.5);
	
	// Check if our new UVs are outside the image boundaries
	bool out_of_bounds = padded_uv.x < 0.0 || padded_uv.x > 1.0 || padded_uv.y < 0.0 || padded_uv.y > 1.0;
	
	vec4 sprite_color = vec4(0.0);
	if (!out_of_bounds) {
		sprite_color = texture(TEXTURE, padded_uv);
	}
	
	// 2. Determine if the current pixel is the actual icon
	bool current_is_solid = !out_of_bounds && is_solid(sprite_color);
	
	// 3. Strip the black background (turn it transparent)
	vec4 final_color = current_is_solid ? sprite_color : vec4(0.0);
	
	// 4. Draw Outline if hovered
	if (IsHovered && !current_is_solid) {
		vec2 size = TEXTURE_PIXEL_SIZE * OutlineWidth * PaddingScale;
		bool has_solid_neighbor = false;
		
		// Sample 8 neighbors
		vec2 offsets[8] = {
			vec2(size.x, 0.0), vec2(-size.x, 0.0),
			vec2(0.0, size.y), vec2(0.0, -size.y),
			vec2(size.x, size.y), vec2(-size.x, size.y),
			vec2(size.x, -size.y), vec2(-size.x, -size.y)
		};
		
		for (int i = 0; i < 8; i++) {
			vec2 neighbor_uv = padded_uv + offsets[i];
			if (neighbor_uv.x >= 0.0 && neighbor_uv.x <= 1.0 && neighbor_uv.y >= 0.0 && neighbor_uv.y <= 1.0) {
				vec4 neighbor_color = texture(TEXTURE, neighbor_uv);
				if (is_solid(neighbor_color)) {
					has_solid_neighbor = true;
					break;
				}
			}
		}
		
		if (has_solid_neighbor) {
			final_color = OutlineColor;
		}
	}
	
	COLOR = final_color;
}