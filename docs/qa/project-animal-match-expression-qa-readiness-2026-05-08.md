# Project Animal Match Expression QA Readiness - 2026-05-08

## QA 결과

PAM-QA-040 no-device readiness 통과 대상이다. 최종 승인은 실제 기기 또는 시뮬레이터 portrait/landscape 수동 QA 결과가 필요하다. 이 문서는 자동 검증 결과를 기기 QA 실행표로 넘기는 handoff 기준이다.

## 대상 작업 카드

- PAM-QA-040: 표정 애니메이션 QA 체크리스트 수행

## 확인 환경

- Godot 4.x headless validation
- 저장소: `/Users/shinehandmac/Github/3MatchGame`
- 확인 일시: 2026-05-08 KST
- 수동 QA 실행 시 `Build source commit`, 빌드 산출물 경로, 기기명, OS 버전, orientation을 아래 결과 표에 기록한다.

## 검증 명령

```sh
./scripts/validate_gameplay.sh
godot --headless --path . --script res://scripts/validate_scene_loads.gd
```

## No-device readiness

- `blink`: scene smoke가 8x8 보드에서 최소 1개, 동시에 최대 4개를 검증한다.
- `blink`: `is_busy == true` 또는 결과 overlay 표시 중 `_play_random_idle_blinks()`가 새 expression을 시작하지 않는지 검증한다.
- `smile`: `_select_cell()` 경로에서 선택 타일이 `smile` 상태가 되는지 검증한다.
- `match`: `_set_tile_expression(..., "match", true)` 이후 `blink`, `smile`, `worried`가 덮지 못하는지 검증한다.
- `worried`: `remaining_moves == 3` HUD 갱신 경로에서 목표 타일 일부에만 표시되고 동시 4개 이하로 제한되는지 검증한다.
- 레이아웃: scene load smoke가 홈, 월드맵, 게임 HUD, 도감의 논리 캔버스 앵커를 검증한다.

## Device-blocked items

- 실제 물리 viewport에서 블록 얼굴이 portrait/landscape 모두 잘리지 않는지 확인해야 한다.
- 빠른 스와이프, 매치, 낙하, 리필, 특수 블록 발동 중 표정/VFX 겹침이 과하지 않은지 확인해야 한다.
- 터치감, UI 사운드, 햅틱 강도는 headless 검증으로 승인하지 않는다.

## 권장 기기 범위

| 범위 | 기기 | Orientation | 설정 | Result |
| --- | --- | --- | --- | --- |
| 기준 Android 실기기 | Pending | portrait, landscape | sound ON/OFF, haptics ON/OFF | Pending |
| 저사양 Android 실기기 | Pending | portrait, landscape | sound ON, haptics ON | Pending |
| iOS 기기 또는 시뮬레이터 | Pending | portrait, landscape | sound ON, haptics ON | Pending |

## 실제 기기 QA 실행표

| 구간 | Orientation | 진입 조건 | 필수 확인 | 증거 |
| --- | --- | --- | --- | --- |
| Home -> Stage Select | portrait, landscape | 신규 세션 또는 저장 데이터 초기화 후 앱 실행 | 홈 버튼, 하단 네비게이션, 월드맵 경로, Stage Popup이 safe area에 잘리지 않는다. | 홈/월드맵/팝업 스크린샷 |
| Stage 1 | portrait, landscape | 기본 매치 2회 이상 플레이 | 선택 `smile`, 제거 직전 `match`, 낙하/리필 중 얼굴 잘림 없음, 목표 칩 판독 가능. | 10초 영상 또는 연속 스크린샷 |
| Stage 4 | portrait, landscape | Buddy preview가 있는 첫 스테이지 진입 | Stage Popup Buddy 문구와 Gameplay HUD 대상이 같고, 0/3 -> 2/3 -> ready -> complete 상태가 읽힌다. | Popup/HUD/ready/complete 캡처 |
| Stage 8 | portrait | 콤보 2+와 Fever 진입 유도 | `combo_peep` 충전 피드백이 Fever 중 과하게 겹치지 않고, 차단/준비 상태가 HUD에서 혼동되지 않는다. | 10초 영상 |
| Stage 18 또는 81 | portrait | 덤불 목표를 남기고 Buddy 발동 조건 유도 | Buddy가 마지막 목표를 단독 완료하려 할 때 UI가 과장된 성공 피드백을 보이지 않고, 보드/목표 칩이 안정적이다. | 발동 전후 캡처 |
| Stage 25 | portrait | Near Miss 실패와 재시도/continue 진입 | `worried` 표현, 실패 overlay, `놓친 핵심`, `다음 한 수`, continue CTA가 서로 겹치지 않는다. | 실패 overlay 캡처 |
| Stage 31 | portrait, landscape | 특수+특수 조합 6종 모두 수동 발동 | 전용 flash/beam/ring/label이 일반 match burst와 구분되고, SFX/haptic/shake가 과하지 않으며, 제거 후 낙하/리필이 자연스럽다. | 각 조합 5초 영상 또는 연속 캡처 |
| Collection | portrait, landscape | Rescue Book 열기, 해금 카드 탭 | 카드 미리보기 Tween이 스크롤 중 과하지 않고, NEW/토큰/우정 레벨/잠김 문구가 잘리지 않는다. | 그리드/상세 캡처 |

최소 증거 기준은 portrait/landscape 스크린샷 각 1장, Stage 31 특수+특수 조합 6종 증거, Buddy 3개 이상 스테이지 캡처, 실패/Blocked 항목의 재현 단계와 로그 경로다.

## 반려 기준

- Blocker: 보드 셀, 목표 칩, 남은 이동 수, Stage Popup START, 실패/결과 CTA 중 하나라도 실제 viewport에서 조작 불가 또는 판독 불가.
- Blocker: 빠른 연쇄 또는 특수 조합 후 입력이 2초 이상 회복되지 않거나 stage state가 멈춘다.
- Major: 표정/VFX/Buddy HUD가 같은 영역을 반복 가려 플레이 의사결정을 방해한다.
- Major: portrait 또는 landscape 한쪽에서만 safe area, notch, home indicator, 하단 네비게이션과 주요 UI가 겹친다.
- Minor: 판독은 가능하지만 특정 VFX, 햅틱, 사운드 강도가 과하거나 약해 튜닝이 필요하다.

## 결과 기록표

| 항목 | 값 |
| --- | --- |
| Build source commit | Pending |
| Build artifact path | Pending |
| Device / OS | Pending |
| Tester | Pending |
| Orientation checked | Pending |
| Overall result | Pending |

| 구간 | Result | Evidence path | Issue IDs | Notes |
| --- | --- | --- | --- | --- |
| Home -> Stage Select | Pending |  |  |  |
| Stage 1 | Pending |  |  |  |
| Stage 4 | Pending |  |  |  |
| Stage 8 | Pending |  |  |  |
| Stage 18 또는 81 | Pending |  |  |  |
| Stage 25 | Pending |  |  |  |
| Stage 31 | Pending |  |  |  |
| Collection | Pending |  |  |  |

## Evidence logs

- `scripts/validate_scene_loads.gd::_validate_expression_animation_rules`
- `docs/dev/validation-process.md`의 no-device 표정 애니메이션 readiness 체크리스트
- 실제 기기 QA 증거는 `output/pam-qa-040/YYYY-MM-DD/` 아래 스크린샷 또는 짧은 영상 경로로 기록한다.
