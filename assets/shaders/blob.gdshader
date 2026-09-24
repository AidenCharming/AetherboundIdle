// Placeholder for Aetherlings without art yet (the hybrids): a soft two-colour aether blob with a face.
// Drawn on purpose in the sprites' outlined style so it reads as "sketch pending", not as broken art.
shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(0.4, 0.8, 0.5, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform float form = 1.0;             // 1..3: bigger crest and more sparkle with each form
uniform float silhouette = 0.0;
uniform vec4 silhouette_color : source_color = vec4(0.23, 0.25, 0.47, 1.0);
uniform float flash = 0.0;
uniform float seed = 0.0;

const vec3 INK = vec3(0.137, 0.102, 0.208);

float body_sdf(vec2 p, float t) {
	// squashed circle with a soft wobble along the rim
	float ang = atan(p.y, p.x);
	float wob = 0.018 * sin(ang * 5.0 + t * 1.7 + seed) + 0.012 * sin(ang * 3.0 - t * 1.3);
	vec2 q = p * vec2(1.0, 1.12);
	return length(q) - (0.34 + wob);
}

void fragment() {
	vec2 p = UV - vec2(0.5, 0.56);
	float t = TIME;
	float d = body_sdf(p, t);
	// crest: one to three little flame-leaf tufts on top
	float crest = 1e5;
	for (int i = 0; i < 3; i++) {
		if (float(i) >= form) break;
		float x = (float(i) - (form - 1.0) * 0.5) * 0.11;
		vec2 c = p - vec2(x, -0.36 - 0.02 * float(form));
		c.x += 0.02 * sin(t * 2.0 + float(i));
		float tuft = length(c * vec2(1.6, 0.9)) - 0.07;
		crest = min(crest, tuft);
	}
	float shape = min(d, crest);
	float aa = fwidth(shape) * 1.2;
	float fill = 1.0 - smoothstep(-aa, aa, shape);
	float outline = 1.0 - smoothstep(-aa, aa, shape - 0.022);
	// two-colour swirl
	float swirl = 0.5 + 0.5 * sin(atan(p.y, p.x) * 2.0 + length(p) * 14.0 - t * 0.8 + seed);
	vec3 col = mix(color_a.rgb, color_b.rgb, smoothstep(0.25, 0.75, swirl));
	if (crest < d) { col = mix(color_b.rgb, vec3(1.0), 0.15); }
	// shading and highlight
	col *= 0.85 + 0.35 * smoothstep(0.3, -0.3, p.y + p.x * 0.3);
	float hl = 1.0 - smoothstep(0.0, 0.07, length(p - vec2(-0.13, -0.14)));
	col = mix(col, vec3(1.0), hl * 0.55);
	// face: two eyes with highlights, blush
	vec2 e1 = p - vec2(-0.1, 0.02);
	vec2 e2 = p - vec2(0.1, 0.02);
	float blink = step(0.97, fract(t * 0.23 + seed * 0.1));
	float ey = mix(1.0, 8.0, blink);
	float eye = min(length(e1 * vec2(1.0, ey)), length(e2 * vec2(1.0, ey))) - 0.045;
	float eyem = 1.0 - smoothstep(-aa, aa, eye);
	col = mix(col, INK, eyem);
	float shine = min(length(e1 - vec2(-0.015, -0.018)), length(e2 - vec2(-0.015, -0.018))) - 0.014;
	col = mix(col, vec3(1.0), (1.0 - smoothstep(-aa, aa, shine)) * (1.0 - blink));
	float blush = min(length((p - vec2(-0.19, 0.1)) * vec2(1.0, 1.8)), length((p - vec2(0.19, 0.1)) * vec2(1.0, 1.8))) - 0.04;
	col = mix(col, vec3(1.0, 0.55, 0.65), (1.0 - smoothstep(-0.02, 0.02, blush)) * 0.45);
	// mouth
	vec2 m = p - vec2(0.0, 0.1);
	float mouth = abs(length(m - vec2(0.0, -0.03)) - 0.035) - 0.008;
	mouth = max(mouth, -m.y + 0.0);
	col = mix(col, INK, (1.0 - smoothstep(-aa, aa, mouth)) * 0.9);
	vec3 rgb = mix(INK, col, fill);
	rgb = mix(rgb, silhouette_color.rgb, silhouette);
	rgb = mix(rgb, vec3(1.0), flash);
	COLOR = vec4(rgb, outline * COLOR.a);
}
