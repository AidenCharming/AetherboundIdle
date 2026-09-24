// Animated night sky: deep gradient, drifting nebula and twinkling stars. Tinted per screen.
shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.03, 0.035, 0.09, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.07, 0.07, 0.19, 1.0);
uniform vec4 nebula_a : source_color = vec4(0.25, 0.2, 0.7, 1.0);
uniform vec4 nebula_b : source_color = vec4(0.1, 0.55, 0.7, 1.0);
uniform float nebula_strength = 0.35;
uniform float star_density = 1.0;
uniform vec2 aspect = vec2(1.78, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void fragment() {
	vec2 uv = UV * aspect;
	vec3 col = mix(top_color.rgb, bottom_color.rgb, UV.y);
	float t = TIME * 0.015;
	float n = fbm(uv * 1.6 + vec2(t, -t * 0.5));
	float n2 = fbm(uv * 2.4 - vec2(t * 0.7, t));
	col += nebula_a.rgb * smoothstep(0.45, 0.9, n) * nebula_strength;
	col += nebula_b.rgb * smoothstep(0.5, 0.95, n2) * nebula_strength * 0.8;
	// stars on a grid, one per cell, twinkling
	for (int layer = 0; layer < 2; layer++) {
		float scale = layer == 0 ? 60.0 : 130.0;
		vec2 g = uv * scale;
		vec2 cell = floor(g);
		float h = hash(cell + float(layer) * 17.0);
		if (h > 1.0 - 0.08 * star_density) {
			vec2 pos = vec2(hash(cell + 3.1), hash(cell + 7.7));
			float d = length(fract(g) - pos);
			float tw = 0.55 + 0.45 * sin(TIME * (1.0 + h * 3.0) + h * 40.0);
			float size = layer == 0 ? 0.09 : 0.06;
			col += vec3(0.85, 0.9, 1.0) * smoothstep(size, 0.0, d) * tw * (layer == 0 ? 0.9 : 0.5);
		}
	}
	COLOR = vec4(col, 1.0);
}
