shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float h_step : hint_range(1.0, 32.0, 1.0) = 8;
uniform float s_step : hint_range(1.0, 32.0, 1.0) = 8;
uniform float v_step : hint_range(1.0, 32.0, 1.0) = 8;
uniform bool use_hsv = false;

float posterize(float value, float levels) {
	return round(value * levels) / levels;
}

vec3 rgb_to_okhsv(vec3 rgb) {
	// 1. sRGB to Linear RGB
	vec3 lrgy = vec3(
		(rgb.r > 0.04045) ? pow((rgb.r + 0.055) / 1.055, 2.4) : rgb.r / 12.92,
		(rgb.g > 0.04045) ? pow((rgb.g + 0.055) / 1.055, 2.4) : rgb.g / 12.92,
		(rgb.b > 0.04045) ? pow((rgb.b + 0.055) / 1.055, 2.4) : rgb.b / 12.92
	);

	// 2. Linear RGB to OKLab
	float l = 0.4122214708 * lrgy.r + 0.5363320363 * lrgy.g + 0.0514459929 * lrgy.b;
	float m = 0.2119034982 * lrgy.r + 0.6806995451 * lrgy.g + 0.1073969566 * lrgy.b;
	float s = 0.0883024619 * lrgy.r + 0.2817188376 * lrgy.g + 0.6299787005 * lrgy.b;

	float l_ = pow(l, 1.0 / 3.0);
	float m_ = pow(m, 1.0 / 3.0);
	float s_ = pow(s, 1.0 / 3.0);

	float L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
	float a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
	float b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;

	// 3. OKLab to OKHSV (Simplified cylindrical mapping)
	float h = atan(b, a) / (2.0 * 3.1415926535);
	if (h < 0.0) h += 1.0;
	
	float chroma = sqrt(a * a + b * b);
	
	// Value is roughly based on Lightness, Saturation on Chroma
	// Note: For perfect gamut accuracy, Ottosson's full iterative 
	// LC_to_ST is usually used, but this is the standard shader approximation.
	float v = L;
	float sat = (v > 0.0) ? chroma / v : 0.0;
	
	return vec3(h, clamp(sat, 0.0, 1.0), clamp(v, 0.0, 1.0));
}

vec3 okhsv_to_rgb(vec3 hsv) {
	float h = hsv.x * 2.0 * 3.1415926535;
	float s = hsv.y;
	float v = hsv.z;

	// 1. OKHSV to OKLab
	float L = v;
	float a = v * s * cos(h);
	float b = v * s * sin(h);

	// 2. OKLab to Linear RGB
	float l_ = L + 0.3963377774 * a + 0.2158037573 * b;
	float m_ = L - 0.1055613458 * a - 0.0638541728 * b;
	float s_ = L - 0.0894841775 * a - 1.2914855480 * b;

	float l = l_ * l_ * l_;
	float m = m_ * m_ * m_;
	float s_lin = s_ * s_ * s_;

	vec3 lrgb = vec3(
		+4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s_lin,
		-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s_lin,
		-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s_lin
	);

	// 3. Linear RGB to sRGB (Gamma correction)
	return vec3(
		(lrgb.r > 0.0031308) ? 1.055 * pow(lrgb.r, 1.0 / 2.4) - 0.055 : 12.92 * lrgb.r,
		(lrgb.g > 0.0031308) ? 1.055 * pow(lrgb.g, 1.0 / 2.4) - 0.055 : 12.92 * lrgb.g,
		(lrgb.b > 0.0031308) ? 1.055 * pow(lrgb.b, 1.0 / 2.4) - 0.055 : 12.92 * lrgb.b
	);
}

void fragment() {
	vec4 tex_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec3 c_hsv = rgb_to_okhsv(vec3(tex_color.r, tex_color.g, tex_color.b));
	float r_hsv = posterize(c_hsv.r, h_step);
	float g_hsv = posterize(c_hsv.g, s_step);
	float b_hsv = posterize(c_hsv.b, v_step);
	vec3 c_rgb = okhsv_to_rgb(vec3(r_hsv, g_hsv, b_hsv));
	
	// Debug test HSV converter which is AI generated code
	vec3 final_color;
	if (use_hsv){
		vec3 testc_hsv = rgb_to_okhsv(c_rgb);
		final_color = okhsv_to_rgb(testc_hsv);
	}
	else
		final_color = c_rgb;
	COLOR = vec4(final_color.r, final_color.g, final_color.b, tex_color.a);
}
