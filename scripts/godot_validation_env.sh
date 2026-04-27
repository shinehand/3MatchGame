#!/bin/zsh

# Keep validation runs from reading or mutating a player's local user:// save data.
export GODOT_VALIDATION_HOME="${GODOT_VALIDATION_HOME:-${TMPDIR:-/tmp}/3matchgame-godot-validation-home}"
mkdir -p "$GODOT_VALIDATION_HOME"
export HOME="$GODOT_VALIDATION_HOME"
export XDG_DATA_HOME="$GODOT_VALIDATION_HOME/xdg-data"
export XDG_CONFIG_HOME="$GODOT_VALIDATION_HOME/xdg-config"
export XDG_CACHE_HOME="$GODOT_VALIDATION_HOME/xdg-cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

validation_require_godot() {
  if ! command -v godot >/dev/null 2>&1; then
    echo "Godot executable not found in PATH."
    exit 127
  fi
}

validation_search() {
  local pattern="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -n "$pattern" "$@"
    return $?
  fi

  if command -v grep >/dev/null 2>&1; then
    grep -R -E -n "$pattern" "$@"
    return $?
  fi

  echo "Neither rg nor grep is available for validation scans." >&2
  return 2
}

validation_fail_on_matches() {
  local label="$1"
  local pattern="$2"
  shift 2
  local scan_output

  if scan_output="$(validation_search "$pattern" "$@" 2>&1)"; then
    print -r -- "$scan_output"
    echo "$label reported blocking errors."
    exit 1
  else
    local scan_status=$?
    if [ "$scan_status" -gt 1 ]; then
      print -r -- "$scan_output"
      echo "$label scan failed."
      exit "$scan_status"
    fi
  fi
}
