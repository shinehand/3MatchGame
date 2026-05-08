#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/godot_validation_env.sh
validation_require_godot
validation_log="/tmp/puzzle-liveops-config-validation.log"
validation_stdout="/tmp/puzzle-liveops-config-validation.stdout"

rm -f "$validation_log" "$validation_stdout"
if ! godot --headless --quiet --path . --log-file "$validation_log" --script res://scripts/validate_liveops_config.gd >"$validation_stdout" 2>&1; then
  echo "LiveOps config validation failed."
  cat "$validation_stdout"
  exit 1
fi
touch "$validation_log" "$validation_stdout"

validation_fail_on_matches "LiveOps config validation" "SCRIPT ERROR:|Parse Error:|Invalid access to property|Cannot call method|Attempt to call function|LiveOps config validation error" "$validation_log" "$validation_stdout"

echo "LiveOps config validation passed."
