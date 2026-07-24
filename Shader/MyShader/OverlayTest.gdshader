shader_type spatial;
// "unshaded" is crucial here! The base material already computed the lighting. 
// If we don't use unshaded, the mesh will receive lighting twice and look washed out.
render_mode unshaded;

// Expose the screen texture so we can read what was rendered before this overlay
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// A color to tint the mesh with (you can change this in the inspector)
uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Default Red

void fragment() {
    // 1. GET THE COLOR: Read the screen at the exact pixel this overlay is rendering on
    // Because this mesh just rendered its base material, this grabs the base material's output!
    vec3 base_color = texture(screen_texture, SCREEN_UV).rgb;
    
    // 2. MODIFY IT: Here are a few ways to modify the color (uncomment the one you want)
    
    // Modification A: Tint it (Multiply)
    vec3 final_color = base_color * tint_color.rgb;
    
    // Modification B: Invert the colors
    // vec3 final_color = vec3(1.0) - base_color;
    
    // Modification C: Make it Grayscale
    // float gray = (base_color.r + base_color.g + base_color.b) / 3.0;
    // vec3 final_color = vec3(gray);

    // 3. OUTPUT: Set the final color
    ALBEDO = final_color;
}