// Rotating light rays for hatch and evolution reveals.
shader_type canvas_item;

uniform vec4 ray_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform float intensity = 1.0;
uniform float count = 14.0;
uniform float speed = 0.25;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float a = atan(p.y, p.x) + TIME * speed;
	float r = length(p);
	float rays = pow(0.5 + 0.5 * sin(a * count), 6.0);
	float fade = smoothstep(0.5, 0.05, r);
	float core = exp(-r * 9.0);
	COLOR = vec4(ray_color.rgb, clamp((rays * 0.6 + core) * fade * intensity, 0.0, 1.0));
}
