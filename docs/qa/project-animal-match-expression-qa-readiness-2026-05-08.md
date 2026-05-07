# Project Animal Match Expression QA Readiness - 2026-05-08

## QA 결과

PAM-QA-040 no-device readiness 통과 대상이다. 최종 승인은 실제 기기 또는 시뮬레이터 portrait/landscape 수동 QA 결과가 필요하다.

## 대상 작업 카드

- PAM-QA-040: 표정 애니메이션 QA 체크리스트 수행

## 확인 환경

- Godot 4.x headless validation
- 저장소: `/Users/shinehandmac/Github/3MatchGame`
- 확인 일시: 2026-05-08 KST

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

## Evidence logs

- `scripts/validate_scene_loads.gd::_validate_expression_animation_rules`
- `docs/dev/validation-process.md`의 no-device 표정 애니메이션 readiness 체크리스트
