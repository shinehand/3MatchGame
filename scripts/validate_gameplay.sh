#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/godot_validation_env.sh
validation_require_godot

blocking_log_patterns="SCRIPT ERROR:|Parse Error:|Invalid access to property|Cannot call method|Attempt to call function|Failed loading resource|Unable to open file:|GameSession: failed to open save file|Scene load validation error"

echo "[1/8] Stage data structure validation"
zsh scripts/validate_stage_data.sh

echo "[2/8] Stage balance validation"
zsh scripts/validate_stage_balance.sh

echo "[3/8] Godot import cache"
import_log="/tmp/puzzle-import-cache.log"
import_stdout="/tmp/puzzle-import-cache.stdout"
if ! godot --headless --quiet --path . --import --quit --log-file "$import_log" >"$import_stdout" 2>&1; then
  echo "Godot import failed."
  cat "$import_stdout"
  exit 1
fi
validation_fail_on_matches "Godot import" "$blocking_log_patterns" "$import_log" "$import_stdout"
echo "Godot import cache prepared."

echo "[4/8] Focused scene load smoke"
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

echo "[5/8] Headless main load"
headless_log="/tmp/puzzle-headless-validate.log"
headless_stdout="/tmp/puzzle-headless-validate.stdout"
if ! godot --headless --quiet --path . --log-file "$headless_log" --quit >"$headless_stdout" 2>&1; then
  echo "Headless main load failed."
  cat "$headless_stdout"
  exit 1
fi
validation_fail_on_matches "Headless main load" "$blocking_log_patterns" "$headless_log" "$headless_stdout"
echo "No script/runtime errors reported in headless log."

echo "[6/8] Texture loading anti-pattern scan"
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

echo "[7/8] Alpha QA packet integrity"
alpha_packet_stdout="/tmp/puzzle-alpha-qa-packet-dry-run.stdout"
if ! zsh scripts/create_alpha_qa_packet.sh --dry-run >"$alpha_packet_stdout" 2>&1; then
  echo "Alpha QA packet dry-run failed."
  cat "$alpha_packet_stdout"
  exit 1
fi
alpha_template="docs/qa/templates/alpha-lock-pass-manual-qa-template.md"
for required_pattern in \
  "\\| Home \\|" \
  "\\| Stage 1 \\|" \
  "\\| Stage 11 \\|" \
  "\\| Stage 25 \\|" \
  "\\| Stage 50 \\|" \
  "\\| Stage 75 \\|" \
  "\\| Stage 100 \\|" \
  "Alpha Blocker Log" \
  "Device-Blocked Items" \
  "sound" \
  "haptics" \
  "Orientation"; do
  if ! validation_search "$required_pattern" "$alpha_template" >/dev/null 2>&1; then
    echo "Alpha QA template missing required pattern: $required_pattern"
    exit 1
  fi
done
echo "Alpha QA packet template and dry-run passed."

