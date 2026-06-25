shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

// --- UNIFORMS ---
uniform vec4 lightning_color : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform float emission_energy = 5.0;

// Controls how wild the lightning is
uniform float amplitude = 1.5;
// Controls how many zig-zags the lightning has
uniform float frequency = 10.0;
// Controls how fast the lightning changes shape
uniform float speed = 20.0;

// --- NOISE FUNCTION ---
// Generates a random value based on a 2D coordinate
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 2D Value Noise to create smooth zig-zags between points
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Smoothstep interpolation
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    // Mix the values and remap from [0, 1] to [-1, 1]
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y) * 2.0 - 1.0;
}

void vertex() {
    // 1. TIME SNAPPING: 
    // Lightning doesn't slither like a snake; it flashes and snaps.
    // By using floor(), we lock the time value to step discretely.
    float snapped_time = floor(TIME * speed);
    
    // 2. GENERATE JAGGED NOISE:
    // We use UV.y (the length of the cylinder) and the snapped time.
    // We sample two different noise coordinates to push it on the X and Z axes.
    vec2 noise_coord_x = vec2(UV.y * frequency, snapped_time);
    vec2 noise_coord_z = vec2(UV.y * frequency + 100.0, snapped_time); // +100 to get a different random seed
    
    float offset_x = noise(noise_coord_x) * amplitude;
    float offset_z = noise(noise_coord_z) * amplitude;
    
    // 3. ANCHOR THE ENDS:
    // We don't want the base or the tip of the lightning to fly away.
    // sin(UV.y * PI) creates a curve that is 0.0 at the ends and 1.0 in the middle.
    float mask = sin(UV.y * PI);
    
    // 4. APPLY DISPLACEMENT:
    // Move the vertices outward based on the noise and the mask.
    VERTEX.x += offset_x * mask;
    VERTEX.z += offset_z * mask;
}

void fragment() {
    // 5. MAKE IT GLOW
    ALBEDO = lightning_color.rgb;
    
    // Make the lightning flicker by applying the same snapped time to a random brightness
    float flicker = hash(vec2(floor(TIME * speed * 1.5), 0.0)) * 0.5 + 0.5;
    
    EMISSION = lightning_color.rgb * emission_energy * flicker;
    ALPHA = lightning_color.a;
}