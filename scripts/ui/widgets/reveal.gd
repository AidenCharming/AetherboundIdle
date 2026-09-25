class_name Reveal
extends Control
## The hatch and evolution reveals. Eggs wobble and crack with a build-up that grows with rarity, then a
## flash in the rarity colour, light rays and a burst of sparks, and the creature pops out. Reveals queue
## up (hatch-all, eggs that finished while away) and play one after another; click to continue.

const RAYS := preload("res://assets/shaders/rays.gdshader")

var active := false
var _queue: Array = []
var _dim: ColorRect
var _rays: ColorRect
var _rays_mat: ShaderMaterial
var _stage: Control
var _flash: ColorRect
var _caption: VBoxContainer
var _hint: Label
var _can_continue := false
var _particles: CPUParticles2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.01, 0.05, 0.86)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_rays = ColorRect.new()
	_rays_mat = ShaderMaterial.new()
	_rays_mat.shader = RAYS
	_rays.material = _rays_mat
	_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rays)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 90
	_particles.lifetime = 1.4
	_particles.explosiveness = 0.95
	_particles.spread = 180.0
	_particles.initial_velocity_min = 216.0
	_particles.initial_velocity_max = 624.0
	_particles.gravity = Vector2(0, 312)
	_particles.damping_min = 48.0
	_particles.damping_max = 108.0
	_particles.scale_amount_min = 3.6
	_particles.scale_amount_max = 8.4
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	_particles.color_ramp = grad
	add_child(_particles)
	_caption = UI.vbox(7)
	_caption.alignment = BoxContainer.ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)
	_hint = UI.label("Click to continue", "Faint")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


func enqueue(kind: String, data: Dictionary) -> void:
	_queue.append({"kind": kind, "data": data})
	if not active:
		_next()


func _layout() -> void:
	var vs := size
	var center := vs / 2.0 - Vector2(0, 60)
	_rays.size = Vector2(1080, 1080)
	_rays.position = center - _rays.size / 2.0
	_stage.position = center
	_particles.position = center
	_caption.position = Vector2(0, center.y + 180)
	_caption.size = Vector2(vs.x, 240)
	_hint.position = Vector2(0, vs.y - 72)
	_hint.size = Vector2(vs.x, 36)


func _next() -> void:
	if _queue.is_empty():
		_close()
		return
	var item: Dictionary = _queue.pop_front()
	active = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_can_continue = false
	_hint.visible = false
	UI.clear(_stage)
	UI.clear(_caption)
	_layout()
	_rays_mat.set_shader_parameter("intensity", 0.0)
	modulate.a = 1.0
	if _dim.color.a < 0.5:
		pass
	match item.kind:
		"hatch":
			_play_hatch(item.data)
		"evolve":
			_play_evolve(item.data)
		_:
			_next()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _can_continue:
		accept_event()
		Sfx.play("click")
		_next()


func _unhandled_input(event: InputEvent) -> void:
	if active and _can_continue and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_next()


func _close() -> void:
	active = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		visible = false
		modulate.a = 1.0
		UI.clear(_stage)
		UI.clear(_caption))


func _motion() -> bool:
	return not Options.get_value("reduce_motion")


# ---------------------------------------------------------------- hatch

