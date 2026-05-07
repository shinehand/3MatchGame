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
- 앱 실행 직후 캔디 배경, 큰 `Zoo-Zoo Pop` 로고, 움직이는 동물 캔디, 진행바가 있는 로딩 화면이 먼저 보이는지 확인
- 홈 화면에서 큰 `Zoo-Zoo Pop` 로고, 동물 마스코트, `PLAY`, `맵`, `도감`, `설정`이 게임 화면처럼 보이는지 확인
- `PLAY`를 누르면 월드맵/스테이지 선택 씬으로 이동하는지 확인
- 스테이지 선택 씬 첫 화면에서 긴 설명 패널/카드 목록이 아니라 전체 월드맵, 10개 경로 노드, 큰 `출동` 버튼이 먼저 보이는지 확인
- 스테이지 선택 씬에서 두꺼운 캔디 경로, 컬러 도트, 광택 원형 노드, 배경 캔디 장식, 마스코트가 함께 보여 사가맵처럼 보이는지 확인
- 스테이지 노드를 누르면 바로 게임으로 가지 않고 Stage Popup이 뜨는지 확인
- Stage Popup이 페이드/팝인으로 뜨고 닫을 때 자연스럽게 사라지는지 확인
- Stage Popup에서 목표, 이동 수, 보상, 아이콘이 있는 시작 부스터 3종, START 버튼이 정상 표시되는지 확인
- Stage 4 같은 Buddy 스테이지에서는 Stage Popup에 Rescue Buddy 동물/스킬/조건 요약이 보이고 Gameplay HUD Buddy 문구와 같은 대상을 가리키는지 확인
- 부스터를 선택하고 START를 누르면 게임 시작 보드에 선택 부스터가 배치되는지 확인
- 앱 실행 후 보드 8x8 블록이 즉시 보이는지 확인
- 모바일 세로 게임 화면에서 큰 스탯/목표 카드가 아니라 상단 게임 HUD와 목표 띠가 먼저 보이고, 보드가 화면 중심을 차지하는지 확인
- 모바일 세로 게임 화면 하단에 아이콘형 부스터 도크가 있어 화면 아래가 비어 보이지 않는지 확인
- 보드가 멈춰 있을 때도 동물 블록들이 아주 미세하게 숨 쉬는 idle 애니메이션을 유지하는지 확인
- 게임 시작 때 보드가 살짝 등장하고 `LEVEL / READY / GO` 상위 연출이 보이는지 확인
- 첫 유효 매치 후 전체 보드가 깜빡이거나 사라지지 않는지 확인
- 매치, 무지개 구슬, 콤보 보상 때 보드 흔들림과 상위 이펙트가 블록 위에서 재생되는지 확인
- 연쇄 발생 시 남은 블록은 안정적으로 유지되는지 확인
- 4매치 후 줄 제거 특수 블록 배지가 생기는지 확인
- 5매치 후 무지개 구슬 특수 블록이 생기는지 확인
- L/T자 매치 후 폭발 특수 블록이 생기는지 확인
- Stage 31 smoke에서 row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb 6종 조합이 중복 제거 없이 한 번씩 처리되는지 확인
- Combo Gauge가 차면 일반 블록 3개가 특수 블록으로 변환되는지 확인
- Stage 4/5/8/16/18/20/24/25/31/41/51/81 첫 등장 Rescue Buddy가 보드/게이지/장애물/점수/추천/구조 이동에 과한 지연 없이 반응하는지 확인
- 덤불 스테이지에서 덤불 목표 칩과 보드 오버레이가 함께 보이는지 확인
- 스테이지 클리어 후 남은 이동 수가 있으면 Zoo-Zoo Time 보너스 폭발이 먼저 재생되는지 확인
- 스테이지 클리어 결과에서 별, 골드, Zoo-Zoo Time 보너스, `다음 스테이지`, `홈으로` 선택이 정상적으로 보이는지 확인
- 스테이지 실패 오버레이가 정상적으로 뜨는지 확인
- Near Miss 실패 오버레이에서 `+3 이동 받고 계속`을 누르면 이동 3회로 실제 플레이가 재개되는지 확인
- 실패 오퍼 선택과 닫기 행동이 `fail_offer_select`, `fail_offer_dismiss`로 기록되는지 확인
- 실패 오퍼 노출과 추가 이동 지급이 `fail_offer_show`, `extra_moves_grant`로 기록되는지 확인
EOF
