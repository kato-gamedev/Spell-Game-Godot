shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// --- UNIFORMS (Tweak these in the inspector) ---
group_uniforms Colors;
uniform vec3 SandColorLight : source_color = vec3(0.92, 0.83, 0.70);
uniform vec3 SandColorDark : source_color = vec3(0.75, 0.65, 0.50);

group_uniforms ShapesAndDunes;
uniform float MacroScale = 0.2; 
uniform float DuneStrength = 2.0; 
uniform float WindDirection = 0.5; 

group_uniforms Details;
uniform float GrainScale = 150.0; 
uniform float GrainStrength = 0.15; 
uniform float BaseRoughness = 0.85;

// --- PROCEDURAL NOISE FUNCTIONS ---

// 2D Random Hash
vec2 RandomHash(vec2 InputPosition) {
    InputPosition = vec2(dot(InputPosition, vec2(127.1, 311.7)), dot(InputPosition, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(InputPosition) * 43758.5453123);
}

// 2D Perlin Noise
float CalculatePerlinNoise(vec2 InputPosition) {
    vec2 IntegerPosition = floor(InputPosition);
    vec2 FractionalPosition = InputPosition - IntegerPosition;
    vec2 InterpolationWeights = FractionalPosition * FractionalPosition * (3.0 - 2.0 * FractionalPosition);

    return mix(
        mix(dot(RandomHash(IntegerPosition + vec2(0.0, 0.0)), FractionalPosition - vec2(0.0, 0.0)),
            dot(RandomHash(IntegerPosition + vec2(1.0, 0.0)), FractionalPosition - vec2(1.0, 0.0)), InterpolationWeights.x),
        mix(dot(RandomHash(IntegerPosition + vec2(0.0, 1.0)), FractionalPosition - vec2(0.0, 1.0)),
            dot(RandomHash(IntegerPosition + vec2(1.0, 1.0)), FractionalPosition - vec2(1.0, 1.0)), InterpolationWeights.x),
        InterpolationWeights.y);
}

// Fractal Brownian Motion (Layered noise for natural detail)
float CalculateFractalBrownianMotion(vec2 InputPosition) {
    float TotalNoiseValue = 0.0;
    float CurrentAmplitude = 0.5;
    float CurrentFrequency = 1.0;
    
    for(int OctaveIndex = 0; OctaveIndex < 4; OctaveIndex++) {
        TotalNoiseValue += CurrentAmplitude * CalculatePerlinNoise(InputPosition * CurrentFrequency);
        CurrentFrequency *= 2.0;
        CurrentAmplitude *= 0.5;
    }
    
    return TotalNoiseValue;
}

// --- HEIGHT/SHAPE GENERATION ---

// Calculates the physical shape of the sand dunes
float CalculateSandHeight(vec2 WorldCoordinate) {
    // Rotate coordinates to simulate wind direction
    float SineWindDirection = sin(WindDirection);
    float CosineWindDirection = cos(WindDirection);
    mat2 RotationMatrix = mat2(vec2(CosineWindDirection, -SineWindDirection), vec2(SineWindDirection, CosineWindDirection));
    vec2 RotatedPosition = RotationMatrix * WorldCoordinate;

    // Create a wavy base pattern for dunes
    float BaseWavePattern = sin(RotatedPosition.x * 2.0 + CalculateFractalBrownianMotion(WorldCoordinate * 0.5) * 3.0);
    
    // Add layers of noise to make it look like natural, shifting sand
    float DuneShape = BaseWavePattern * 0.5 + 0.5;
    DuneShape = pow(DuneShape, 1.5); // Sharpen the ridges of the dunes
    
    // Add micro-bumps
    float MicroBumps = CalculateFractalBrownianMotion(WorldCoordinate * 5.0) * 0.1;
    
    return (DuneShape + MicroBumps) * DuneStrength;
}

void fragment() {
    // 1. GET WORLD SPACE COORDINATES
    vec3 WorldSpacePosition = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 ScaledPosition = WorldSpacePosition.xz * MacroScale;
    
    // 2. MACRO STRUCTURE (Dunes)
    float TerrainHeight = CalculateSandHeight(ScaledPosition);
    float NormalizedHeight = clamp(TerrainHeight / DuneStrength, 0.0, 1.0);
    
    // 3. MICRO STRUCTURE (Grains)
    float SandGrainNoise = fract(sin(dot(WorldSpacePosition.xz, vec2(12.9898, 78.233))) * 43758.5453);
    
    // 4. COLOR MIXING
    vec3 SurfaceColor = mix(SandColorDark, SandColorLight, NormalizedHeight);
    SurfaceColor += (SandGrainNoise - 0.5) * GrainStrength;
    
    ALBEDO = SurfaceColor;
    
    // 5. PROCEDURAL NORMALS (Lighting)
    vec2 NormalOffset = vec2(0.01, 0.0);
    float CenterHeight = TerrainHeight;
    float OffsetXHeight = CalculateSandHeight(ScaledPosition + NormalOffset.xy);
    float OffsetZHeight = CalculateSandHeight(ScaledPosition + NormalOffset.yx);
    
    // Construct the normal vector based on the height slopes
    vec3 CalculatedNormal = normalize(vec3(CenterHeight - OffsetXHeight, 0.05, CenterHeight - OffsetZHeight));
    
    // Convert from world space normals back to view space
    NORMAL = (VIEW_MATRIX * vec4(CalculatedNormal, 0.0)).xyz;
    
    // 6. ROUGHNESS & SPECULAR
    ROUGHNESS = BaseRoughness + (SandGrainNoise * 0.15);
    SPECULAR = SandGrainNoise * 0.5; 
}