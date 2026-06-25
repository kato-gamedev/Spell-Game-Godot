shader_type spatial;

uniform sampler2D uNoiseTexture;
uniform vec2 uScrollSpeed = vec2(1.0, 1.0);

void vertex() {
	vec2 moving_uv = vec2(VERTEX.x, VERTEX.z) + (TIME * uScrollSpeed);
	vec4 Noise = texture(uNoiseTexture, moving_uv);
	VERTEX.y = Noise.y / 2.0;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
