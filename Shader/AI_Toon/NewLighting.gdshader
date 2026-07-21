shader_type spatial;
// Disable standard specular and ambient to take full manual control
render_mode specular_disabled, ambient_light_disabled;

uniform sampler2D albedo_texture : source_color;
uniform vec3 shadow_color : source_color = vec3(0.6, 0.6, 0.75); // A cool blue/purple anime shadow

void fragment() {
    // Treat the texture as the absolute baseline color
    ALBEDO = texture(albedo_texture, UV).rgb;
}

void light() {
    // In Godot, ATTENUATION contains the shadow map data (0.0 = shadow, 1.0 = lit)
    // We ignore dot(NORMAL, LIGHT) completely so the surface doesn't get gradients.
    
    // Instead of adding light, we mix between the shadowed color and the full unlit color
    vec3 shadowed_albedo = ALBEDO * shadow_color;
    
    // Mix based purely on whether a shadow is hitting this pixel
    vec3 final_light = mix(shadowed_albedo, ALBEDO, ATTENUATION);
    
    // In Godot 4, whatever you write to DIFFUSE_LIGHT is the final output of the light pass
    DIFFUSE_LIGHT += final_light; 
}