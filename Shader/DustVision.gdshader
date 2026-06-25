shader_type spatial;
// Unshaded is required so the post-process isn't affected by scene lighting
render_mode unshaded, fog_disabled, depth_test_disabled;

uniform sampler2D ScreenTexture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DepthTexture : hint_depth_texture, filter_nearest;

uniform vec3 DustColor : source_color = vec3(0.85, 0.45, 0.15);
uniform float FogDensity : hint_range(0.0, 5.0) = 1.5;
uniform float Desaturation : hint_range(0.0, 1.0) = 0.7;
uniform float GrainIntensity : hint_range(0.0, 1.0) = 0.15;
uniform float EmissiveThreshold : hint_range(0.0, 2.0) = 1.2;

float RandomNoise(vec2 UvCoordinates, float TimeValue) {
	return fract(sin(dot(UvCoordinates + TimeValue, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	// This forces the quad to stretch over the entire screen,
	// completely ignoring camera position and rotation.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec4 BaseColor = texture(ScreenTexture, SCREEN_UV);
	float RawDepth = texture(DepthTexture, SCREEN_UV).x;

	// 1. Linearize Depth (Automatically un-projects using the camera's matrix)
	vec3 NormalizedDeviceCoordinates = vec3(SCREEN_UV * 2.0 - 1.0, RawDepth);
	vec4 ViewSpacePosition = INV_PROJECTION_MATRIX * vec4(NormalizedDeviceCoordinates, 1.0);
	ViewSpacePosition.xyz /= ViewSpacePosition.w;
	float LinearDepth = -ViewSpacePosition.z;

	// Scale depth down for mathematical fog falloff
	float DepthFactor = LinearDepth / 100.0;

	// 2. Calculate "DUSTEYES" Highlight (Glowing objects pierce the fog)
	float Luminance = dot(BaseColor.rgb, vec3(0.299, 0.587, 0.114));
	float PiercingFactor = step(EmissiveThreshold, Luminance);

	// 3. Desaturate the foreground to make it look "Dull"
	vec3 TintedColor = mix(BaseColor.rgb, Luminance * DustColor, Desaturation);

	// 4. Calculate Depth Fog
	// Reduce fog density where PiercingFactor is high (monster eyes)
	float EffectiveDepth = DepthFactor * (1.0 - (PiercingFactor * 0.8));
	float FogFactor = exp2(-FogDensity * FogDensity * EffectiveDepth * EffectiveDepth * 10.0);
	FogFactor = clamp(FogFactor, 0.0, 1.0);

	// 5. Blend Screen with Blinding Dust
	vec3 FinalColor = mix(DustColor, TintedColor, FogFactor);

	// 6. Add Animated Sand Grain
	float NoiseValue = RandomNoise(SCREEN_UV, TIME);
	FinalColor += (NoiseValue - 0.5) * GrainIntensity;

	// 7. Add Squint/Goggle Vignette
	vec2 ScreenDistance = SCREEN_UV - vec2(0.5);
	float VignetteValue = 1.0 - dot(ScreenDistance, ScreenDistance) * 1.5;
	FinalColor *= smoothstep(0.0, 1.0, VignetteValue);

	// Output to screen
	ALBEDO = FinalColor;
}