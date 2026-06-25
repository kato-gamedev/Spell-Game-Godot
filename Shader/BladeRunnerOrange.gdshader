shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// --- COLORS (Matched to the movie reference) ---
group_uniforms Colors;
uniform vec3 DustColorBright : source_color = vec3(0.85, 0.40, 0.08); // Vibrant orange dust
uniform vec3 DustColorDark : source_color = vec3(0.50, 0.15, 0.02);   // Deep reddish brown for crevices

group_uniforms TerrainFeatures;
uniform float OverallScale = 0.5;
uniform float StreakStrength = 0.4;
uniform float ClumpStrength = 0.15;
uniform float WindDirection = -0.2; // Rotates the wind streaks

group_uniforms Textures;
// We only need ONE noise texture. The shader will reuse it to save memory.
uniform sampler2D NoiseTexture : repeat_enable, filter_linear_mipmap;

// --- HEIGHT CALCULATION ---
float CalculateGroundHeight(vec2 WorldCoordinate) {
    // Rotate coordinates to match wind direction
    float SineWind = sin(WindDirection);
    float CosineWind = cos(WindDirection);
    mat2 RotationMatrix = mat2(vec2(CosineWind, -SineWind), vec2(SineWind, CosineWind));
    vec2 RotatedPosition = RotationMatrix * WorldCoordinate;

    // 1. MACRO UNEVENNESS (Broad rolling shapes)
    float BaseCrust = texture(NoiseTexture, WorldCoordinate * 0.02).r;

    // 2. WIND STREAKS (Stretching the texture severely on one axis)
    vec2 StreakCoordinates = vec2(RotatedPosition.x * 0.05, RotatedPosition.y * 0.8);
    float WindStreaks = texture(NoiseTexture, StreakCoordinates).r;
    // Sharpen the streaks to look like accumulated sand ridges
    WindStreaks = pow(WindStreaks, 2.0) * StreakStrength;

    // 3. DIRT CLUMPS & ROCKS (High frequency, tiny scale)
    float DirtClumps = texture(NoiseTexture, WorldCoordinate * 0.5).r;
    DirtClumps = pow(DirtClumps, 4.0) * ClumpStrength; // Pow 4 makes them isolated specks

    // Combine them all into the final physical height
    return BaseCrust * 0.2 + WindStreaks + DirtClumps;
}

void fragment() {
    // 1. WORLD COORDINATES
    vec3 WorldSpacePosition = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 ScaledPosition = WorldSpacePosition.xz * OverallScale;

    // 2. CALCULATE HEIGHT
    float TerrainHeight = CalculateGroundHeight(ScaledPosition);

    // Normalize height to figure out where the shadows/peaks are
    float NormalizedHeight = clamp(TerrainHeight * 1.5, 0.0, 1.0);

    // 3. COLOR
    // Lower areas (streaks/crevices) get the dark red, raised areas get the bright orange
    vec3 SurfaceColor = mix(DustColorDark, DustColorBright, NormalizedHeight);

    ALBEDO = SurfaceColor;

    // 4. PROCEDURAL NORMALS (For realistic lighting on the streaks/clumps)
    vec2 NormalOffset = vec2(0.02, 0.0);
    float CenterHeight = TerrainHeight;
    float OffsetXHeight = CalculateGroundHeight(ScaledPosition + NormalOffset.xy);
    float OffsetZHeight = CalculateGroundHeight(ScaledPosition + NormalOffset.yx);

    vec3 CalculatedNormal = normalize(vec3(CenterHeight - OffsetXHeight, 0.02, CenterHeight - OffsetZHeight));
    NORMAL = (VIEW_MATRIX * vec4(CalculatedNormal, 0.0)).xyz;

    // 5. ROUGHNESS
    // The Blade Runner ground is completely matte/dry dust. Very high roughness.
    ROUGHNESS = 0.95;
    SPECULAR = 0.05;
}