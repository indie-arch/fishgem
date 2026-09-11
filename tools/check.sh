#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot_bin="${GODOT:-godot}"
"$godot_bin" --headless --path . --editor --import
test_log="$(mktemp)"
trap 'rm -f "$test_log"' EXIT
for test in tests/*_test.gd; do
  # Assertions can leave a SceneTree running, so CI must bound each test.
  timeout 120 "$godot_bin" --headless --path . --script "res://$test" 2>&1 | tee "$test_log"
  if grep -Eq "SCRIPT ERROR:|^ERROR:" "$test_log"; then
    exit 1
  fi
done
