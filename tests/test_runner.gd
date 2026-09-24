extends Node
## Headless test runner. Runs every tests/test_*.gd: each public method named test_* is one test.
## Usage (from the repo root):  godot --headless --path godot res://tests/test_runner.tscn
## Exit code 0 when everything passes, 1 otherwise.

var failures: Array = []
var current := ""
var asserts := 0


func _ready() -> void:
	var files := DirAccess.get_files_at("res://tests")
	var total := 0
	var started := Time.get_ticks_msec()
	for f in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")) or f == "test_runner.gd":
			continue
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			# a test file that does not compile is a failure, not a hang
			failures.append("%s: does not compile" % f)
			print("  FAIL  ", f, " (does not compile)")
			continue
		var suite: Object = script.new()
		suite.set("t", self)
		for m in suite.get_method_list():
			var test_name: String = m.name
			if not test_name.begins_with("test_"):
				continue
			current = "%s::%s" % [f.get_basename(), test_name]
			var before := failures.size()
			suite.call(test_name)
			total += 1
			if failures.size() == before:
				print("  ok    ", current)
			else:
				print("  FAIL  ", current)
	print("\n%d tests, %d assertions, %d failures (%d ms)" % [total, asserts, failures.size(), Time.get_ticks_msec() - started])
	for f in failures:
		print("  - ", f)
	get_tree().quit(0 if failures.is_empty() else 1)


func ok(cond: bool, msg := "") -> void:
	asserts += 1
	if not cond:
		failures.append("%s: %s" % [current, msg])


func eq(a: Variant, b: Variant, msg := "") -> void:
	asserts += 1
	if not (a == b or (typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT] and is_equal_approx(float(a), float(b)))):
		failures.append("%s: expected %s, got %s %s" % [current, str(b), str(a), msg])


func near(a: float, b: float, tol: float, msg := "") -> void:
	asserts += 1
	if absf(a - b) > tol:
		failures.append("%s: expected %s ± %s, got %s %s" % [current, b, tol, a, msg])
