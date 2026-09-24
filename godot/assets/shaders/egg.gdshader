// A Genesis Pod egg: shell colour, speckles, inner glow hinting at rarity, and cracks for the reveal.
shader_type canvas_item;

uniform vec4 shell : source_color = vec4(0.95, 0.93, 1.0, 1.0);
uniform vec4 spots : source_color = vec4(0.6, 0.5, 1.0, 1.0);
uniform vec4 glow : source_color = vec4(0.5, 0.9, 1.0, 1.0);
uniform float glow_strength = 0.4;
uniform float crack = 0.0;          // 0..1
uniform float flash = 0.0;
uniform float seed = 1.0;

const vec3 INK = vec3(0.137, 0.102, 0.208);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float egg_sdf(vec2 p) {
	// egg: circle stretched upward, narrower at the top
	p.y -= 0.04;
	float k = p.y < 0.0 ? 1.28 : 1.0;
	return length(vec2(p.x * (1.0 + max(-p.y, 0.0) * 0.55), p.y / k)) - 0.3;
}

void fragment() {
	vec2 p = UV - vec2(0.5, 0.52);
	float d = egg_sdf(p);
	float aa = fwidth(d) * 1.2;
	// halo behind the egg
	float halo = exp(-max(d, 0.0) * 14.0) * glow_strength * (0.8 + 0.2 * sin(TIME * 2.5 + seed));
	vec3 col = shell.rgb;
	// soft shading
	col *= 0.78 + 0.3 * smoothstep(0.3, -0.3, p.x * 0.8 + p.y * 0.6);
	// speckles
	for (int i = 0; i < 7; i++) {
		vec2 c = vec2(hash(vec2(float(i), seed)) - 0.5, hash(vec2(seed, float(i) * 1.3)) - 0.5) * vec2(0.42, 0.55);
		float r = 0.025 + 0.03 * hash(vec2(float(i) * 2.1, seed + 3.0));
		col = mix(col, spots.rgb, (1.0 - smoothstep(r - 0.006, r, length(p - c))) * 0.85);
	}
	// inner glow (rarity hint)
	col = mix(col, glow.rgb, smoothstep(0.0, -0.3, d) * glow_strength * 0.55);
	// highlight
	col = mix(col, vec3(1.0), (1.0 - smoothstep(0.0, 0.06, length(p - vec2(-0.1, -0.16)))) * 0.6);
	// crack: a jagged zig-zag across the middle, growing outward from the centre with `crack`,
	// with the inner light glowing through it
	float zig = abs(fract(p.x * 11.0 + seed * 0.37) - 0.5) * 2.0;   // 0..1 triangle wave
	float cy = 0.015 + (zig - 0.5) * 0.07;
	float dist = abs(p.y - cy);
	float reach = crack * 0.34;
	float inside_reach = 1.0 - smoothstep(reach - 0.02, reach, abs(p.x));
	float crackm = (1.0 - smoothstep(0.004, 0.009, dist)) * inside_reach;
	float crack_glow = (1.0 - smoothstep(0.0, 0.03, dist)) * inside_reach * crack;
	col = mix(col, glow.rgb * 1.3 + 0.2, crack_glow * 0.5);
	col = mix(col, INK, crackm);
	col = mix(col, vec3(1.0), flash);
	float fill = 1.0 - smoothstep(-aa, aa, d);
	float outline = 1.0 - smoothstep(-aa, aa, d - 0.018);
	vec3 rgb = mix(INK, col, fill);
	float a = max(outline, clamp(halo, 0.0, 1.0));
	rgb = mix(glow.rgb, rgb, outline);
	COLOR = vec4(rgb, a * COLOR.a);
}
