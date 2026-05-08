# Project Animal Match Expression QA - 2026-05-02

## QA 결과

승인 — 코드 검증 기준에서 PAM-DEV-030, PAM-DEV-031, PAM-DEV-032의 1차 구현은 통과했다.

PAM-QA-040은 no-device readiness 통과 후 final device QA가 남아 있는 상태로 관리한다.

## 대상 작업 카드

- PAM-DEV-030: BlockTile 표정 상태 API 추가
- PAM-DEV-031: BoardExpressionScheduler 추가
- PAM-DEV-032: 게임 이벤트와 표정 연결
- PAM-QA-040: 표정 애니메이션 QA 체크리스트 수행

## 확인 환경

- Godot 4.x headless validation
- 저장소: `/Users/shinehandmac/Github/3MatchGame`
- 확인 일시: 2026-05-02 11:55 KST

## 검증 명령

```sh
bash scripts/validate_stage_data.sh
bash scripts/validate_stage_balance.sh
bash scripts/validate_gameplay.sh
```

## 주요 확인

- `scripts/block_tile.gd`
  - `set_expression(expression_id, force := false)` API가 추가되어 있다.
  - `clear_expression()`과 `can_play_idle_expression()`이 추가되어 있다.
  - fallback 표현이 구현되어 있다.
    - `blink`: icon scale y 축소 후 복귀
    - `smile`: scale-up + 밝기 증가 후 복귀
    - `match`: 제거 직전 scale-up + tint 후 복귀
    - `fever`: 반복 scale/tint pulse
    - `worried`: 짧은 좌우 shake + tint
  - expression 재생 중 기존 idle motion을 중지하고, 종료 후 가능한 경우 idle motion을 재개한다.

- `scripts/gameplay.gd`
  - idle scheduler가 `_restart_idle_expression_scheduler()` / `_run_idle_expression_scheduler()`로 연결되어 있다.
  - idle blink 간격은 `2.8~6.0초` 범위다.
  - 동시 blink 수는 `IDLE_EXPRESSION_MAX_ACTIVE := 4`로 제한된다.
  - `stage_state != "playing"`, `is_busy == true`, overlay 표시 중에는 새 blink를 시작하지 않는다.
  - 이벤트 연결 확인:
    - 타일 선택 및 유효 스왑: `smile`
    - 매치 제거 직전: `match`
    - 특수/보너스성 연출: `fever`
    - 이동 수 3 이하 및 실패 직전: `worried`

- 데이터/로스터 연계
  - 12종 로스터 확장과 validator 기준이 유지된다.
  - Stage 8~10 pool은 6종 이하로 정리되어 있다.
  - 목표 동물이 pool에 포함되는 규칙이 validator에 추가되어 있다.

## 반려 이슈

없음.

## 재확인 필요

- 실제 디바이스에서 portrait/landscape 수동 확인 필요.
- `lion`, `elephant`는 전용 기본 블록 texture가 추가되었으므로 실제 디바이스에서 64px 미리보기/보드 판독성과 후속 표정 atlas 품질을 다시 확인해야 한다.
- expression과 match/drop VFX가 매우 빠른 연쇄 상황에서 과하게 겹치지 않는지 플레이 QA 필요.
