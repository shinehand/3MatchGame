#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/godot_validation_env.sh
validation_require_godot
validation_log="/tmp/puzzle-analytics-contract-validation.log"
validation_stdout="/tmp/puzzle-analytics-contract-validation.stdout"

if ! godot --headless --quiet --path . --log-file "$validation_log" --script res://scripts/validate_analytics_contract.gd >"$validation_stdout" 2>&1; then
  echo "Analytics contract validation failed."
  cat "$validation_stdout"
  exit 1
fi

validation_fail_on_matches "Analytics contract validation" "SCRIPT ERROR:|Parse Error:|Invalid access to property|Cannot call method|Attempt to call function|Analytics contract validation error" "$validation_log" "$validation_stdout"

echo "Analytics contract validation passed."