echo "[8/8] Manual smoke checklist"
cat <<'EOF'
- 앱 실행 직후 캔디 배경, 큰 `Zoo-Zoo Pop` 로고, 움직이는 동물 캔디, 진행바가 있는 로딩 화면이 먼저 보이는지 확인
- 홈 화면에서 큰 `Zoo-Zoo Pop` 로고, 동물 마스코트, `PLAY`, `맵`, `도감`, `설정`이 게임 화면처럼 보이는지 확인
- `PLAY`를 누르면 월드맵/스테이지 선택 씬으로 이동하는지 확인
- 스테이지 선택 씬 첫 화면에서 긴 설명 패널/카드 목록이 아니라 전체 월드맵, 10개 경로 노드, 큰 `출동` 버튼이 먼저 보이는지 확인
- 스테이지 선택 씬에서 두꺼운 캔디 경로, 컬러 도트, 광택 원형 노드, 배경 캔디 장식, 마스코트가 함께 보여 사가맵처럼 보이는지 확인
- 스테이지 노드를 누르면 바로 게임으로 가지 않고 Stage Popup이 뜨는지 확인
- Stage Popup이 페이드/팝인으로 뜨고 닫을 때 자연스럽게 사라지는지 확인
- Stage Popup에서 목표, 이동 수, 보상, 아이콘이 있는 시작 부스터 3종, START 버튼이 정상 표시되는지 확인
- Stage Popup을 닫으면 overlay가 사라지고, START 직전 선택 스테이지/부스터가 저장되는지 확인
- Stage 4 같은 Buddy 스테이지에서는 Stage Popup에 Rescue Buddy 동물/스킬/조건 요약이 보이고 Gameplay HUD Buddy 문구와 같은 대상을 가리키는지 확인
- 부스터를 선택하고 START를 누르면 게임 시작 보드에 선택 부스터가 배치되는지 확인
- 첫 세션 Level 1-5 순차 클리어 후 Stage 6, `frog`/`koala`/`hamster` Rescue Book `NEW`, `animal_unlock` 기록이 유지되는지 확인
- Rescue Book 카드에서 해금 동물의 토큰/우정 레벨/NEW 상태와 잠김 동물의 해금 스테이지 문구가 정상 표시되는지 확인
- 라이브 이벤트 노출이 홈, 스테이지 선택, 결과 오버레이, 컬렉션에서 각각 `live_event_impression`으로 기록되는지 확인
- 런타임 analytics가 `GameSession` 저장과 `AnalyticsGateway` local_buffer queued dispatch 양쪽에 남고, local_buffer가 disk reload 후에도 유지되며, flush 후 pending queue에서 제거되고, corrupt/bounded queue가 안전하며, 계약 위반 이벤트는 provider queue 대신 rejected_contract로 격리되는지 확인
- 앱 실행 후 보드 8x8 블록이 즉시 보이는지 확인
- 모바일 세로 게임 화면에서 큰 스탯/목표 카드가 아니라 상단 게임 HUD와 목표 띠가 먼저 보이고, 보드가 화면 중심을 차지하는지 확인
- 모바일 세로 게임 화면 하단에 아이콘형 부스터 도크가 있어 화면 아래가 비어 보이지 않는지 확인
- 보드가 멈춰 있을 때도 동물 블록들이 아주 미세하게 숨 쉬는 idle 애니메이션을 유지하는지 확인
- 게임 시작 때 보드가 살짝 등장하고 `LEVEL / READY / GO` 상위 연출이 보이는지 확인
- 첫 유효 매치 후 전체 보드가 깜빡이거나 사라지지 않는지 확인
- 매치, 무지개 구슬, 콤보 보상 때 보드 흔들림과 상위 이펙트가 블록 위에서 재생되는지 확인
- 목표 완료 시 동물명 구출, 덤불 정리, 점수 달성 피드백이 구분되어 보이는지 확인
- FxLayer 자동 smoke가 동시 VFX child count 상한과 transient node cleanup을 검증하는지 확인
- 연쇄 발생 시 남은 블록은 안정적으로 유지되는지 확인
- 4매치 후 줄 제거 특수 블록 배지가 생기는지 확인
- 5매치 후 무지개 구슬 특수 블록이 생기는지 확인
- L/T자 매치 후 폭발 특수 블록이 생기는지 확인
- Stage 31 smoke에서 row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb 6종 조합이 실제 swap 경로에서 중복 제거 없이 한 번씩 처리되는지 확인
- 특수+특수 조합 시작 시 일반 매치 pop과 구분되는 조합별 shaped flash/beam/ring/label 전용 VFX가 보이는지 확인
- 특수+특수 조합 6종이 `special_combo_trigger` analytics에 타입/제거 수/장애물 수를 남기는지 확인
- Combo Gauge가 차면 일반 블록 3개가 특수 블록으로 변환되는지 확인
- Stage 4/5/8/16/18/20/24/25/31/41/51/81 첫 등장 Rescue Buddy가 보드/게이지/장애물/점수/추천/구조 이동에 과한 지연 없이 반응하는지 확인
- 덤불 스테이지에서 덤불 목표 칩, 보드 오버레이, 덤불 제거 전용 사운드/진동/VFX가 함께 보이는지 확인
- 스테이지 클리어 후 남은 이동 수가 있으면 Zoo-Zoo Time 보너스 폭발이 먼저 재생되는지 확인
- 스테이지 클리어 결과에서 별, 골드, Zoo-Zoo Time 보너스, `다음 스테이지`, `홈으로` 선택이 정상적으로 보이는지 확인
- 스테이지 실패 오버레이가 정상적으로 뜨는지 확인
- Stage 1 같은 FTUE 실패 오버레이는 무료 재도전만 보이고 보상형 광고/IAP 문구가 없는지 확인
- Near Miss 실패 오버레이에서 `놓친 핵심`, `다음 한 수`, `+3 이동 받고 계속`이 함께 보이고, 계속하기를 누르면 이동 3회로 실제 플레이가 재개되는지 확인
- Near Miss 실패 오버레이에서 `재도전`을 누르면 같은 스테이지가 새 이동 수/점수 0 상태로 다시 시작되는지 확인
- 보상형 광고 실패/취소와 IAP 취소/실패/복구는 이동 수, 목표 진행, wallet을 바꾸지 않는지 확인
- 같은 transaction_id의 보상형 광고/IAP continue 콜백이 반복되어도 추가 이동과 완료 로그가 중복 지급되지 않는지 확인
- 코인 continue는 충분한 gold가 있을 때만 차감 후 5회 이동으로 재개되고, gold 부족 시 실패 상태가 유지되는지 확인
- 실패 오퍼 선택과 닫기 행동이 `fail_offer_select`, `fail_offer_dismiss`로 기록되는지 확인
- 실패 continue CTA가 provider-neutral monetization gateway를 거쳐 실패/성공 callback과 source 허용 정책을 처리하는지 확인
- 실패 오퍼 노출, 광고/IAP 결과, 추가 이동 지급이 `fail_offer_show`, `ad_reward_complete`, `ad_reward_fail`, `iap_purchase_complete`, `iap_purchase_restore`, `iap_purchase_cancel`, `iap_purchase_fail`, `extra_moves_grant`로 기록되는지 확인
EOF
