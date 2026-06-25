shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec3 sand_color : source_color = vec3(0.9, 0.75, 0.3);
uniform float fall_speed = 20.0;
uniform float base_pixel_resolution = 30.0; // How tiny the pixels are up close
uniform float density = 0.3;

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void fragment() {
    // 1. Calculate how far away the camera is from this pixel
    // In Godot, length(VERTEX) in the fragment shader gives the exact distance to the camera!
    float dist_to_camera = length(VERTEX);

    // 2. DYNAMIC RESOLUTION (The Fix)
    // If the camera is far away, we lower the resolution (making the 3D blocks bigger).
    // The "0.1" controls how fast they grow when you zoom out. Adjust this if needed!
    float dynamic_res = base_pixel_resolution / max(1.0, dist_to_camera * 0.2);

    // 3. Pixelate using the dynamic resolution instead of a static one
    vec3 voxel_pos = floor(world_pos * dynamic_res);
    voxel_pos.y += floor(TIME * fall_speed);

    float noise = hash(voxel_pos);

    if (noise > density) {
        discard;
    }

    float color_variation = (hash(voxel_pos + vec3(1.0)) - 0.5) * 0.2;
    ALBEDO = sand_color + vec3(color_variation);
}