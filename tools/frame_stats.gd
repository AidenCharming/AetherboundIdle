extends SceneTree
## Frame-to-frame change for Movie Maker clips (used by `bridge.py run ... --movie`).
##   godot --headless --path . --script res://tools/frame_stats.gd -- LIST.txt OUT.json
## LIST.txt holds one PNG path per line, in order. For each frame this writes how much it differs from the
## one before (mean absolute difference per channel, 0..1, on a 160x90 thumbnail) and its mean brightness.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- LIST.txt OUT.json")
		quit(2)
		return
	var paths := FileAccess.get_file_as_string(args[0]).split("\n", false)
	var out := []
	var prev := PackedByteArray()
	for path in paths:
		var img := Image.load_from_file(path.strip_edges())
		if img == null or img.is_empty():
			out.append({"path": path, "error": "unreadable"})
			prev = PackedByteArray()
			continue
		img.convert(Image.FORMAT_RGB8)
		img.resize(160, 90, Image.INTERPOLATE_BILINEAR)
		var data := img.get_data()
		var lum := 0
		for i in data.size():
			lum += data[i]
		var diff := -1.0
		if prev.size() == data.size():
			var d := 0
			for i in data.size():
				d += absi(int(data[i]) - int(prev[i]))
			diff = d / (255.0 * data.size())
		out.append({"path": path, "diff": diff, "lum": lum / (255.0 * data.size())})
		prev = data
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit(0)
