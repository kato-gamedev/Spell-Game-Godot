shader_type canvas_item;

// Captures the screen behind this CanvasItem
uniform sampler2D ScreenTexture : hint_screen_texture, filter_linear_mipmap;

// The GradientTexture1D for your color palette
uniform sampler2D ColorPalette : source_color, filter_linear;

// --- Useful Parameters ---

// Controls how much of the color palette is applied (0.0 = original, 1.0 = fully graded)
uniform float PaletteBlend : hint_range(0.0, 1.0) = 0.5;

// Toggle for how the gradient is applied:
// true = Maps overall screen brightness to the gradient (Usually looks BEST for stylized themes like Blade Runner)
// false = Maps RGB channels individually (Behaves exactly like default Godot WorldEnvironment)
uniform bool MapByLuminance = true;

// Emulating WorldEnvironment Adjustment settings (1.0 is neutral)
uniform float Brightness : hint_range(0.0, 4.0) = 1.0;
uniform float Contrast : hint_range(0.0, 4.0) = 1.0;
uniform float Saturation : hint_range(0.0, 4.0) = 1.0;

void fragment() {
    // 1. Get the original screen pixel color
    vec4 OriginalColor = texture(ScreenTexture, SCREEN_UV);
    vec3 AdjustedColor = OriginalColor.rgb;

    // 2. Apply Brightness
    AdjustedColor *= Brightness;

    // 3. Apply Contrast
    AdjustedColor = (AdjustedColor - vec3(0.5)) * Contrast + vec3(0.5);

    // 4. Apply Saturation (Using Rec. 709 Luma coefficients)
    float Luma = dot(AdjustedColor, vec3(0.2126, 0.7152, 0.0722));
    AdjustedColor = mix(vec3(Luma), AdjustedColor, Saturation);

    // Clamp to ensure we don't sample outside the gradient boundaries
    AdjustedColor = clamp(AdjustedColor, vec3(0.0), vec3(1.0));

    // 5. Apply the Color Palette
    vec3 GradedColor;

    if (MapByLuminance) {
        // Luminance Mapping: Best for unified thematic palettes.
        // Re-calculate Luma in case Brightness/Contrast/Saturation changed it
        float FinalLuma = dot(AdjustedColor, vec3(0.2126, 0.7152, 0.0722));
        GradedColor = texture(ColorPalette, vec2(FinalLuma, 0.5)).rgb;
    } else {
        // Per-Channel Mapping: Godot's default WorldEnvironment behavior.
        GradedColor.r = texture(ColorPalette, vec2(AdjustedColor.r, 0.5)).r;
        GradedColor.g = texture(ColorPalette, vec2(AdjustedColor.g, 0.5)).g;
        GradedColor.b = texture(ColorPalette, vec2(AdjustedColor.b, 0.5)).b;
    }

    // 6. Final Blend
    // Mix between the adjusted image and the color-graded image
    vec3 FinalColor = mix(AdjustedColor, GradedColor, PaletteBlend);

    COLOR = vec4(FinalColor, OriginalColor.a);
}