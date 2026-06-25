/*
Shader from Godot Shaders - the free shader library.
godotshaders.com/shader/oklch-posterization-color-palette-shader

MIT License. Made by Yūgen. Feel free to use, improve and change this shader according to your needs
and consider sharing the modified result on godotshaders.com.

Modified to accept a dynamic 1D Texture Strip as the palette.
Modified so Lightness, Chroma, and Hue all use intuitive "step" counts.
*/

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D palette : filter_nearest, repeat_disable;

group_uniforms Color_Palette;
uniform float mix_amount = 1.0;
group_uniforms;

group_uniforms OKLCH_Values;
uniform bool use_l = true;
uniform bool use_c = true;
uniform bool use_h = true;

// All values now represent the number of "steps" or chunks to slice the color space into.
uniform float steps_l : hint_range(1.0, 50.0, 1.0) = 25.0; // 25 levels of brightness
uniform float steps_c : hint_range(1.0, 50.0, 1.0) = 10.0; // 10 levels of saturation/chroma
uniform float steps_h : hint_range(1.0, 64.0, 1.0) = 12.0; // 12 distinct hues around the color wheel
group_uniforms;

vec3 get_nearest_color(vec3 color) {
	// Get the width of the palette texture dynamically
	int palette_size = textureSize(palette, 0).x;

	float min_diff = 9999.0;
	vec3 nearest_color = color;

	for (int i = 0; i < 256; i++) {
		if (i >= palette_size) {
			break;
		}

		float uv_x = (float(i) + 0.5) / float(palette_size);
		vec3 palette_color = texture(palette, vec2(uv_x, 0.5)).rgb;

		float curr_dist = distance(palette_color, color);
		if (curr_dist < min_diff) {
			min_diff = curr_dist;
			nearest_color = palette_color;
		}
	}
	return nearest_color;
}

vec3 rgb_to_oklch(vec3 rgb) {
	// convert srgb to linear rgb
	vec3 linear_rgb;
	linear_rgb.r = (rgb.r <= 0.04045) ? rgb.r / 12.92 : pow((rgb.r + 0.055) / 1.055, 2.4);
	linear_rgb.g = (rgb.g <= 0.04045) ? rgb.g / 12.92 : pow((rgb.g + 0.055) / 1.055, 2.4);
	linear_rgb.b = (rgb.b <= 0.04045) ? rgb.b / 12.92 : pow((rgb.b + 0.055) / 1.055, 2.4);

	// convert linear rgb to xyz (CIE 1931 XYZ color space) primary color space
	float x = linear_rgb.r * 0.4124 + linear_rgb.g * 0.3576 + linear_rgb.b * 0.1805;
	float y = linear_rgb.r * 0.2126 + linear_rgb.g * 0.7152 + linear_rgb.b * 0.0722;
	float z = linear_rgb.r * 0.0193 + linear_rgb.g * 0.1192 + linear_rgb.b * 0.9505;

	float xd65 = 0.95047;
	float yd65 = 1.0;
	float zd65 = 1.08883;

	float x_norm = x / xd65;
	float y_norm = y / yd65;
	float z_norm = z / zd65;

	float fx = (x_norm > 0.008856) ? pow(x_norm, 1.0 / 3.0) : (7.787 * x_norm + 16.0 / 116.0);
	float fy = (y_norm > 0.008856) ? pow(y_norm, 1.0 / 3.0) : (7.787 * y_norm + 16.0 / 116.0);
	float fz = (z_norm > 0.008856) ? pow(z_norm, 1.0 / 3.0) : (7.787 * z_norm + 16.0 / 116.0);

	float l_lab = 116.0 * fy - 16.0;
	float a_lab = 500.0 * (fx - fy);
	float b_lab = 200.0 * (fy - fz);

	float c = sqrt(a_lab * a_lab + b_lab * b_lab);
	float h = degrees(atan(b_lab, a_lab));
	if (h < 0.0) {
		h += 360.0;
	}

	return vec3(l_lab / 100.0, c / 100.0, h);
}

vec3 oklch_to_rgb(vec3 lch) {
	float l = lch.x * 100.0;
	float c = lch.y * 100.0;
	float h_rad = radians(lch.z);

	float a_lab = cos(h_rad) * c;
	float b_lab = sin(h_rad) * c;

	float fy = (l + 16.0) / 116.0;
	float fx = a_lab / 500.0 + fy;
	float fz = fy - b_lab / 200.0;
	vec3 f = vec3(fx, fy, fz);
	vec3 f_cubed = pow(f, vec3(3.0));

	vec3 mask_xyz = step(vec3(0.008856), f_cubed);
	vec3 xyz = mask_xyz * f_cubed + (1.0 - mask_xyz) * ((f - vec3(16.0/116.0)) / 7.787);
	vec3 d65 = vec3(0.95047, 1.0, 1.08883);
	xyz *= d65;

	float r = xyz.x *  3.2406 + xyz.y * -1.5372 + xyz.z * -0.4986;
	float g = xyz.x * -0.9689 + xyz.y *  1.8758 + xyz.z *  0.0415;
	float b = xyz.x *  0.0557 + xyz.y * -0.2040 + xyz.z *  1.0570;
	vec3 linear_rgb = vec3(r, g, b);

	vec3 linear_gamma = linear_rgb * 12.92;
	vec3 non_linear_gamma = 1.055 * pow(linear_rgb, vec3(1.0 / 2.4)) - 0.055;

	vec3 mask_rgb = step(linear_rgb, vec3(0.0031308));
	vec3 srgb = mix(non_linear_gamma, linear_gamma, mask_rgb);

	return clamp(srgb, 0.0, 1.0);
}

float posterize(float value, float levels) {
	return round(value * levels) / levels;
}

void fragment() {
	vec4 original_sc = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec3 oklch = rgb_to_oklch(original_sc.rgb);

	if (use_l) {
		oklch.r = posterize(oklch.r, steps_l);
	}
	if (use_c) {
		oklch.g = posterize(oklch.g, steps_c);
	}
	if (use_h) {
		// Hue is 0 to 360 degrees.
		// We normalize it to 0.0 - 1.0, posterize into chunks, then expand it back to 360.
		float normalized_h = oklch.b / 360.0;
		oklch.b = posterize(normalized_h, steps_h) * 360.0;
	}

	vec3 posterized_sc = oklch_to_rgb(oklch);
	vec3 nearest_color = get_nearest_color(posterized_sc);
	vec3 final_sc = mix(posterized_sc, nearest_color, mix_amount);

	COLOR = vec4(final_sc, 1.0);
}