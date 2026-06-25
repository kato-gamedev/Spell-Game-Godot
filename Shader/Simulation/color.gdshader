shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tex_sim : filter_linear;
uniform sampler2D tex_color : filter_linear;
uniform vec2 resolution;
uniform float time;
uniform vec4 mouse;
uniform vec4 last_mouse;

const float dt = 0.15;

vec3 getPalette(float x, vec3 c1, vec3 c2, vec3 p1, vec3 p2) {
    float x2 = fract(x/2.0);
    x = fract(x);   
    mat3 m = mat3(c1, p1, c2);
    mat3 m2 = mat3(c2, p2, c1);
    float omx = 1.0 - x;
    vec3 pws = vec3(omx*omx, 2.0*omx*x, x*x);
    return clamp(mix(m*pws, m2*pws, step(x2, 0.5)), 0.0, 1.0);
}

vec4 pal(float x) {
    vec3 p = getPalette(-x, vec3(0.2, 0.5, 0.7), vec3(0.9, 0.4, 0.1), vec3(1.0, 1.2, 0.5), vec3(1.0, -0.4, 0.0));
    return vec4(p, 1.0);
}

vec4 pal2(float x) {
    vec3 p = getPalette(-x, vec3(0.4, 0.3, 0.5), vec3(0.9, 0.75, 0.4), vec3(0.1, 0.8, 1.3), vec3(1.25, -0.1, 0.1));
    return vec4(p, 1.0);
}

vec2 point1(float t) {
    t *= 0.62;
    return vec2(0.12, 0.5 + sin(t)*0.2);
}

vec2 point2(float t) {
    t *= 0.62;
    return vec2(0.88, 0.5 + cos(t + 1.5708)*0.2);
}

void fragment() {
    vec2 uv = UV;
    vec2 w = 1.0 / resolution;
    vec2 mo = mouse.xy * w;
    vec2 last_mo = last_mouse.xy * w;
    
    vec2 velo = textureLod(tex_sim, uv, 0.0).xy;
    vec4 col = textureLod(tex_color, uv - dt * velo * w * 3.0, 0.0); // advection
    
    // Mouse Interaction
    if (mouse.z > 0.5 && last_mouse.z > 0.5) {
        float str = smoothstep(-0.5, 1.0, length(mo - last_mo));   
        col += str * 0.0009 / (pow(length(uv - mo), 1.7) + 0.002) * pal2(-time * 0.7);
    }
    
    // Points injection
    col += 0.0025 / (0.0005 + pow(length(uv - point1(time)), 1.75)) * dt * 0.12 * pal(time * 0.05);
    col += 0.0025 / (0.0005 + pow(length(uv - point2(time)), 1.75)) * dt * 0.12 * pal2(time * 0.05 + 0.675);
    
    // Clear buffer at start
    if (time < 0.2) col = vec4(0.0);
    
    col = clamp(col, 0.0, 5.0);
    col = max(col - (0.0001 + col * 0.004) * 0.5, 0.0); // decay
    
    COLOR = col;
}