#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/godot_validation_env.sh
validation_require_godot

export PAM_RENDER_SNAPSHOT_DIR="${PAM_RENDER_SNAPSHOT_DIR:-/tmp/puzzle-render-snapshots}"
validation_log="/tmp/puzzle-render-snapshots-validation.log"
validation_stdout="/tmp/puzzle-render-snapshots-validation.stdout"

mkdir -p "$PAM_RENDER_SNAPSHOT_DIR"
rm -f "$validation_log" "$validation_stdout"
godot_command=(godot --quiet --audio-driver Dummy --rendering-driver opengl3 --path . --log-file "$validation_log" --script res://scripts/validate_render_snapshots.gd)
if command -v xvfb-run >/dev/null 2>&1; then
  godot_command=(xvfb-run -a "${godot_command[@]}")
fi

if ! "${godot_command[@]}" >"$validation_stdout" 2>&1; then
  echo "Render snapshot validation failed."
  cat "$validation_stdout"
  exit 1
fi
touch "$validation_log" "$validation_stdout"

validation_fail_on_matches "Render snapshot validation" "SCRIPT ERROR:|Parse Error:|Invalid access to property|Cannot call method|Attempt to call function|Render snapshot validation error" "$validation_log" "$validation_stdout"

snapshot_count="$(find "$PAM_RENDER_SNAPSHOT_DIR" -type f -name '*.png' | wc -l | tr -d ' ')"
if [ "$snapshot_count" -lt 10 ]; then
  echo "Render snapshot validation expected at least 10 PNGs in $PAM_RENDER_SNAPSHOT_DIR, got $snapshot_count."
  exit 1
fi

echo "Render snapshot validation passed: $snapshot_count PNGs in $PAM_RENDER_SNAPSHOT_DIR."
