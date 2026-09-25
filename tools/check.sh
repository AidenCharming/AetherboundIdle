#!/usr/bin/env bash
# Imports the project and runs the headless test suite. Usage: tools/check.sh [path-to-godot]
set -e
cd "$(dirname "$0")/.."
GODOT="${1:-${GODOT:-godot}}"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --debug --path . res://tests/test_runner.tscn < /dev/null
