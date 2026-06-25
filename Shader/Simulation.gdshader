shader_type canvas_item;

// Define colors we can change in the editor
uniform vec4 color_bg : source_color = vec4(0.05, 0.05, 0.08, 1.0); // Dark background
uniform vec4 color_1 : source_color = vec4(0.1, 0.6, 0.8, 1.0);     // The Blue/Cyan
uniform vec4 color_2 : source_color = vec4(0.8, 0.2, 0.3, 1.0);     // The Red/Pink
uniform vec4 color_3 : source_color = vec4(1.0, 0.8, 0.4, 1.0);     // Bright Core/Yellow

uniform float speed = 0.3;
uniform float scale = 3.0;

// Basic pseudo-random hash function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Mix 4 corners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

// Fractional Brownian Motion - layers of noise
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.50)));
    for (int i = 0; i < 5; ++i) {
        value += amplitude * noise(st);
        st = rot * st * 2.0 + shift;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV * scale;
    float time = TIME * speed;

    // DOMAIN WARPING
    // We create a noise value (q), and use it to distort the next noise value (r)
    vec2 q = vec2(0.);
    q.x = fbm(uv + vec2(0.0, 0.0) + time * 0.5);
    q.y = fbm(uv + vec2(1.0, 1.0) + time * 0.2);

    vec2 r = vec2(0.);
    r.x = fbm(uv + 1.0 * q + vec2(1.7, 9.2) + time * 0.7);
    r.y = fbm(uv + 1.0 * q + vec2(8.3, 2.8) + time * 0.6);

    float f = fbm(uv + r);

    // COLOR MIXING
    // Blend the colors based on the final noise value (f)
    vec3 final_color = mix(color_bg.rgb, color_1.rgb, clamp((f*f)*4.0, 0.0, 1.0));
    final_color = mix(final_color, color_2.rgb, clamp(length(q), 0.0, 1.0));
    final_color = mix(final_color, color_3.rgb, clamp(length(r.x), 0.0, 1.0));

    // Add contrast
    final_color = final_color * final_color * 1.5;

    COLOR = vec4(final_color, 1.0);
}