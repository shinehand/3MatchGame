#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "[1/5] Stage data structure validation"
zsh scripts/validate_stage_data.sh

echo "[2/5] Stage balance validation"
zsh scripts/validate_stage_balance.sh

echo "[3/5] Headless load"
godot --headless --path . --log-file /tmp/puzzle-headless-validate.log --quit
if rg -n "SCRIPT ERROR:|Parse Error:|Invalid access to property|Cannot call method|Attempt to call function" /tmp/puzzle-headless-validate.log; then
  echo "Headless load reported script/runtime errors."
  exit 1
fi
echo "No script/runtime errors reported in headless log."

echo "[4/5] Texture loading anti-pattern scan"
if rg -n "Image\.load_from_file|ProjectSettings\.globalize_path" scripts >/tmp/puzzle_texture_scan.log 2>&1; then
  echo "Direct file-based texture loading found:"
  cat /tmp/puzzle_texture_scan.log
  exit 1
fi
echo "No direct file-based texture loading in scripts."

echo "[5/5] Manual smoke checklist"
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
