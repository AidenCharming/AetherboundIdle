// Creature sprite: per-type shiny recolour, Aether-Log silhouettes and a white flash for reveals.
//
// Shinies use a gradient map instead of a hue rotation: each pixel's brightness picks a colour on the
// type's three-stop shiny palette (data/types.json "shiny"), and the result is blended back with a little
// of the original so shading, blush and eye highlights survive. The dark outline is left untouched.
shader_type canvas_item;

uniform float shiny = 0.0;            // 0 or 1
uniform vec4 pal_dark : source_color = vec4(0.1, 0.1, 0.3, 1.0);
uniform vec4 pal_mid : source_color = vec4(0.4, 0.5, 1.0, 1.0);
uniform vec4 pal_light : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform float silhouette = 0.0;       // 1 = solid silhouette
uniform vec4 silhouette_color : source_color = vec4(0.23, 0.25, 0.47, 1.0);
uniform float flash = 0.0;            // 0..1 white flash
uniform float shimmer = 0.0;          // shiny sparkle sweep strength
// Rarity effects (data/rarities.json "fx"), all following the sprite's own outline:
// 1-2 outline glow, 3 + a sweeping shine, 4 + the glow pulses, 5 rainbow edge, body shimmer, rising motes.
uniform float fx = 0.0;
uniform vec4 fx_color : source_color = vec4(1.0, 0.85, 0.4, 1.0);

vec3 hue(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

float hash1(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// how much sprite is nearby (0..1): the alpha around this pixel, for a glow outside the outline
float near_alpha(sampler2D tex, vec2 uv, float r) {
	float a = 0.0;
	for (int i = 0; i < 12; i++) {
		float ang = float(i) * 0.5236;
		vec2 d = vec2(cos(ang), sin(ang));
		a = max(a, texture(tex, uv + d * r).a * 0.55);
		a = max(a, texture(tex, uv + d * r * 0.5).a * 0.8);
		a = max(a, texture(tex, uv + d * r * 0.25).a);
	}
	return a;
}

vec3 gradient_map(float l) {
	return l < 0.5 ? mix(pal_dark.rgb, pal_mid.rgb, l * 2.0) : mix(pal_mid.rgb, pal_light.rgb, (l - 0.5) * 2.0);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec3 rgb = c.rgb;
	if (shiny > 0.5) {
		float l = dot(rgb, vec3(0.299, 0.587, 0.114));
		float mx = max(rgb.r, max(rgb.g, rgb.b));
		float mn = min(rgb.r, min(rgb.g, rgb.b));
		float sat = mx - mn;
		// stretch the brightness range a little so the palette's ends are reached
		float t = clamp((l - 0.08) / 0.84, 0.0, 1.0);
		vec3 mapped = gradient_map(t);
		// keep the ink outline, near-white highlights and a trace of the original detail
		float keep_outline = 1.0 - smoothstep(0.06, 0.2, l);
		float keep_white = smoothstep(0.86, 0.97, l) * (1.0 - smoothstep(0.05, 0.2, sat));
		float amount = (1.0 - keep_outline) * (1.0 - keep_white) * 0.88;
		rgb = mix(rgb, mapped, amount);
	}
	if (shimmer > 0.0) {
		float band = sin((UV.x + UV.y) * 9.0 - TIME * 2.4);
		rgb += pal_light.rgb * 0.35 * smoothstep(0.93, 1.0, band) * shimmer;
	}
	float out_a = c.a;
	if (fx > 0.5 && silhouette < 0.5) {
		vec3 fc = fx > 4.5 ? hue(TIME * 0.18 + (UV.x + UV.y) * 0.5) * 0.7 + 0.3 : fx_color.rgb;
		float pulse = fx > 3.5 ? 0.7 + 0.3 * sin(TIME * 3.0) : 1.0;
		// glow just outside the outline
		// the glow's reach is a share of the sprite, so it reads the same at any size
		float r = 0.012 + 0.004 * fx;
		float near = near_alpha(TEXTURE, UV, r);
		float glow = near * (1.0 - c.a) * min(0.95, 0.45 + 0.1 * fx) * pulse;
		// a band of light sweeping across the body every few seconds
		if (fx > 2.5) {
			float sweep = fract(TIME * 0.28);
			float d = abs((UV.x * 0.8 + UV.y * 0.4) - (sweep * 2.2 - 0.4));
			rgb += vec3(1.0, 0.97, 0.9) * smoothstep(0.07, 0.0, d) * 0.45 * c.a;
		}
		// Zenith: a soft rainbow sheen over the body and motes rising around it
		if (fx > 4.5) {
			rgb = mix(rgb, rgb * 0.75 + hue(TIME * 0.12 + UV.y * 0.8) * 0.35, 0.22 * c.a);
			for (int i = 0; i < 7; i++) {
				float fi = float(i);
				float y = 1.0 - fract(TIME * (0.12 + hash1(fi) * 0.1) + hash1(fi + 3.1));
				vec2 m = vec2(0.12 + 0.76 * hash1(fi + 9.7), y);
				float md = length((UV - m) * vec2(1.0, 1.0));
				float life = sin(y * 3.14159);
				float mote = smoothstep(0.03, 0.0, md) * life;
				glow = max(glow, mote * (1.0 - c.a) * 0.9);
				fc = mix(fc, hue(TIME * 0.2 + fi * 0.14) * 0.6 + 0.4, mote * (1.0 - c.a));
			}
		}
		rgb = mix(fc, rgb, c.a);
		out_a = max(c.a, glow);
	}
	rgb = mix(rgb, silhouette_color.rgb, silhouette);
	rgb = mix(rgb, vec3(1.0), flash);
	COLOR = vec4(rgb, out_a * COLOR.a);
}
