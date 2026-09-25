// Flattens a glossy painted button icon: the coloured face's brightness and saturation are pulled toward one
// value, which takes out the gradient and the white specular highlight. Dark outlines/rims (low value) and
// warm parts (the cream cross, outside `hue_min..hue_max`) keep their paint.
shader_type canvas_item;

uniform float flatness : hint_range(0.0, 1.0) = 0.8;   // 0 = as painted, 1 = one flat colour on the face
uniform float face_value = 0.72;                       // the face's flat brightness
uniform float face_sat = 0.62;                         // the face's flat saturation
uniform float hue_min = 0.62;                          // the face's hues (violet by default)
uniform float hue_max = 0.86;
uniform float brighten = 1.0;                          // hover: > 1 lifts the whole icon

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec3 hsv = rgb2hsv(col.rgb);
	// on the face: the right hue and not a dark outline or rim
	float face = step(hue_min, hsv.x) * step(hsv.x, hue_max) * smoothstep(0.32, 0.45, hsv.z);
	vec3 flat_hsv = vec3(hsv.x, mix(hsv.y, face_sat, flatness), mix(hsv.z, face_value, flatness));
	vec3 rgb = mix(col.rgb, hsv2rgb(flat_hsv), face);
	COLOR = vec4(rgb * brighten, col.a) * COLOR;
}
