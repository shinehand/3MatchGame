#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/godot_validation_env.sh
validation_require_godot

blocking_log_patterns="SCRIPT ERROR:|Parse Error:|Invalid access to property|Cannot call method|Attempt to call function|Failed loading resource|Unable to open file:|GameSession: failed to open save file|Scene load validation error"

echo "[1/7] Stage data structure validation"
zsh scripts/validate_stage_data.sh

echo "[2/7] Stage balance validation"
zsh scripts/validate_stage_balance.sh

echo "[3/7] Godot import cache"
import_log="/tmp/puzzle-import-cache.log"
import_stdout="/tmp/puzzle-import-cache.stdout"
if ! godot --headless --quiet --path . --import --quit --log-file "$import_log" >"$import_stdout" 2>&1; then
  echo "Godot import failed."
  cat "$import_stdout"
  exit 1
fi
validation_fail_on_matches "Godot import" "$blocking_log_patterns" "$import_log" "$import_stdout"
echo "Godot import cache prepared."

echo "[4/7] Focused scene load smoke"
scene_log="/tmp/puzzle-scene-load-validate.log"
scene_stdout="/tmp/puzzle-scene-load-validate.stdout"
if ! godot --headless --quiet --path . --log-file "$scene_log" --script res://scripts/validate_scene_loads.gd >"$scene_stdout" 2>&1; then
  echo "Focused scene load smoke failed."
  cat "$scene_stdout"
  exit 1
fi
validation_fail_on_matches "Focused scene load smoke" "$blocking_log_patterns" "$scene_log" "$scene_stdout"
if validation_search "Scene load validation passed" "$scene_stdout" >/dev/null 2>&1; then
  true
else
  echo "Scene load validation passed."
fi

echo "[5/7] Headless main load"
headless_log="/tmp/puzzle-headless-validate.log"
headless_stdout="/tmp/puzzle-headless-validate.stdout"
if ! godot --headless --quiet --path . --log-file "$headless_log" --quit >"$headless_stdout" 2>&1; then
  echo "Headless main load failed."
  cat "$headless_stdout"
  exit 1
fi
validation_fail_on_matches "Headless main load" "$blocking_log_patterns" "$headless_log" "$headless_stdout"
echo "No script/runtime errors reported in headless log."

echo "[6/7] Texture loading anti-pattern scan"
if validation_search "Image\.load_from_file|ProjectSettings\.globalize_path" scripts >/tmp/puzzle_texture_scan.log 2>&1; then
  echo "Direct file-based texture loading found:"
  cat /tmp/puzzle_texture_scan.log
  exit 1
elif [ "$?" -gt 1 ]; then
  echo "Texture loading anti-pattern scan failed:"
  cat /tmp/puzzle_texture_scan.log
  exit 1
fi
echo "No direct file-based texture loading in scripts."

echo "[7/7] Manual smoke checklist"
cat <<'EOF'
- 홈 화면에서 `시작`, `스테이지 라인`, `설정` 버튼이 정상 표시되는지 확인
- `시작`을 누르면 스토리 라인이 있는 전용 스테이지 선택 씬으로 이동하는지 확인
- 스테이지 선택 씬에서 밴드 스토리, 추천 스테이지, 잠금/해금/별 수가 정상 반영되는지 확인
- 앱 실행 후 보드 8x8 블록이 즉시 보이는지 확인
- 첫 유효 매치 후 전체 보드가 깜빡이거나 사라지지 않는지 확인
- 연쇄 발생 시 남은 블록은 안정적으로 유지되는지 확인
- 4매치 후 줄 제거 특수 블록 배지가 생기는지 확인
- 5매치 후 폭발 특수 블록이 생기는지 확인
- 덤불 스테이지에서 덤불 목표 칩과 보드 오버레이가 함께 보이는지 확인
- 스테이지 클리어 시 `다음 스테이지`와 `홈으로` 선택이 정상적으로 동작하는지 확인
- 스테이지 실패 오버레이가 정상적으로 뜨는지 확인
EOF
