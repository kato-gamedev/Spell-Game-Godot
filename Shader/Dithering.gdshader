shader_type canvas_item;

// This allows us to read the pixels behind the ColorRect
uniform sampler2D ScreenTexture : hint_screen_texture, filter_nearest;

uniform float ColorBands : hint_range(1.0, 32.0) = 6.0;
uniform float DitherSpread : hint_range(0.0, 1.0) = 0.3;
uniform float PatternScale : hint_range(1.0, 10.0) = 2.0;

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
    // Read from the screen behind the ColorRect, NOT the ColorRect itself
    vec4 InputTexture = texture(ScreenTexture, SCREEN_UV);
    vec3 BaseColor = InputTexture.rgb;

    vec2 ScaledScreen = FRAGCOORD.xy / PatternScale;
    float DitherThreshold = GetBayerDither(ScaledScreen);

    vec3 BandedColor = floor(BaseColor * ColorBands) / ColorBands;
    vec3 NextBand = ceil(BaseColor * ColorBands) / ColorBands;
    vec3 BandProgress = fract(BaseColor * ColorBands);

    BandProgress = clamp((BandProgress - 0.5) / max(DitherSpread, 0.001) + 0.5, 0.0, 1.0);

    vec3 FinalColor;
    FinalColor.r = BandProgress.r > DitherThreshold ? NextBand.r : BandedColor.r;
    FinalColor.g = BandProgress.g > DitherThreshold ? NextBand.g : BandedColor.g;
    FinalColor.b = BandProgress.b > DitherThreshold ? NextBand.b : BandedColor.b;

    COLOR = vec4(FinalColor, 1.0);
}