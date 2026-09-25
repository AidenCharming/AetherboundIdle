extends Node
## Headless test runner. Runs every tests/test_*.gd: each public method named test_* is one test.
## Usage (from the repo root):  godot --headless --path . res://tests/test_runner.tscn < /dev/null
## Exit code 0 when everything passes, 1 otherwise. Not with --debug: a script error there stops at a debugger
## prompt forever. Warnings only print with --debug, so check them with the load-only mode, which runs no code:
##   godot --headless --debug --path . res://tests/test_runner.tscn -- --warnings < /dev/null

var failures: Array = []
var current := ""
var asserts := 0
var _errors := ErrorCounter.new()


## Counts script errors and push_errors from game code. A runtime error aborts the test it happens in without adding a failure, so the runner
## compares the count before and after each test (and each load) instead.
class ErrorCounter extends Logger:
	var count := 0
	var last := ""
	var warnings: Array[String] = []
	var expected: Array[String] = []   # error texts the current test triggers on purpose

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			warnings.append("%s (%s:%d)" % [rationale if rationale != "" else code, file, line])
		elif error_type == ERROR_TYPE_SCRIPT or (error_type == ERROR_TYPE_ERROR and function == "push_error"):
			# a push_error from game code fails the test too (engine messages, like the headless shader
			# compiler's, don't), unless the test said it expects it
			var text := rationale if rationale != "" else code
			if expected.any(func(e): return e in text):
				return
			count += 1
			last = "%s (%s:%d in %s)" % [text, file, line, function]


func _ready() -> void:
	var files := DirAccess.get_files_at("res://tests")
	var total := 0
	var started := Time.get_ticks_msec()
	OS.add_logger(_errors)
	if "--warnings" in OS.get_cmdline_user_args():
		_check_warnings()
		return
	for f in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")) or f == "test_runner.gd":
			continue
		var errors_before := _errors.count
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate() or _errors.count > errors_before:
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
			var errors_before_test := _errors.count
			_errors.expected.clear()
			suite.call(test_name)
			if _errors.count > errors_before_test:
				failures.append("%s: script error: %s" % [current, _errors.last])
			total += 1
			if failures.size() == before:
				print("  ok    ", current)
			else:
				print("  FAIL  ", current)
	print("\n%d tests, %d assertions, %d failures (%d ms)" % [total, asserts, failures.size(), Time.get_ticks_msec() - started])
	for f in failures:
		print("  - ", f)
	get_tree().quit(0 if failures.is_empty() else 1)


## Loads (compiles) every script without running any, and fails on any warning.
func _check_warnings() -> void:
	var paths: Array[String] = []
	for dir in ["res://scripts", "res://tests", "res://tools"]:
		_collect_scripts(dir, paths)
	# the autoloads and every class they use are compiled before the logger is added, so a plain load() would
	# return the cached script and its warnings would never reach the logger: compile each one afresh
	# (not this runner itself: a fresh copy of the running script replaces it mid-call)
	for p in paths:
		if p != get_script().resource_path:
			ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_IGNORE)
	print("
%d scripts loaded, %d warnings" % [paths.size(), _errors.warnings.size()])
	for w in _errors.warnings:
		print("  - ", w)
	get_tree().quit(0 if _errors.warnings.is_empty() else 1)


func _collect_scripts(dir: String, into: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			into.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_collect_scripts(dir.path_join(d), into)


## For a test that triggers an error on purpose: an error containing `text` doesn't fail it.
func expect_error(text: String) -> void:
	_errors.expected.append(text)


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
