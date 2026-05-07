#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/godot_validation_env.sh
validation_require_godot
validation_log="/tmp/puzzle-stage-balance-validation.log"
validation_stdout="/tmp/puzzle-stage-balance-validation.stdout"

if ! godot --headless --quiet --path . --log-file "$validation_log" --script res://scripts/validate_stage_balance.gd >"$validation_stdout" 2>&1; then
  echo "Stage balance validation failed."
  cat "$validation_stdout"
  exit 1
fi

validation_fail_on_matches "Stage balance validation" "SCRIPT ERROR:|Parse Error:|Invalid access to property|Cannot call method|Attempt to call function|Stage balance validation failed|Stage balance validation error|StageCatalog validation error" "$validation_log" "$validation_stdout"

echo "Stage balance validation passed."
