shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tex_sim : filter_linear;
uniform vec2 resolution;
uniform float time;
uniform vec4 mouse;
uniform vec4 last_mouse;

const float dt = 0.15;
const float VORTICITY_AMOUNT = 0.11;

float mag2(vec2 p){ return dot(p,p); }

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
    
    vec4 data = textureLod(tex_sim, uv, 0.0);
    vec4 tr = textureLod(tex_sim, uv + vec2(w.x, 0.0), 0.0);
    vec4 tl = textureLod(tex_sim, uv - vec2(w.x, 0.0), 0.0);
    vec4 tu = textureLod(tex_sim, uv + vec2(0.0, w.y), 0.0);
    vec4 td = textureLod(tex_sim, uv - vec2(0.0, w.y), 0.0);
    
    vec3 dx = (tr.xyz - tl.xyz) * 0.5;
    vec3 dy = (tu.xyz - td.xyz) * 0.5;
    vec2 densDif = vec2(dx.z, dy.z);
    
    data.z -= dt * dot(vec3(densDif, dx.x + dy.y), data.xyz); // density
    vec2 laplacian = tu.xy + td.xy + tr.xy + tl.xy - 4.0 * data.xy;
    vec2 viscForce = vec2(0.55) * laplacian;
    
    data.xyw = textureLod(tex_sim, uv - dt * data.xy * w, 0.0).xyw; // advection
    
    vec2 newForce = vec2(0.0);
    newForce.xy += 0.75 * vec2(0.0003, 0.00015) / (mag2(uv - point1(time)) + 0.0001);
    newForce.xy -= 0.75 * vec2(0.0003, 0.00015) / (mag2(uv - point2(time)) + 0.0001);
    
    if (mouse.z > 0.5 && last_mouse.z > 0.5) {
        vec2 vv = clamp((mouse.xy * w - last_mouse.xy * w) * 400.0, vec2(-6.0), vec2(6.0));
        newForce.xy += 0.001 / (mag2(uv - mouse.xy * w) + 0.001) * vv;
    }
    
    data.xy += dt * (viscForce.xy - 0.2 / dt * densDif + newForce); // update velocity
    data.xy = max(vec2(0.0), abs(data.xy) - 1e-4) * sign(data.xy); // linear velocity decay
    
    // Vorticity confinement
    data.w = (tr.y - tl.y - tu.x + td.x);
    vec2 vort = vec2(abs(tu.w) - abs(td.w), abs(tl.w) - abs(tr.w));
    vort *= VORTICITY_AMOUNT / (length(vort) + 1e-9) * data.w;
    data.xy += vort;
    
    data.y *= smoothstep(0.5, 0.48, abs(uv.y - 0.5)); // Boundaries
    data = clamp(data, vec4(-10.0, -10.0, 0.5, -10.0), vec4(10.0, 10.0, 3.0, 10.0));
    
    // Clear buffer at start
    if (time < 0.2) {
        data = vec4(0.5, 0.0, 0.0, 0.0);
    }
    COLOR = data;
}