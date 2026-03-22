#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
godot --headless --path . --log-file /tmp/puzzle-stage-validation.log --script res://scripts/validate_stage_data.gd
