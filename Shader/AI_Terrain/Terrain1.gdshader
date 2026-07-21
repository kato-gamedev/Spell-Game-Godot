shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded;

// ==========================================
// UNIFORMS (Adjust these in the inspector)
// ==========================================

group_uniforms Grass_Settings;
uniform vec3 grass_color_base : source_color = vec3(0.23, 0.30, 0.18); // Dark olive
uniform vec3 grass_color_highlight : source_color = vec3(0.31, 0.40, 0.23); // Lighter green
uniform vec3 grass_color_patch : source_color = vec3(0.19, 0.28, 0.29); // Blueish/Teal patches
uniform float grass_noise_scale = 0.5;
uniform float patch_noise_scale = 1.2;
uniform float patch_threshold : hint_range(0.0, 1.0) = 0.65;

group_uniforms Rock_Settings;
uniform vec3 rock_color_base : source_color = vec3(0.16, 0.14, 0.23); // Dark purple/blue
uniform vec3 rock_color_band : source_color = vec3(0.23, 0.22, 0.30); // Lighter rock band
uniform float rock_warp_scale = 0.3;
uniform float band_density = 2.0;
uniform float band_distortion = 1.5;

group_uniforms Blending_Settings;
uniform float slope_threshold : hint_range(-1.0, 1.0) = 0.7; // How steep before it becomes rock
uniform float slope_blend_softness : hint_range(0.0, 0.5) = 0.1;
uniform float transition_noise_scale = 0.8;
uniform float transition_noise_intensity = 0.2; // Breaks up the straight line of the slope

group_uniforms Material_Properties;
uniform float mat_roughness : hint_range(0.0, 1.0) = 0.9;
uniform float mat_specular : hint_range(0.0, 1.0) = 0.1;

// ==========================================
// VARYINGS
// ==========================================
varying vec3 world_pos;
varying vec3 world_normal;

// ==========================================
// CUSTOM NOISE FUNCTIONS (3D Value Noise)
// ==========================================

// 3D Hash function for randomness
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// 3D Value Noise
float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);

    // Smoothstep for non-linear interpolation (gives that slightly stylized look)
    f = f * f * (3.0 - 2.0 * f);

    return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
                   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
               mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
                   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// Fractional Brownian Motion (fBm) loop written directly in shader
float fbm(vec3 x, int octaves) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100.0); // Shift to prevent octave overlapping artifacts
    for (int i = 0; i < octaves; ++i) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

// ==========================================
// VERTEX & FRAGMENT
// ==========================================

void vertex() {
    // Get world position and normal for 3D mapping and slope detection
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    // ----------------------------------------------------
    // 1. GRASS GENERATION
    // ----------------------------------------------------
    // Base grass noise
    float n_grass = fbm(world_pos * grass_noise_scale, 4);

    // Smoothstep to create a "painterly/blotchy" transition rather than a smooth blur
    n_grass = smoothstep(0.4, 0.6, n_grass);
    vec3 grass_albedo = mix(grass_color_base, grass_color_highlight, n_grass);

    // Distinct stylistic patches (the teal/blueish spots in the image)
    // Offset the coordinates so it doesn't align with the base grass noise
    float n_patch = fbm(world_pos * patch_noise_scale + vec3(12.3, -4.5, 8.1), 3);

    // Step function creates hard, distinct edges for the patches
    n_patch = step(patch_threshold, n_patch);
    grass_albedo = mix(grass_albedo, grass_color_patch, n_patch);

    // ----------------------------------------------------
    // 2. ROCK / CLIFF GENERATION
    // ----------------------------------------------------
    // Noise used to warp the horizontal bands so they look organic
    float n_rock_warp = fbm(world_pos * rock_warp_scale, 3);

    // Generate horizontal striations using sine waves on the World Y axis, warped by noise
    float band = sin((world_pos.y * band_density) + (n_rock_warp * band_distortion));

    // Tight smoothstep to make the rock bands look stylized and sharp
    band = smoothstep(-0.1, 0.1, band);
    vec3 rock_albedo = mix(rock_color_base, rock_color_band, band);

    // ----------------------------------------------------
    // 3. SLOPE BLENDING (Triplanar style rule)
    // ----------------------------------------------------
    // Use the Y component of the world normal to determine how flat the surface is
    float slope = world_normal.y;

    // Break up the transition line so it looks like organic dirt/grass creeping down
    float n_transition = fbm(world_pos * transition_noise_scale + vec3(5.5), 3) * transition_noise_intensity;

    // Calculate the final blend factor between rock and grass
    float blend = smoothstep(slope_threshold - slope_blend_softness,
                             slope_threshold + slope_blend_softness,
                             slope + n_transition);

    // ----------------------------------------------------
    // 4. FINAL OUTPUT
    // ----------------------------------------------------
    ALBEDO = mix(rock_albedo, grass_albedo, blend);
    ROUGHNESS = mat_roughness;
    SPECULAR = mat_specular;
}