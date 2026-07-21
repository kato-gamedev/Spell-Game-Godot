shader_type sky;

group_uniforms Sky_and_Lighting;
uniform vec3 sun_color : source_color = vec3(1.2, 1.2, 1.0); // >1.0 for Godot Glow/Bloom
uniform vec3 sky_color : source_color = vec3(0.1, 0.45, 0.9);
uniform float sun_spread : hint_range(0.1, 5.0) = 1.5;

group_uniforms Canopy_Leaves;
uniform vec3 leaf_dark_color : source_color = vec3(0.02, 0.15, 0.02);
uniform vec3 leaf_lit_color : source_color = vec3(0.4, 0.8, 0.1);
uniform float leaf_scale : hint_range(0.1, 10.0) = 4.0;
uniform float canopy_density : hint_range(0.0, 1.0) = 0.55;

group_uniforms Tree_Trunks;
uniform vec3 trunk_color : source_color = vec3(0.03, 0.04, 0.02);
uniform float trunk_frequency : hint_range(1.0, 30.0) = 15.0;
uniform float trunk_thickness : hint_range(0.0, 1.0) = 0.75;


// --- PROCEDURAL NOISE FUNCTIONS ---

// 2D Random Hash
vec2 hash(vec2 p) {
    p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(p)*43758.5453123);
}

// 2D Simplex Noise
float noise(vec2 p) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
    vec2 i = floor(p + (p.x+p.y)*K1);
    vec2 a = p - i + (i.x+i.y)*K2;
    float m = step(a.y, a.x); 
    vec2 o = vec2(m, 1.0 - m);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0*K2;
    vec3 h = max(0.5 - vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0);
    vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot(n, vec3(70.0));
}

// Fractal Brownian Motion (FBM) for natural layering
float fbm(vec2 p) {
    float f = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for(int i = 0; i < 4; i++) {
        f += amp * noise(p * freq);
        freq *= 2.0;
        amp *= 0.5;
    }
    return f * 0.5 + 0.5; // Normalize to 0.0 - 1.0
}


// --- MAIN SKY SHADER ---

void sky() {
    // 1. PROJECT THE DOME TO A FLAT PLANE (Perspective trick)
    // We imagine a flat "ceiling" above the camera. 
    // This creates natural perspective: things get smaller near the zenith.
    float view_y = max(EYEDIR.y, 0.02); // Prevent division by zero at horizon
    vec2 uv = EYEDIR.xz / view_y; 
    
    // Distance from the zenith (straight up)
    float dist = length(uv);
    // Angle around the zenith (for radial trunks)
    float angle = atan(uv.y, uv.x);

    // Fade everything to dark green below the horizon line
    float horizon_mask = smoothstep(0.0, 0.1, EYEDIR.y);


    // 2. SKY BACKGROUND & SUN
    // Calculate a glowing gradient emanating from the center (zenith)
    float sun_mask = exp(-dist * sun_spread);
    vec3 base_sky = mix(sky_color, sun_color, sun_mask);


    // 3. TREE TRUNKS & BRANCHES (Radial Warped Lines)
    // Warp the angle using FBM so the trees grow crookedly, not perfectly straight.
    float angle_warp = fbm(uv * 0.5) * 1.5;
    float warped_angle = angle + angle_warp;
    
    // Create radial lines by feeding the warped angle into a sine wave.
    float trunk_lines = sin(warped_angle * trunk_frequency) * 0.5 + 0.5;
    
    // Add noise to the radius to make branches fork and look bark-like.
    trunk_lines *= fbm(vec2(warped_angle * 5.0, dist * 2.0));
    
    // Threshold into solid dark shapes.
    float trunk_mask = smoothstep(trunk_thickness, trunk_thickness + 0.1, trunk_lines);
    
    // Fade trunks out exactly at the sun so they don't block the very center
    trunk_mask *= smoothstep(0.1, 0.5, dist); 


    // 4. CANOPY & LEAVES (Fractal Blobs)
    // Domain warp the UVs for the leaves so they swirl naturally.
    vec2 leaf_warp = vec2(fbm(uv + 1.0), fbm(uv - 1.0)) * 0.5;
    float leaf_noise = fbm((uv + leaf_warp) * leaf_scale);
    
    // Crown Shyness / Cracks: Multiply by another noise to create gaps
    float gaps = fbm(uv * (leaf_scale * 0.3));
    leaf_noise *= smoothstep(0.2, 0.8, gaps);
    
    // Density gradient: Canopy is thicker near horizon, thinner near zenith
    float current_density = mix(canopy_density - 0.2, canopy_density + 0.2, smoothstep(0.0, 2.0, dist));
    float leaf_mask = smoothstep(current_density, current_density + 0.15, leaf_noise);

    // Fake Subsurface Scattering (Leaves glow yellow-green where thin or near the sun)
    float leaf_thickness = smoothstep(current_density, current_density + 0.4, leaf_noise);
    vec3 leaf_color = mix(leaf_lit_color, leaf_dark_color, leaf_thickness);
    // Add sun glow to leaves near the center
    leaf_color = mix(leaf_color, sun_color, sun_mask * 0.5);


    // 5. COMPOSITION
    vec3 final_color = base_sky;
    
    // Layer leaves over sky
    final_color = mix(final_color, leaf_color, leaf_mask);
    
    // Layer dark trunks over leaves
    final_color = mix(final_color, trunk_color, trunk_mask);
    
    // Darken below the horizon so it blends with your ground
    final_color *= horizon_mask;

    COLOR = final_color;
}