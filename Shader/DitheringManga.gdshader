shader_type canvas_item;

// Reads the screen behind the ColorRect
uniform sampler2D ScreenTexture : hint_screen_texture, filter_nearest;

// Scale of the dots. Keep above 1.0 for a stylized comic/halftone look.
uniform float PatternScale : hint_range(0.1, 10.0) = 2.0;

// How dark the dots are. 0.0 = invisible, 1.0 = pitch black dots.
uniform float DitherStrength : hint_range(0.0, 1.0) = 0.4;

// Controls where the dots appear. 
// Higher = dots cover more of the screen. Lower = dots only appear in deep shadows.
uniform float DitherThresholdOffset : hint_range(-1.0, 1.0) = 0.1;

float GetBayerDither(vec2 ScreenPosition) {
    mat4 BayerMatrix = mat4(
        vec4(0.0 / 16.0, 12.0 / 16.0,  3.0 / 16.0, 15.0 / 16.0),
        vec4(8.0 / 16.0,  4.0 / 16.0, 11.0 / 16.0,  7.0 / 16.0),
        vec4(2.0 / 16.0, 14.0 / 16.0,  1.0 / 16.0, 13.0 / 16.0),
        vec4(10.0 / 16.0,  6.0 / 16.0,  9.0 / 16.0,  5.0 / 16.0)
    );
    
    int X = int(mod(ScreenPosition.x, 4.0));
    int Y = int(mod(ScreenPosition.y, 4.0));
    
    return BayerMatrix[X][Y];
}

void fragment() {
    // Read the actual smooth colors from the 3D game
    vec4 InputTexture = texture(ScreenTexture, SCREEN_UV);
    vec3 BaseColor = InputTexture.rgb;
    
    // Calculate the brightness (luminance) of the current pixel
    float Luminance = dot(BaseColor, vec3(0.299, 0.587, 0.114));
    
    // Get the dither pattern value for this screen pixel
    vec2 ScaledScreen = FRAGCOORD.xy / PatternScale;
    float BayerValue = GetBayerDither(ScaledScreen);
    
    // Adjust brightness based on user preference
    float AdjustedLuminance = clamp(Luminance + DitherThresholdOffset, 0.0, 1.0);
    
    // Create a mask: 0.0 means "draw a dot", 1.0 means "keep original brightness"
    float DitherMask = step(BayerValue, AdjustedLuminance);
    
    // Instead of banding colors, we just darken the base color where dots appear.
    // This creates stylized texture over smooth colors!
    vec3 ShadowColor = BaseColor * (1.0 - DitherStrength);
    vec3 FinalColor = mix(ShadowColor, BaseColor, DitherMask);
    
    COLOR = vec4(FinalColor, 1.0);
}