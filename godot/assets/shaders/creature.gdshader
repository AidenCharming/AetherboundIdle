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
	rgb = mix(rgb, silhouette_color.rgb, silhouette);
	rgb = mix(rgb, vec3(1.0), flash);
	COLOR = vec4(rgb, c.a * COLOR.a);
}
