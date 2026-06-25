shader_type spatial;
// blend_add makes it glow like light. unshaded ignores scene shadows.
render_mode blend_add, depth_draw_opaque, unshaded;

// Expose variables to the Godot Inspector
uniform vec4 aura_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);
uniform float emission_strength = 2.0;
uniform sampler2D noise_texture;
uniform vec2 scroll_speed = vec2(0.1, 0.2);

// Function to calculate Fresnel (Edge glow)
float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void fragment() {
    // 1. Calculate the Fresnel effect
    // 3.0 is the sharpness. Higher = thinner edge glow.
    float edge_glow = fresnel(3.0, NORMAL, VIEW);

    // 2. Animate a noise texture to give it movement
    vec2 moving_uv = UV + (TIME * scroll_speed);
    float noise = texture(noise_texture, moving_uv).r;

    // 3. Combine Fresnel and Noise for the final transparency (Alpha)
    float final_alpha = edge_glow * noise;

    // 4. Apply colors and glowing emission
    ALBEDO = aura_color.rgb;
    EMISSION = aura_color.rgb * emission_strength;
    ALPHA = final_alpha;
}