func _play_hatch(res: Dictionary) -> void:
	var egg: Dictionary = res.egg
	var c: Dictionary = res.creature
	var rarity := int(c.rarity)
	var rc := Data.rarity_color(rarity)
	var ev := EggView.make(egg, 360)
	ev.position = Vector2(-180, -180)
	ev.pivot_offset = Vector2(180, 180)
	_stage.add_child(ev)
	_rays_mat.set_shader_parameter("ray_color", Data.rarity_color(int(egg.get("shell", rarity))))
	var tw := create_tween()
	tw.tween_method(func(v): _rays_mat.set_shader_parameter("intensity", v), 0.0, 0.25, 0.5)
	# build-up: more wobbles and a longer wait the rarer the egg
	var wobbles := 2 + int(ceil(rarity / 2.0))
	for i in wobbles:
		var amp := deg_to_rad(6.0 + i * 3.0) if _motion() else 0.0
		var sp := maxf(0.05, 0.11 - i * 0.008)
		tw.tween_property(ev, "rotation", amp, sp).set_trans(Tween.TRANS_SINE)
		tw.tween_property(ev, "rotation", -amp, sp * 2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(ev, "rotation", 0.0, sp).set_trans(Tween.TRANS_SINE)
		var crack := float(i + 1) / wobbles * 0.9
		tw.tween_callback(func():
			ev.set_crack(crack)
			Sfx.play("crack", 1.0 + i * 0.08))
		tw.tween_interval(0.28 if i < wobbles - 1 else 0.45)
	tw.tween_method(func(v): ev.set_flash(v), 0.0, 1.0, 0.25)
	tw.tween_callback(func():
		ev.queue_free()
		_burst(rc, rarity)
		_show_creature(c, rc)
		_hatch_caption(c, res.events))


func _hatch_caption(c: Dictionary, events: Array) -> void:
	var sp: Dictionary = Data.species[c.species]
	var is_new := events.any(func(e): return e.type == "discovered")
	var is_recipe := events.any(func(e): return e.type == "recipe")
	if is_new:
		var tag := "NEW SPECIES" if not is_recipe else ("SECRET RECIPE DISCOVERED" if sp.kind == "special" else "NEW HYBRID")
		var nl := UI.label(tag, "H3", Palette.GOLD)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_caption.add_child(nl)
	elif events.any(func(e): return e.type == "rarity_logged"):
		var new_rl := UI.label("NEW RARITY: " + Data.rarity(int(c.rarity)).name.to_upper(), "H3", Data.rarity_color(int(c.rarity)))
		new_rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_caption.add_child(new_rl)
	var title_lbl := UI.label(Data.form_name(c.species, 1), "Title")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_outline_color", Palette.INK)
	title_lbl.add_theme_constant_override("outline_size", 12)
	_caption.add_child(title_lbl)
	var line := "%s%s · %s" % ["Shiny " if c.shiny else "", Data.rarity(int(c.rarity)).name, " / ".join(sp.types.map(func(t): return Data.types[t].name))]
	var rl := UI.label(line, "H2", Data.rarity_color(int(c.rarity)))
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_child(rl)
	var traits: Array = c.traits.map(func(t): return "%s (%s)" % [Data.traits[t.id].name, Traits.strength_label(t.s)])
	var tl := UI.label("Traits: " + (", ".join(traits) if not traits.is_empty() else "none yet"), "Dim")
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_child(tl)
	_pop_caption()
	Sfx.play("hatch", 1.0 + (int(c.rarity) - 1) * 0.03)


# ---------------------------------------------------------------- evolution

func _play_evolve(e: Dictionary) -> void:
	var c := GameState.creature(Game.state, e.creature)
	if c.is_empty():
		_next()
		return
	var old := CreaturePortrait.make(e.species, int(e.from), int(c.rarity), bool(c.shiny), 360)
	old.plate = false
	old.position = Vector2(-180, -180)
	_stage.add_child(old)
	_rays_mat.set_shader_parameter("ray_color", Palette.AETHER)
	var tw := create_tween()
	tw.tween_method(func(v): _rays_mat.set_shader_parameter("intensity", v), 0.0, 0.35, 0.6)
	for i in 5:
		tw.tween_method(func(v): old.set_flash(v), 0.0, 0.85, 0.16 - i * 0.02)
		tw.tween_method(func(v): old.set_flash(v), 0.85, 0.1, 0.16 - i * 0.02)
	tw.tween_method(func(v): old.set_flash(v), 0.0, 1.0, 0.2)
	tw.tween_callback(func():
		old.queue_free()
		var rc := Data.rarity_color(int(c.rarity))
		_burst(Palette.AETHER, 5)
		var shown := c.duplicate()
		_show_creature(shown, rc)
		var head := UI.label("EVOLUTION", "H3", Palette.AETHER)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_caption.add_child(head)
		var title_lbl := UI.label("%s became %s!" % [Data.form_name(e.species, int(e.from)), Data.form_name(e.species, int(e.form))], "H1")
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_caption.add_child(title_lbl)
		var desc: String = Data.species[e.species].forms[int(e.form) - 1].get("desc", "")
		if desc != "":
			var dl := UI.label(desc, "Dim")
			dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_caption.add_child(dl)
		_pop_caption()
		Sfx.play("evolve"))


# ---------------------------------------------------------------- shared

func _burst(color: Color, rarity: int) -> void:
	var fc := Color(color, 0.0)
	var tw := create_tween()
	_flash.color = fc
	tw.tween_property(_flash, "color:a", 0.75 if rarity >= 4 else 0.5, 0.06)
	tw.tween_property(_flash, "color:a", 0.0, 0.5)
	_particles.color = color.lightened(0.3)
	_particles.amount = 60 + rarity * 20
	_particles.restart()
	_particles.emitting = true
	var rtw := create_tween()
	rtw.tween_method(func(v): _rays_mat.set_shader_parameter("intensity", v), 1.2, 0.55 + rarity * 0.04, 0.8)
	_rays_mat.set_shader_parameter("ray_color", color)
	if rarity >= 5 and Options.get_value("screen_shake") and _motion():
		var host: Control = get_parent()
		var st := create_tween()
		for i in 8:
			st.tween_property(host, "position", Vector2(randf_range(-11, 11), randf_range(-8, 8)) * (1.0 - i / 8.0), 0.04)
		st.tween_property(host, "position", Vector2.ZERO, 0.04)


func _show_creature(c: Dictionary, _rc: Color) -> void:
	var p := CreaturePortrait.of(c, 360)
	p.plate = false
	p.position = Vector2(-180, -180)
	p.pivot_offset = Vector2(180, 180)
	p.scale = Vector2(0.2, 0.2)
	_stage.add_child(p)
	var tw := create_tween()
	tw.tween_property(p, "scale", Vector2(1.12, 1.12), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "scale", Vector2.ONE, 0.2)
	if c.get("shiny", false):
		for i in 10:
			var sp := UI.icon(Data.ui_icon("shiny"), 36)
			sp.position = Vector2(randf_range(-204, 180), randf_range(-204, 168))
			sp.modulate.a = 0.0
			_stage.add_child(sp)
			var st := sp.create_tween().set_loops(3)
			st.tween_property(sp, "modulate:a", 1.0, 0.3).set_delay(randf() * 0.6)
			st.tween_property(sp, "modulate:a", 0.0, 0.4)


func _pop_caption() -> void:
	_caption.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.35).set_delay(0.2)
	tw.tween_callback(func():
		_can_continue = true
		_hint.text = "Click to continue" + ("  (%d more)" % _queue.size() if not _queue.is_empty() else "")
		_hint.visible = true)
