# Task Brief: Fun Enhancement 2026-03-23

## 작업명

- 게임 재미 보강 1차: 이동수 긴장감, 별 등급 조정, 콤보 표시, 목표 완료 피드백

## 목표

- `fun-review-2026-03-23.md`의 즉시 구현 항목 F1~F4를 구현한다.
- 코어 루프에서 플레이어가 `잘 했다`는 느낌을 받는 순간을 강화한다.

## 범위

- 포함
  - 이동 수 경고 색상 (F1)
  - 별 등급 비율 기준 (F2)
  - 콤보 배너 텍스트 (F3)
  - 개별 목표 달성 사운드 (F4)
- 제외
  - BGM 추가
  - 클리어 별 팝 애니메이션 (씬 개편 필요)
  - 동물 구출 이펙트

## 팀별 분담

### Core Developer (담당: `gameplay.gd`)

- **F1**: `_update_hud()`에서 `remaining_moves` 경고 색상 로직 추가
  - ≤ 3: 빨강 `Color(0.75, 0.19, 0.19, 1)`
  - ≤ 5: 주황 `Color(0.88, 0.50, 0.13, 1)`
  - 기본: 갈색 `Color(0.32, 0.24, 0.19, 1)`
  - portrait 모드 `stage_value`도 동일 색상 적용
- **F2**: `_stage_star_rating()` → 비율 기반 변경
  - `var total_moves := int(_current_stage()["moves"])`
  - 3★: `remaining_moves >= int(round(total_moves * 0.35))`
  - 2★: `remaining_moves >= int(round(total_moves * 0.15))`
  - 단, 최솟값 보장: 3★ threshold ≥ 3, 2★ threshold ≥ 1
- **F3**: `@onready var combo_label: Label = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame/ComboBanner/ComboLabel`
  - `_show_combo_banner()` 안에서 combo ≥ 2이면 `combo_label.text = "×%d" % combo`, 1이면 `combo_label.text = ""`
  - combo_label도 같은 tween에서 banner와 함께 fade in/out 처리
- **F4**: `_refresh_goal_chips()` 안에서 개별 collect 목표가 막 완료된 순간 감지
  - `_prev_complete_set` 딕셔너리를 state로 유지해서 새로 complete가 된 항목 감지
  - 새로 complete가 됐을 때 `Feedback.play_goal_complete()` 호출

### UI Developer (담당: `gameplay.tscn`)

- **F3**: `ComboBanner` 아래에 `ComboLabel` Label 노드 추가
  - `layout_mode = 1`, anchors center, 텍스트 기본값 빈 문자열
  - 폰트 사이즈 34, 두꺼운 폰트 색상 `Color(1, 0.92, 0.24, 1)` (밝은 노랑)
  - `mouse_filter = 2` (통과)

### Audio Developer (담당: `feedback.gd`)

- **F4**: `play_goal_complete()` 메서드 추가
  - 맑고 짧은 팡 사운드: `goal_complete` 스트림 정의
  - 진동: 28ms

## 완료 조건

- 이동 수 5 이하에서 `moves_value` 색이 주황/빨강으로 바뀐다.
- 클리어 시 별 등급이 스테이지 총 이동 수 대비 비율로 계산된다.
  - 예: Stage 1(12이동, 6이동 남음 → 50% → 3★), Stage 50(17이동, 4이동 남음 → 23% → 2★)
- 콤보 2 이상 발생 시 배너에 `×2`, `×3` 텍스트가 표시된다.
- 수집 목표가 달성되는 순간 맑은 사운드가 1회 재생된다.
- 기존 게임 루프에 영향 없음 (validate_gameplay.sh 통과 기준)

## QA 핸드오프 기준

- Stage 1 플레이에서 위 4가지 변경을 직접 확인
- Stage 50, Stage 90에서 별 등급이 이전과 달라졌는지 수치 확인

## 영향 파일

- `scripts/gameplay.gd`
- `scripts/feedback.gd`
- `scenes/gameplay.tscn`
