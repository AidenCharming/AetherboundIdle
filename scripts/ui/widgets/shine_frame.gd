class_name ShineFrame
extends Control
## A flashy frame for rare, limited-time offers: an animated rainbow-gold border that runs around the card and
## little sparkles that twinkle over it. wrap() puts a card and the frame together; it never takes the mouse.

var radius := 14.0
var width := 3.0
var _t := 0.0
var _sparks: Array = []   # [{pos (0..1), phase, size}]


## The card with the frame laid over its full rect (a container's padding would inset it otherwise).
static func wrap(card: Control, corner := 17.0) -> Control:
	var holder := MarginContainer.new()
	holder.size_flags_horizontal = card.size_flags_horizontal
	holder.add_child(card)
	var f := ShineFrame.new()
	f.radius = corner
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(f)
	return holder


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id()
	for i in 9:
		_sparks.append({"pos": Vector2(rng.randf(), rng.randf()), "phase": rng.randf() * TAU, "size": rng.randf_range(3.0, 7.0)})


func _process(delta: float) -> void:
	if Options.values.get("reduce_motion", false):
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ONE * width * 0.5, size - Vector2.ONE * width)
	# the border: short segments walking round the edge, each hued by where it sits and the time
	var pts := _outline(r, radius, 96)
	var n := pts.size()
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var hue := fposmod(float(i) / n - _t * 0.25, 1.0)
		var col := Color.from_hsv(hue, 0.45, 1.0)
		col = col.lerp(Palette.GOLD, 0.35 + 0.25 * sin(_t * 3.0 + i * 0.2))
		draw_line(a, b, col, width, true)
	# a soft glow line inside the border
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(Palette.GOLD, 0.18 + 0.1 * sin(_t * 2.0)), width * 3.0, true)
	# twinkling four-point sparkles
	for sp in _sparks:
		var k := 0.5 + 0.5 * sin(_t * 2.6 + float(sp.phase))
		if k < 0.25:
			continue
		var p := Vector2(sp.pos.x * size.x, sp.pos.y * size.y)
		var s: float = sp.size * k
		var c := Color(1.0, 0.97, 0.8, k)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 1.6), p + Vector2(s * 0.35, -s * 0.35), p + Vector2(s * 1.6, 0),
			p + Vector2(s * 0.35, s * 0.35), p + Vector2(0, s * 1.6), p + Vector2(-s * 0.35, s * 0.35), p + Vector2(-s * 1.6, 0),
			p + Vector2(-s * 0.35, -s * 0.35)]), c)


## Points round a rounded rectangle, clockwise from the top-left corner's end.
static func _outline(r: Rect2, rad: float, count: int) -> PackedVector2Array:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var out := PackedVector2Array()
	var corners := [[r.position + Vector2(r.size.x - rad, rad), -PI / 2.0], [r.end - Vector2(rad, rad), 0.0],
		[Vector2(r.position.x + rad, r.end.y - rad), PI / 2.0], [r.position + Vector2(rad, rad), PI]]
	var per := int(count / 4.0)
	for c in corners:
		for i in per:
			var ang: float = float(c[1]) + PI / 2.0 * float(i) / float(per - 1)
			out.append(Vector2(c[0]) + Vector2(cos(ang), sin(ang)) * rad)
	return out
