class_name AchievementTile
extends Button
## One achievement on the Achievements page: its painting in a tier frame (bronze, silver, gold; violet for a
## secret), the name, and what to do (or the hint of a secret still hidden), with a progress bar until earned.

const ART := 176
const TIER_COLORS := [Color("a07ef0"), Color("c98a4b"), Color("c9d3e0"), Color("f2c14e")]   # secret, bronze, silver, gold

var a: Dictionary
var _bar: ProgressBar
var _count: Label


static func make(achievement: Dictionary) -> AchievementTile:
	var tile := AchievementTile.new()
	tile.a = achievement
	return tile


static func frame_color(achievement: Dictionary) -> Color:
	return TIER_COLORS[0 if achievement.get("secret", false) else clampi(int(achievement.tier), 1, 3)]


## A locked secret shows only its hint: no name, no painting.
static func hidden(achievement: Dictionary) -> bool:
	return achievement.get("secret", false) and not Achievements.is_unlocked(Game.state, achievement.id)


func _ready() -> void:
	theme_type_variation = "Tile"
	custom_minimum_size = Vector2(ART + 28, 318)
	tooltip_text = ""
	var done := Achievements.is_unlocked(Game.state, a.id)
	var v := UI.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP]:
		v.set_offset(side, 14)
	for side in [SIDE_RIGHT, SIDE_BOTTOM]:
		v.set_offset(side, -14)
	add_child(v)
	var art := FramedArt.new()
	art.a = a
	art.custom_minimum_size = Vector2(ART, ART)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(art)
	var title := UI.label("???" if hidden(a) else a.name, "", Palette.TEXT if done else Palette.TEXT_DIM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.custom_minimum_size.x = ART
	v.add_child(title)
	var desc := UI.wrap_label(a.hint if hidden(a) else a.text, "Faint" if hidden(a) else "Dim", ART)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	v.add_child(desc)
	v.add_child(UI.spacer())
	if done:
		var got := UI.label("Earned " + date_text(int(Game.state.achievements.unlocked[a.id])), "Faint", Palette.GOLD)
		got.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(got)
	elif not hidden(a):
		_bar = UI.bar(frame_color(a), 8)
		v.add_child(_bar)
		_count = UI.label("", "Faint")
		_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_count.add_theme_font_size_override("font_size", 13)
		v.add_child(_count)
		update_progress()
	pressed.connect(func(): AchievementTile.detail(a))


func update_progress() -> void:
	if _bar == null:
		return
	var p := Achievements.progress(Game.state, a)
	_bar.max_value = maxf(1.0, float(p[1]))
	_bar.value = float(p[0])
	_count.text = "%s / %s" % [F.format_num(float(p[0])), F.format_num(float(p[1]))]


static func date_text(unix: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return Time.get_date_string_from_unix_time(unix + bias)


## The big view: the painting at full size, the text, the reward and when it was earned.
static func detail(achievement: Dictionary) -> Modal:
	var done := Achievements.is_unlocked(Game.state, achievement.id)
	var v := UI.vbox(14)
	var art := FramedArt.new()
	art.a = achievement
	art.custom_minimum_size = Vector2(420, 420)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(art)
	var cat: String = {"skills": "Skills", "nexus": "Aetherlings & Nexus", "adventure": "Adventure", "breeding": "Breeding",
		"secret": "Secret"}[achievement.category]
	var tier: String = "Secret" if achievement.get("secret", false) else ["", "Bronze", "Silver", "Gold"][clampi(int(achievement.tier), 1, 3)]
	v.add_child(UI.hbox(8, [UI.chip(cat, Palette.AETHER), UI.chip(tier, frame_color(achievement))]))
	v.add_child(UI.wrap_label(achievement.hint if hidden(achievement) else achievement.text, "Dim", 420))
	var r: Dictionary = achievement.reward
	var reward := UI.hbox(12, [UI.label("Reward:", "Faint")])
	for k in ["aether", "gold"]:
		if r.has(k):
			reward.add_child(UI.amount(k, float(r[k])))
	if r.has("title"):
		reward.add_child(UI.label("Title: “%s”" % ("???" if hidden(achievement) else r.title), "", Palette.GOLD))
	v.add_child(reward)
	if done:
		v.add_child(UI.label("Earned on " + date_text(int(Game.state.achievements.unlocked[achievement.id])), "Dim", Palette.GOLD))
	elif not hidden(achievement):
		var p := Achievements.progress(Game.state, achievement)
		v.add_child(UI.label("Progress: %s / %s" % [F.format_num(float(p[0])), F.format_num(float(p[1]))], "Dim"))
	return Modal.open(v, "???" if hidden(achievement) else achievement.name, 520.0)


## The painting in its tier frame: an ink line, the tier's colour band with a highlight, diamond studs on the corners
## and a soft vignette. Dimmed and greyed until earned; a locked secret is a "?" on violet. The island clears show
## their island's battle backdrop, framed as a trophy picture: a victory pennant on top, the island's name on a ribbon.
class FramedArt extends Control:
	var a: Dictionary

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var col := AchievementTile.frame_color(a)
		var done := Achievements.is_unlocked(Game.state, a.id)
		var island: bool = str(a.art).begins_with("zone:")
		var band := maxf(4.0, size.x * 0.035)
		var inner := r.grow(-band)
		if AchievementTile.hidden(a):
			draw_rect(r, Color(0.16, 0.12, 0.3))
			var font := get_theme_default_font()
			var fs := int(size.y * 0.5)
			var sz := font.get_string_size("?", HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			draw_string(font, Vector2((size.x - sz.x) / 2.0, size.y * 0.5 + fs * 0.35), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col.darkened(0.2))
		else:
			var tex := Data.achievement_icon(a)
			if tex:
				draw_texture_rect(tex, inner, false, Color.WHITE if done else Color(0.42, 0.42, 0.5))
			_vignette(inner, 0.45 if island else 0.3)
			if not done:
				draw_rect(inner, Color(0.05, 0.05, 0.14, 0.35))
		var c := col if done else col.darkened(0.45)
		# the frame: ink outside, the tier band, a thin highlight inside it, an ink line against the picture
		draw_rect(r.grow(-1.0), Palette.INK, false, 2.0)
		draw_rect(r.grow(-band / 2.0 - 1.0), c, false, band - 2.0)
		draw_rect(r.grow(-2.5), c.lightened(0.35), false, 1.0)
		draw_rect(inner.grow(0.5), Palette.INK, false, 1.5)
		for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
			_diamond(corner + (r.get_center() - corner).sign() * band * 0.5, band * 1.15, c)
		if island and not AchievementTile.hidden(a):
			_pennant(Vector2(size.x / 2.0, band), band, c)
			_ribbon(Data.zones[str(a.art).substr(5)].name, c)

	func _diamond(at: Vector2, rad: float, c: Color) -> void:
		var pts := PackedVector2Array([at + Vector2(0, -rad), at + Vector2(rad, 0), at + Vector2(0, rad), at + Vector2(-rad, 0)])
		draw_colored_polygon(pts, c)
		pts.append(pts[0])
		draw_polyline(pts, Palette.INK, 1.5, true)
		draw_circle(at + Vector2(-rad * 0.25, -rad * 0.25), rad * 0.18, Color(1, 1, 1, 0.7))

	## Darker edges, so the frame sits on the picture and the middle reads first.
	func _vignette(box: Rect2, strength: float) -> void:
		var steps := 8
		var depth := box.size.x * 0.14
		for i in steps:
			var k := float(i) / steps
			var w := depth * (1.0 - k) / steps
			var col := Color(0.02, 0.02, 0.08, strength * (1.0 - k) * (1.0 - k) * 0.45)
			var b := box.grow(-depth * k)
			draw_rect(Rect2(b.position, Vector2(b.size.x, w)), col)
			draw_rect(Rect2(Vector2(b.position.x, b.end.y - w), Vector2(b.size.x, w)), col)
			draw_rect(Rect2(b.position, Vector2(w, b.size.y)), col)
			draw_rect(Rect2(Vector2(b.end.x - w, b.position.y), Vector2(w, b.size.y)), col)

	## A little victory flag on a pole, planted on the top of the frame.
	func _pennant(foot: Vector2, band: float, c: Color) -> void:
		var h := band * 3.2
		draw_line(foot, foot + Vector2(0, -h * 0.2) + Vector2(0, h), Palette.INK, 2.0)
		var top := foot + Vector2(0, band * 0.2)
		var flag := PackedVector2Array([top, top + Vector2(h * 0.9, h * 0.28), top + Vector2(0, h * 0.56)])
		draw_colored_polygon(flag, c.lightened(0.15))
		flag.append(flag[0])
		draw_polyline(flag, Palette.INK, 1.5, true)

	## The island's name on a ribbon across the bottom of the picture.
	func _ribbon(text: String, c: Color) -> void:
		var font := get_theme_default_font()
		var fs := int(clampf(size.y * 0.075, 11.0, 28.0))
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var w := minf(size.x * 0.9, tw + fs * 2.0)
		var hgt := fs * 1.6
		var y := size.y * 0.8
		var x0 := (size.x - w) / 2.0
		var tail := hgt * 0.45
		for side in [-1.0, 1.0]:
			var ex: float = x0 if side < 0.0 else x0 + w
			var pts := PackedVector2Array([Vector2(ex, y + hgt * 0.2), Vector2(ex + side * tail * 1.4, y + hgt * 0.2),
				Vector2(ex + side * tail, y + hgt * 0.7), Vector2(ex + side * tail * 1.4, y + hgt * 1.2), Vector2(ex, y + hgt * 1.2)])
			draw_colored_polygon(pts, c.darkened(0.35))
			pts.append(pts[0])
			draw_polyline(pts, Palette.INK, 1.5, true)
		var body := Rect2(x0, y, w, hgt)
		draw_rect(body, c)
		draw_rect(body, Palette.INK, false, 1.5)
		draw_line(body.position + Vector2(3, 3), Vector2(body.end.x - 3, body.position.y + 3), c.lightened(0.4), 1.0)
		draw_string(font, Vector2(x0, y + hgt * 0.5 + fs * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, Palette.INK)
