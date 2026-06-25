shader_type canvas_item;

uniform sampler2D _MainTex : hint_screen_texture, filter_linear_mipmap;

group_uniforms Brush_Settings;
// Controls the size of the brush strokes
uniform int radius : hint_range(2, 20) = 5;
// Controls how much the brush strokes stretch along edges. Higher = more directional
uniform float anisotropy : hint_range(0.1, 4.0) = 1.0;
// Controls the clarity of the brush stroke shapes
uniform float sharpness : hint_range(1.0, 15.0) = 8.0;

group_uniforms Detail_Settings;
// Controls edge preservation. High numbers keep edges sharp, low numbers blur them
uniform float hardness : hint_range(1.0, 20.0) = 8.0;
// Controls sector overlap. Alters the "texture" of the paint splotches
uniform float stroke_detail : hint_range(0.1, 1.5) = 0.58; 
// Controls polynomial weights distribution, high numbers equivalent to blurring image
uniform float zeta : hint_range(0.01, 1.0) = 0.1;

group_uniforms Color_Settings;
// Kuwahara tends to wash out colors. This boosts vibrance
uniform float saturation : hint_range(0.0, 3.0) = 1.2;
// Blends the painting effect with the original unpainted image
uniform float blend_mix : hint_range(0.0, 1.0) = 1.0;

const int _N = 8;

vec4 sobel(vec2 screen_size, vec2 uv) {
	vec2 d = screen_size.xy;
	
	vec3 sobel_x = (
		1.0 * texture(_MainTex, uv + vec2(-d.x, -d.y)).rgb +
		2.0 * texture(_MainTex, uv + vec2(-d.x,  0.0)).rgb +
		1.0 * texture(_MainTex, uv + vec2(-d.x,  d.y)).rgb +
		-1.0 * texture(_MainTex, uv + vec2(d.x, -d.y)).rgb +
		-2.0 * texture(_MainTex, uv + vec2(d.x,  0.0)).rgb +
		-1.0 * texture(_MainTex, uv + vec2(d.x,  d.y)).rgb
	) / 4.0;
	
	vec3 sobel_y = (
		1.0 * texture(_MainTex, uv + vec2(-d.x, -d.y)).rgb +
		2.0 * texture(_MainTex, uv + vec2( 0.0, -d.y)).rgb +
		1.0 * texture(_MainTex, uv + vec2( d.x, -d.y)).rgb +
		-1.0 * texture(_MainTex, uv + vec2(-d.x, d.y)).rgb +
		-2.0 * texture(_MainTex, uv + vec2( 0.0, d.y)).rgb +
		-1.0 * texture(_MainTex, uv + vec2( d.x, d.y)).rgb
	) / 4.0;
		
	return vec4(dot(sobel_x, sobel_x), dot(sobel_y, sobel_y), dot(sobel_x, sobel_y), 1.0);
}

// Single-pass structure tensor smoothing
vec4 get_smoothed_tensor(vec2 uv, vec2 d) {
	vec4 tensor = vec4(0.0);
	float weight_sum = 0.0;
	int blur_radius = 2; // Lightweight 5x5 blur
	
	for(int x = -blur_radius; x <= blur_radius; x++) {
		for(int y = -blur_radius; y <= blur_radius; y++) {
			tensor += sobel(d, uv + vec2(float(x), float(y)) * d);
			weight_sum += 1.0;
		}
	}
	return tensor / weight_sum;
}

vec4 scaling_factor(vec4 t) {
	float lambda1 = 0.5 * (t.x + t.y + sqrt(t.x * t.x - 2.0 * t.x * t.y + t.y * t.y + 4.0 * t.z * t.z));
	float lambda2 = 0.5 * (t.x + t.y - sqrt(t.x * t.x - 2.0 * t.x * t.y + t.y * t.y + 4.0 * t.z * t.z));

	vec2 v = vec2(lambda1 - t.x, -t.z);
	vec2 n = length(v) > 0.0 ? normalize(v) : vec2(0.0, 1.0);
	
	float phi = -atan(n.y / n.x);
	float A = (lambda1 + lambda2 > 0.0) ? (lambda1 - lambda2) / (lambda1 + lambda2) : 0.0;
	
	return vec4(n, phi, A);
}

