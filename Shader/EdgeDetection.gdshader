shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float thickness : hint_range(0.0, 0.5) = 0.05;
uniform float edge_sharpness : hint_range(0.0, 0.1) = 0.01;

void fragment() {
    // Get the distance from the edges using UV coordinates
    // This works perfectly for Godot's default CubeMesh
    vec2 uv = UV;
    
    // Calculate how close we are to any edge (0.0 or 1.0)
    float edge_x = min(uv.x, 1.0 - uv.x);
    float edge_y = min(uv.y, 1.0 - uv.y);
    float closest_edge = min(edge_x, edge_y);
    
    // Create the line mask using smoothstep for anti-aliasing
    float mask = 1.0 - smoothstep(thickness - edge_sharpness, thickness, closest_edge);
        ALBEDO = outline_color.rgb;
    ALPHA = mask * outline_color.a;
}