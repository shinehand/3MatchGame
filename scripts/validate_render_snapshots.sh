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
  export LIBGL_ALWAYS_SOFTWARE=1
  export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
  export GALLIUM_DRIVER=llvmpipe
  godot_command=(xvfb-run -a -s "-screen 0 1280x1024x24 +extension GLX +render -noreset" godot --quiet --audio-driver Dummy --display-driver x11 --rendering-driver opengl3 --path . --log-file "$validation_log" --script res://scripts/validate_render_snapshots.gd)
fi

if ! "${godot_command[@]}" >"$validation_stdout" 2>&1; then
  echo "Render snapshot validation failed."
  cat "$validation_stdout"
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    diagnostic_summary="$(tail -80 "$validation_stdout" "$validation_log" 2>/dev/null | tr '\n' ' ' | cut -c1-3500)"
    echo "::error title=Render snapshot validation failed::$diagnostic_summary"
  fi
  exit 1
fi
touch "$validation_log" "$validation_stdout"
if [ -f "$PAM_RENDER_SNAPSHOT_DIR/manifest.txt" ]; then
  cp "$PAM_RENDER_SNAPSHOT_DIR/manifest.txt" /tmp/puzzle-render-snapshots-manifest.txt
fi

blocking_log_patterns="SCRIPT ERROR:|Parse Error:|Invalid access to property|Cannot call method|Attempt to call function|Render snapshot validation error"
if scan_output="$(validation_search "$blocking_log_patterns" "$validation_log" "$validation_stdout" 2>&1)"; then
  print -r -- "$scan_output"
  echo "Render snapshot validation reported blocking errors."
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    diagnostic_summary="$(print -r -- "$scan_output" | tail -80 | tr '\n' ' ' | cut -c1-3500)"
    echo "::error title=Render snapshot validation log scan failed::$diagnostic_summary"
  fi
  exit 1
else
  scan_status=$?
  if [ "$scan_status" -gt 1 ]; then
    print -r -- "$scan_output"
    echo "Render snapshot validation scan failed."
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
      diagnostic_summary="$(print -r -- "$scan_output" | tail -80 | tr '\n' ' ' | cut -c1-3500)"
      echo "::error title=Render snapshot validation scan failed::$diagnostic_summary"
    fi
    exit "$scan_status"
  fi
fi

snapshot_count="$(find "$PAM_RENDER_SNAPSHOT_DIR" -type f -name '*.png' | wc -l | tr -d ' ')"
if [ "$snapshot_count" -lt 10 ]; then
  echo "Render snapshot validation expected at least 10 PNGs in $PAM_RENDER_SNAPSHOT_DIR, got $snapshot_count."
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    manifest_summary="$(cat "$PAM_RENDER_SNAPSHOT_DIR/manifest.txt" 2>/dev/null | tr '\n' ' ' | cut -c1-3500)"
    echo "::error title=Render snapshot PNG count failed::expected at least 10 PNGs in $PAM_RENDER_SNAPSHOT_DIR, got $snapshot_count. $manifest_summary"
  fi
  exit 1
fi

echo "Render snapshot validation passed: $snapshot_count PNGs in $PAM_RENDER_SNAPSHOT_DIR."
