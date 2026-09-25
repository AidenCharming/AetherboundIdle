#!/usr/bin/env bash
# Imports the project, runs the headless test suite, then checks every script for warnings. Usage: tools/check.sh [path-to-godot]
# The tests run without --debug (with it, a script error stops at a debugger prompt forever); warnings only print
# with --debug, so the second pass loads every script in that mode without running any.
set -e
cd "$(dirname "$0")/.."
GODOT="${1:-${GODOT:-godot}}"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . res://tests/test_runner.tscn < /dev/null
"$GODOT" --headless --debug --path . res://tests/test_runner.tscn -- --warnings < /dev/null