vec4 kuwahara(vec2 n, float phi, float A, vec2 d, vec2 uv) {
	float a = float(radius) * clamp((anisotropy + A) / anisotropy, 0.1, 2.0);
	float b = float(radius) * clamp(anisotropy / (anisotropy + A), 0.1, 2.0);
	
	float cos_phi = cos(phi);
	float sin_phi = sin(phi);
	
	mat2 R = mat2(vec2(cos_phi, -sin_phi), vec2(sin_phi, cos_phi));
	mat2 S = mat2(vec2(0.5 / a, 0.0), vec2(0.0, 0.5 / b));
	mat2 SR = S * R; 
	
	int max_x = int(sqrt(a * a * cos_phi * cos_phi + b * b * sin_phi * sin_phi));
	int max_y = int(sqrt(a * a * sin_phi * sin_phi + b * b * cos_phi * cos_phi));
	
	float sinZeroCross = sin(stroke_detail);
	float eta = (zeta + cos(stroke_detail)) / (sinZeroCross * sinZeroCross);
	
	vec4 m[8];
	vec3 s[8];
	
	for (int k = 0; k < _N; k++) {
		m[k] = vec4(0.0);
		s[k] = vec3(0.0);
	}
	
	for (int y = -max_y; y <= max_y; y++) {
		for(int x = -max_x; x <= max_x; x++) {
			vec2 v = SR * vec2(float(x), float(y));
			if (dot(v, v) <= 0.25) {
				vec3 c = texture(_MainTex, uv + vec2(float(x), float(y)) * d).rgb;
				c = clamp(c, 0.0, 1.0);
				float sum = 0.0;
				float w[8];
				float z, vxx, vyy;
				
				vxx = zeta - eta * v.x * v.x;
				vyy = zeta - eta * v.y * v.y;
				z = max(0.0, v.y + vxx); w[0] = z * z; sum += w[0];
				z = max(0.0, -v.x + vyy); w[2] = z * z; sum += w[2];
				z = max(0.0, -v.y + vxx); w[4] = z * z; sum += w[4];
				z = max(0.0, v.x + vyy); w[6] = z * z; sum += w[6];
				
				v = sqrt(2.0) / 2.0 * vec2(v.x - v.y, v.x + v.y);
				vxx = zeta - eta * v.x * v.x;
				vyy = zeta - eta * v.y * v.y;
				z = max(0.0, v.y + vxx); w[1] = z * z; sum += w[1];
				z = max(0.0, -v.x + vyy); w[3] = z * z; sum += w[3];
				z = max(0.0, -v.y + vxx); w[5] = z * z; sum += w[5];
				z = max(0.0, v.x + vyy); w[7] = z * z; sum += w[7];
				
				float g = exp(-3.125 * dot(v, v)) / sum;
				
				for (int k = 0; k < 8; k++) {
					float wk = w[k] * g;
					m[k] += vec4(c * wk, wk);
					s[k] += c * c * wk;
				}
			}
		}
	}
	
	vec4 output = vec4(0.0);
	for (int k = 0; k < _N; ++k) {
		m[k].rgb /= m[k].w;
		s[k] = abs(s[k] / m[k].w - m[k].rgb * m[k].rgb);

		float sigma2 = s[k].r + s[k].g + s[k].b;
		float w = 1.0 / (1.0 + pow(hardness * 1000.0 * sigma2, 0.5 * sharpness));

		output += vec4(m[k].rgb * w, w);
	}
	
	return clamp(output / output.w, 0.0, 1.0);
}

void fragment() {
	vec4 original_color = texture(_MainTex, SCREEN_UV);
	
	// 1. Calculate smoothed structure tensor to find edge directions
	vec4 tensor = get_smoothed_tensor(SCREEN_UV, SCREEN_PIXEL_SIZE);
	// 2. Calculate scaling factors (Eigenvectors)
	vec4 fac = scaling_factor(tensor);
	// 3. Apply Kuwahara filter based on edge directions
	vec4 output = kuwahara(fac.xy, fac.z, fac.w, SCREEN_PIXEL_SIZE, SCREEN_UV);
	
	// Color Grading: Saturation Boost
	float luma = dot(output.rgb, vec3(0.299, 0.587, 0.114));
	output.rgb = mix(vec3(luma), output.rgb, saturation);

	// Output mix
	COLOR = mix(original_color, output, blend_mix);
}