shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// EXPORTED VARIABLES (Uniforms)
uniform vec3 MARBLE_COLOR_LIGHT : source_color = vec3(0.88, 0.86, 0.83);
uniform vec3 MARBLE_COLOR_DARK : source_color = vec3(0.65, 0.63, 0.60);
uniform vec3 SAND_COLOR : source_color = vec3(0.85, 0.65, 0.40);
uniform float BLOCK_SCALE = 4.0;
uniform float MARBLE_VEIN_SCALE = 0.8;
uniform float SAND_AMOUNT : hint_range(0.0, 1.0) = 0.6;

uniform vec3 MORTAR_COLOR : source_color = vec3(0.15, 0.15, 0.15);
uniform float MORTAR_THICKNESS : hint_range(0.0, 0.2) = 0.02;
uniform float MORTAR_OPACITY : hint_range(0.0, 1.0) = 0.85;

// NEW: EXPORTED VARIABLES FOR DEPTH & BUMP
uniform float BUMP_STRENGTH : hint_range(0.0, 5.0) = 2.0;
uniform float MORTAR_DEPTH : hint_range(0.0, 1.0) = 0.8;
uniform float VEIN_BUMP_STRENGTH : hint_range(0.0, 1.0) = 0.15;

varying vec3 WorldPosition;
varying vec3 WorldNormal;

// Math functions (variables inside use standard lowercase per instructions)
float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	
	return mix(mix(mix(hash(i + vec3(0.0,0.0,0.0)), hash(i + vec3(1.0,0.0,0.0)), f.x),
				   mix(hash(i + vec3(0.0,1.0,0.0)), hash(i + vec3(1.0,1.0,0.0)), f.x), f.y),
			   mix(mix(hash(i + vec3(0.0,0.0,1.0)), hash(i + vec3(1.0,0.0,1.0)), f.x),
				   mix(hash(i + vec3(0.0,1.0,1.0)), hash(i + vec3(1.0,1.0,1.0)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += amp * noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return val;
}

void vertex() {
	vec4 WorldMatrixPos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	WorldPosition = WorldMatrixPos.xyz;
	WorldNormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// 1. Generate the large stone blocks
	vec3 BlockCoord = WorldPosition / BLOCK_SCALE;
	
	BlockCoord.x += floor(BlockCoord.y) * 0.5;
	BlockCoord.z += floor(BlockCoord.y) * 0.5;
	
	vec3 BlockId = floor(BlockCoord);
	vec3 BlockFract = fract(BlockCoord);
	
	vec3 EdgeDist = min(BlockFract, 1.0 - BlockFract);
	float EdgeMin = min(min(EdgeDist.x, EdgeDist.y), EdgeDist.z);
	
	float MortarLine = smoothstep(MORTAR_THICKNESS * 0.5, MORTAR_THICKNESS, EdgeMin);
	float MortarMask = 1.0 - MortarLine;

	// 2. Generate the Marble Texture
	vec3 NoiseCoord = WorldPosition * MARBLE_VEIN_SCALE;
	float MarbleBaseNoise = fbm(NoiseCoord);
	float MarbleVeinNoise = fbm(NoiseCoord * 2.5 + vec3(MarbleBaseNoise * 3.0));
	
	vec3 StoneAlbedo = mix(MARBLE_COLOR_DARK, MARBLE_COLOR_LIGHT, MarbleVeinNoise);
	
	float BlockRandomOffset = hash(BlockId);
	StoneAlbedo += (BlockRandomOffset * 0.1 - 0.05);
	
	vec3 MortarMixedColor = mix(StoneAlbedo, MORTAR_COLOR, MORTAR_OPACITY);
	StoneAlbedo = mix(StoneAlbedo, MortarMixedColor, MortarMask);

	// 3. Desert Sand Accumulation
	float UpwardFactor = dot(WorldNormal, vec3(0.0, 1.0, 0.0));
	float SandDustNoise = fbm(WorldPosition * 4.0);
	float BlendedSandCoverage = UpwardFactor + (SandDustNoise * 0.5 - 0.25);
	float SandMask = smoothstep(1.0 - SAND_AMOUNT, 1.1 - SAND_AMOUNT, BlendedSandCoverage);

	// 4. Combine Albedo and PBR
	vec3 FinalAlbedo = mix(StoneAlbedo, SAND_COLOR, SandMask);
	float StoneRoughness = mix(0.3, 0.5, MarbleVeinNoise); 
	float FinalRoughness = mix(StoneRoughness, 0.95, SandMask);

	ALBEDO = FinalAlbedo;
	ROUGHNESS = FinalRoughness;
	SPECULAR = mix(0.5, 0.05, SandMask); 
	
	// 5. AMBIENT OCCLUSION (Fixing flatness by darkening crevices)
	float CavityAO = 1.0 - (MortarMask * MORTAR_DEPTH);
	CavityAO = mix(CavityAO, 1.0, SandMask); // If sand fills the crack, remove the darkness
	AO = CavityAO;
	
	// 6. PROCEDURAL BUMP MAPPING (Fixing flatness by changing how light bounces)
	// Calculate a virtual height map based on our masks
	float SurfaceHeight = (MarbleVeinNoise * VEIN_BUMP_STRENGTH) - (MortarMask * MORTAR_DEPTH);
	SurfaceHeight = mix(SurfaceHeight, SandMask * 0.1, SandMask); // Sand adds a slight bump over the stone
	
	// Get the screen-space derivatives of the world position and our fake height
	vec3 DPdx = dFdx(WorldPosition);
	vec3 DPdy = dFdy(WorldPosition);
	float DHdx = dFdx(SurfaceHeight);
	float DHdy = dFdy(SurfaceHeight);
	
	// Push the geometry gradients outward based on the height
	vec3 BumpedDPdx = DPdx + WorldNormal * DHdx * BUMP_STRENGTH;
	vec3 BumpedDPdy = DPdy + WorldNormal * DHdy * BUMP_STRENGTH;
	
	// Cross-product the new gradients to get the final 3D bump normal
	vec3 BumpedNormal = normalize(cross(BumpedDPdx, BumpedDPdy));
	
	// Ensure the normal doesn't face backwards (fixes winding order glitches)
	if (dot(BumpedNormal, WorldNormal) < 0.0) {
		BumpedNormal = -BumpedNormal;
	}
	
	// Godot expects NORMAL to be in View Space, so we multiply it by the VIEW_MATRIX
	NORMAL = (VIEW_MATRIX * vec4(BumpedNormal, 0.0)).xyz;
}