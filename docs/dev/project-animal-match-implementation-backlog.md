# Project Animal Match Implementation Backlog

## 목적

이 백로그는 문서 기획을 실제 Godot 개발 작업으로 바꾸는 실행 목록이다. 각 작업은 에이전트가 독립적으로 맡을 수 있도록 대상 파일, 선행 조건, 완료 기준, 검증 방법을 포함한다.

## 현재 상태 요약

- 구현됨: 8x8 보드, 스와이프, 매치 판정, 낙하/리필, 특수 블록, 콤보 게이지, 덤불 장애물, HUD, 100개 스테이지 로딩/검증.
- 구현됨: 12종 동물 로스터 인식, `lion`/`elephant` 전용 256px 기본 블록 PNG, 스테이지 `roster_group`, 표정 fallback API와 idle blink scheduler.
- 문서 기준 신규 요구: 피버 3턴 MVP, Rescue Buddy 1종 자동 스킬, Rescue Book 컬렉션 메타, 실패 유형별 제안 정책, 분석 이벤트 계약.
- 기획 협의 기준: `docs/planning/project-animal-match-planning-council-synthesis.md`를 우선 참조한다.

## P0. 개발 진입 세팅

### PAM-DEV-001: 에이전트 진입 문서 확인

- 소유: PM Lead
- 대상 파일: `docs/project-animal-match-agent-start-here.md`, `docs/project-animal-match-agent-output-index.md`
- 작업:
  - 새 작업 에이전트가 읽어야 할 문서 순서를 확인한다.
  - 작업 카드 선택 후 완료 보고 형식을 따른다.
- 완료 기준:
  - 작업자가 어떤 문서를 읽고 어떤 파일을 수정해야 하는지 명확하다.

## P1. 12종 동물 로스터 연결

### PAM-DEV-010: 코드 로스터를 12종으로 확장

- 상태: 완료됨. 유지보수 시 회귀 검증용 카드로 사용한다.
- 소유: Development Agent
- 선행: Art Director가 12종 기본 블록 에셋 또는 fallback 정책 승인
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/stage_data_validator.gd`
  - `assets/generated/candy/`
- 작업:
  - `ANIMAL_IDS`에 `lion`, `elephant`를 추가한다.
  - `ANIMAL_NAMES`에 `사자`, `코끼리`를 추가한다.
  - `_slot_color()`에 사자/코끼리 색을 추가한다.
  - validator의 `VALID_ANIMALS`를 12종으로 맞춘다.
  - 기본 블록 에셋 누락 시 기존 동물 texture fallback을 방어 경로로 사용한다.
- 완료 기준:
  - 새 동물 id가 스테이지 데이터, 목표 텍스트, 타일 표시, 검증기에서 모두 통과한다.
- 검증:
  - `./scripts/validate_stage_data.sh`
  - `./scripts/validate_gameplay.sh`

### PAM-DEV-011: 12종 에셋 경로와 import 규칙 정리

- 상태: 완료됨. `lion`, `elephant` 전용 `assets/generated/candy/{animal_id}_candy_block.png` 256px 기본 블록 에셋을 추가했고, scene smoke가 MVP 보드 12종 직접 Texture2D/256x256 로드를 검증한다. 런타임 fallback은 에셋 누락 방어용으로 유지한다.
- 소유: Art + Development Agent
- 대상 파일:
  - `docs/art/project-animal-match-visual-style-guide.md`
  - `assets/generated/candy/`
  - Godot `.import` 파일
- 작업:
  - 12종 기본 블록 파일명을 1차 런타임 기준 `assets/generated/candy/{animal_id}_candy_block.png`로 통일한다.
  - 표정 확장 파일명은 `animal_{id}_{expression}.png` 및 atlas 규칙으로 분리한다.
  - `lion_candy_block.png`, `elephant_candy_block.png`를 전용 기본 블록으로 유지한다.
  - 에셋 import 후 Godot에서 Texture2D로 로드되는지 확인한다.
- 완료 기준:
  - `_load_animal_textures()`와 scene load 검증이 12종 모두 직접 기본 블록 Texture2D로 로드됨을 확인한다.

## P2. 스테이지 데이터와 밸런스 정리

### PAM-DEV-020: 스테이지별 animal_pool 5-6종 제한

- 상태: 완료됨. 다음 단계는 해금 순서/풀 회전/난이도 파형 validator 강화다.
- 소유: Planning + Development Agent
- 대상 파일:
  - `data/stages/*.json`
  - `scripts/stage_data_validator.gd`
  - `scripts/validate_stage_balance.gd`
- 작업:
  - 각 스테이지의 `spawn_profile.pool`을 5-6종으로 제한한다.
  - 튜토리얼 구간은 4-5종을 허용한다.
  - validator에 pool 크기 경고 또는 오류 기준을 추가한다.
  - 신규 동물은 밴드별로 순차 해금되도록 배치한다.
- 완료 기준:
  - 모든 스테이지가 4-6종 활성 풀을 가진다.
  - 목표 동물은 반드시 pool과 weight에 포함된다.
- 검증:
  - `./scripts/validate_stage_data.sh`
  - `./scripts/validate_stage_balance.sh`

### PAM-DEV-021: 로스터 그룹 메타데이터 추가

- 상태: 완료됨. 유지보수 시 `roster_group` 누락 회귀를 검증한다.
- 소유: Technical Lead
- 대상 파일:
  - `docs/dev/project-animal-match-technical-architecture.md`
  - `scripts/stage_catalog.gd`
  - `data/stages/*.json`
- 작업:
  - `roster_group` 필드 도입 여부를 확정한다.
  - 도입 시 `StageCatalog._normalize_stage()`에서 읽도록 구현한다.
  - 기존 데이터와 fallback stage에 기본값을 넣는다.
- 완료 기준:
  - 스테이지별 동물 그룹이 문서와 코드에서 추적 가능하다.

## P3. 동물 표정 애니메이션 시스템

### PAM-DEV-030: BlockTile 표정 상태 API 추가

- 상태: 완료됨. 다음 단계는 에셋 overlay/atlas 기반 확장이다.
- 소유: Development Agent
- 대상 파일:
  - `scripts/block_tile.gd`
  - `scenes/block_tile.tscn`
  - `docs/dev/project-animal-match-animal-expression-system.md`
- 작업:
  - `set_expression(expression_id: String)` API를 추가한다.
  - `blink`, `smile`, `match`, `fever`, `worried` 상태를 받을 수 있게 한다.
  - 에셋이 없을 때 scale, squash, eye overlay fallback으로 표현한다.
- 완료 기준:
  - 기존 `set_tile()` 흐름을 깨지 않고 표정 상태를 재생할 수 있다.
  - match 효과와 idle motion이 서로 충돌하지 않는다.
- 검증:
  - 첫 스테이지 실행 후 선택/매치/낙하가 기존처럼 동작한다.

### PAM-DEV-031: BoardExpressionScheduler 추가

- 상태: 완료됨. 다음 단계는 성능 QA와 화면별 표정 확장이다.
- 소유: Development Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - 필요 시 `scripts/board_expression_scheduler.gd`
- 작업:
  - idle 상태에서 2.8-6.0초 랜덤 간격으로 blink 대상 타일을 고른다.
  - 동시에 최대 4개 타일만 blink를 재생한다.
  - `is_busy`, 낙하, 제거, 특수 블록 발동 중에는 새 blink를 시작하지 않는다.
- 완료 기준:
  - 대기 중 일부 동물만 자연스럽게 blink한다.
  - 연쇄/낙하 중 표정 애니메이션이 끼어들지 않는다.

### PAM-DEV-032: 게임 이벤트와 표정 연결

- 상태: 완료됨. 다음 단계는 홈/컬렉션/결과 화면 확장이다.
- 소유: Development Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/block_tile.gd`
- 작업:
  - 타일 선택 시 `smile`.
  - 제거 직전 `match`.
  - 이동 수 3 이하 또는 실패 직전 `worried`.
  - 피버 구현 시 목표 동물과 특수 블록 중심으로 `fever`.
- 완료 기준:
  - 표정 재생이 core loop 피드백을 강화하고 보드 판독성을 해치지 않는다.

## P4. QA와 성능 게이트

### PAM-QA-040: 표정 애니메이션 QA 체크리스트 수행

- 상태: no-device readiness 자동화됨. Scene load smoke가 idle blink 시작, `is_busy` 중 idle blink 차단, 동시 blink 4개 이하, 선택 `smile`, low-move `worried` 4개 이하, `match` 표정 우선순위 유지, 논리 캔버스 기준 홈/월드맵/게임 HUD/도감 레이아웃 앵커를 검증한다. `docs/qa/project-animal-match-expression-qa-readiness-2026-05-08.md`는 실제 기기 또는 시뮬레이터 portrait/landscape 수동 QA 실행표, evidence path, 반려 기준을 포함한다. 남은 최종 승인 조건은 해당 실행표에 실제 결과를 기록하는 것이다.
- 소유: QA Agent
- 대상 파일:
  - `docs/qa/project-animal-match-development-gates.md`
  - `docs/qa/project-animal-match-expression-qa-readiness-2026-05-08.md`
  - `docs/dev/validation-process.md`
  - `scripts/validate_scene_loads.gd`
- 작업:
  - 8x8 보드에서 idle blink 동시 수가 4개 이하인지 확인한다. 자동 smoke로 검증됨.
  - `is_busy == true` 또는 overlay 표시 중 새 idle blink가 시작되지 않는지 확인한다. 자동 smoke로 검증됨.
  - 선택 `smile`, low-move `worried`, 제거 직전 `match` 우선순위가 런타임 경로에서 유지되는지 확인한다. 자동 smoke로 검증됨.
  - 스와이프, 매치, 낙하, 리필, 특수 블록 중 표정 애니메이션이 상태를 꼬이게 하지 않는지 확인한다. 자동 smoke가 우선순위/특수 조합 일부를 검증하며, 수동 플레이 확인이 남아 있다.
  - 모바일 portrait/landscape에서 블록 얼굴이 잘리지 않는지 확인한다. 논리 캔버스 앵커는 자동 검증되며, 물리 viewport 확인이 남아 있다.
- 완료 기준:
  - no-device readiness 결과가 문서화된다.
  - 주요 플로우 승인 또는 반려 사유가 문서화된다.
  - 실제 기기 또는 시뮬레이터 portrait/landscape에서 보드 얼굴, HUD, 부스터 도크, 목표 칩, 표정/VFX 겹침 결과가 기록된다.

### PAM-QA-041: Stage Popup / 시작 부스터 / Buddy Preview 회귀 스모크

- 상태: no-device readiness 자동화됨. Scene load smoke가 `WorldStageNode*` press로 Stage Popup 표시, 목표/이동 수/보상/PLAY/시작 부스터 3종 버튼과 아이콘, 부스터 선택 상태 반영, 닫기 후 overlay 해제, PLAY 선택값 commit helper를 검증한다. Stage 4/51/81 Buddy Preview는 동물명, 스킬명, 충전 조건/효과 설명과 후반 동물 한글명을 검증하고, Stage 1은 Buddy 영역을 숨기는지 검증한다. Gameplay smoke는 `rainbow_paw`, `striped`, `bomb` 선택값이 `GameSession`에서 한 번 소비되고 보드 특수 블록, `stage_start.selected_boosters`, `stage_start.start_boosters_applied`, `booster_used.source = pre_stage`로 이어지는지 검증한다. 남은 작업은 실제 기기에서 팝업 열기/닫기 애니메이션, 터치감, 시작 보드 판독성을 확인하는 것이다.
- 소유: QA Agent + Development Agent
- 대상 파일:
  - `scripts/validate_scene_loads.gd`
  - `data/analytics_events.json`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 작업:
  - 스테이지 노드 press가 바로 gameplay 전환 대신 Stage Popup으로 들어가는지 자동 검증한다.
  - Buddy가 있는 스테이지는 Stage Popup에 Rescue Buddy preview를 표시하고, Buddy가 없는 스테이지는 숨기는지 자동 검증한다.
  - 시작 부스터 3종 UI와 선택 상태를 자동 검증한다.
  - 선택 부스터가 gameplay 시작 시 보드 특수 블록과 analytics로 연결되는지 자동 검증한다.
- 완료 기준:
  - 자동 scene smoke가 Stage Popup/Pre-Booster 양성 경로를 통과한다.
  - 실제 기기 또는 시뮬레이터에서 팝업 애니메이션과 시작 보드 판독성 결과가 기록된다.

## P5. 기획 협의 승격 작업

### PAM-DEV-050: 스테이지 스키마 canonical 정리

- 상태: 완료됨. 원본 JSON은 `spawn_profile.pool/weights`, 런타임 정규화는 `animal_pool/spawn_weights`로 문서화했고, validator가 풀 밖 weight·목표 동물 누락·해금 전 등장을 분리 진단한다.
- 소유: Technical Lead
- 선행: `docs/planning/project-animal-match-planning-council-synthesis.md`
- 대상 파일:
  - `docs/dev/project-animal-match-technical-architecture.md`
  - `scripts/stage_catalog.gd`
  - `scripts/stage_data_validator.gd`
  - `data/stages/*.json`
- 작업:
  - 원본 JSON 기준은 `spawn_profile.pool/weights`, 런타임 정규화 기준은 `animal_pool/spawn_weights`로 명시한다.
  - validator 오류 문구와 문서 용어를 같은 방식으로 맞춘다.
  - 풀 밖 weight, 목표 동물 누락, 해금 전 등장 규칙을 분리해 진단한다.
- 완료 기준:
  - 개발자가 원본 데이터와 런타임 필드를 혼동하지 않는다.
- 검증:
  - `./scripts/validate_stage_data.sh`
  - `./scripts/validate_stage_balance.sh`

### PAM-DEV-051: SpecialEffectQueue와 조합 테스트

- 상태: 부분 완료. 인접한 non-rainbow 특수 블록끼리 교환하면 일반 매치가 없어도 유효 이동으로 처리되어 공통 특수 효과 큐를 먼저 해결한다. scene load smoke가 row+column 15칸 제거, row 경로 위 bomb 연쇄 21칸 제거, clear 경로 인접 장애물 피해, rainbow+special 우선순위 라우팅, row+row/column+column 8칸 중복 제거, row+bomb/column+bomb 14칸 합집합, bomb+bomb 12칸 합집합, 4매치 row/column 특수 생성, 5매치 rainbow 생성, T/L 교차 bomb 생성까지 headless fixture로 검증한다. runtime scene smoke는 Stage 31에서 row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb 6종 실제 `_resolve_swap` 경로의 이동 수 1회 소모, 점수 증가, 경로 장애물 제거, `is_busy` 복귀, playing 상태 유지, `special_combo_trigger` analytics의 조합 타입/제거 수/장애물 수를 검증한다. `FxLayer.play_special_combo` 전용 flash/ring/조합별 label VFX와 smoke 검증을 추가해 특수+특수 발동 시작점이 일반 매치 burst와 구분된다. 6종 조합별 beam/ring 형태를 분리했고, FX smoke가 각 라벨과 explosive 조합 echo ring, child count, cleanup을 검증한다. render snapshot smoke는 Stage 31 실제 `_resolve_swap` 발동 직후 6종을 portrait/landscape PNG로 저장하고 조합별 label/flash/ring 픽셀, filename combo type, `special_combo_trigger` payload, transient cleanup을 확인한다. Stage 31은 `combo_focus` + `recommended_smoke`로 31-40 특수 조합 밴드의 수동 smoke 진입점이 되며, balance validator가 이를 강제한다. 남은 작업은 실제 기기에서 6종 조합의 전용 flash/ring/label이 보드 판독을 해치지 않는지, 강한 사운드/햅틱/보드 shake가 과하지 않은지, 제거 후 낙하·리필이 자연스럽게 이어지는지 수동 QA로 판정하는 것이다.
- 소유: Development Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - 필요 시 `scripts/special_effect_queue.gd`
  - `scripts/validate_scene_loads.gd` 또는 신규 gameplay fixture
- 작업:
  - 처리 순서를 `특수+특수 조합 -> 단일 특수 발동 -> 일반 매치 제거`로 고정한다.
  - 4매치, L/T매치, 5매치, 특수+특수 조합, 장애물 피해를 검증 케이스로 만든다.
- 완료 기준:
  - 특수 조합 6종이 중복 제거 없이 1회씩 처리된다.

### PAM-DEV-052: FeverController MVP 구현

- 상태: 완료됨. Combo Gauge 보상 시 3회 이동 Fever가 켜지고, Fever 중 점수 2배와 목표 동물 수집 +1이 적용된다.
- 소유: Development Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/fx_layer.gd`
  - HUD 관련 씬/스크립트
- 작업:
  - 피버 지속을 `3회 플레이어 이동`으로 고정한다.
  - 피버 중 점수 2배와 목표 동물 수집량 +1을 적용한다.
  - 남은 피버 턴을 HUD에 표시한다.
- 완료 기준:
  - 피버 발동/연장/종료가 이동 수와 연쇄 처리에 끼어들지 않는다.

### PAM-DEV-053: Rescue Buddy 동물 스킬 시스템

- 상태: 완료됨. StageCatalog/validator가 `buddy` 설정을 정규화·검증하고, Stage 4의 `rabbit/quick_refill` 자동 1회 스킬이 목표 동물 매치 충전 후 보드에 목표 동물 1개를 생성한다. Stage 5의 `chick/soft_bomb_plus`는 목표 동물을 폭발 특수 블록으로 강화하고, Stage 8의 `chick/combo_peep`은 콤보 2+에서 Combo Gauge를 추가 충전하되 Fever 중에는 충전/준비 없이 `fever_active` 차단을 기록한다. Stage 16의 `cat/smart_hint`는 목표에 가까운 유효 수를 강조하며, Stage 18의 `frog/leap_clear`는 남은 덤불 1개를 추가 제거한다. Stage 20의 `dog/loyal_fetch`는 실패 직전 Near Miss에서 목표 동물을 불러오고 이동 1회를 구한다. Stage 24의 `panda/calm_fever`는 Fever 시작을 감지해 Fever 종료 후 Combo Gauge 2칸을 보존한다. Stage 25의 `pig/coin_sniff`는 클리어 보상 골드를 5% 늘리고, Stage 31의 `penguin/cascade_slide`는 첫 연쇄 단계에서 해당 연쇄 점수 10% 보너스를 더한다. Stage 41의 `fox/sly_route`는 이동 수 3 이하 Near Fail에서 추천 경로를 최대 2회 표시할 수 있다. Stage 51의 `lion/brave_start`는 하드 스테이지 시작 시 추천 부스터 방향을 알려주되 무료 특수 블록이나 부스터를 지급하지 않고 1회성으로 남는다. Stage 81의 `elephant/mighty_push`는 장애물 제거 흐름에서 남은 덤불 1개를 최대 2회 추가로 밀어낸다. 전용 HUD 충전 라벨/게이지와 scene smoke 검증이 추가됐다. scene smoke는 Stage 4 `quick_refill`의 `buddy_skill_charge/ready/trigger/blocked`와 중복 차단 억제, Stage 5 `soft_bomb_plus`의 post-use 차단, Stage 8 `combo_peep` 정상/피버 차단, Stage 16 `smart_hint`, Stage 18 `leap_clear`, Stage 20 `loyal_fetch`, Stage 24 `calm_fever`, Stage 25 `coin_sniff`, Stage 31 `cascade_slide`, Stage 41 `sly_route` 2회 튜닝, Stage 51 `brave_start`, Stage 81 `mighty_push` 2회 튜닝의 실제 상태 변화와 발동 분석 기록을 검증한다. stage data validator는 스킬별 동물/충전 규칙/충전량/최소 스테이지와 hard/finale 반복 충전 스킬의 최대 2회 사용 정책을 강제하고, balance validator는 첫 등장 Buddy smoke stage의 `recommended_smoke`를 강제한다. 후속은 실제 기기 수동 플레이 QA와 수치/체감 튜닝으로 분리한다.
- 소유: Development Agent + Planning Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - 필요 시 `scripts/animal_skill_controller.gd`
  - `data/stages/*.json`
- 작업:
  - 스테이지별 `buddy_animal`, `skill_id`, `charges_required`, `max_uses`를 읽는다.
  - MVP는 자동 발동을 기본 1회로 제한하고, hard/finale의 반복 충전 스킬만 최대 2회까지 허용한다.
- 완료 기준:
  - 스킬 없는 스테이지는 기존 플레이와 동일하고, 스킬 있는 스테이지는 최대 횟수를 초과하지 않는다.

### PAM-DEV-054: 결과/실패 near-miss 플로우

- 상태: 부분 완료. `FailOfferPolicy`가 Near Miss, Strategic Miss, First Fail, Repeat Fail, Hard Level Fail을 분류하고 Level 1-10 광고/IAP 제안을 차단한다. Near Miss 기준은 `near_miss_goal_threshold`와 `near_miss_progress_threshold` remote config 기본값으로 조정 가능하며 scene smoke가 튜닝 분기를 검증한다. Scene load smoke는 정책 단위에서 near miss, strategic miss, first fail, repeat fail, hard fail, 초반 수익화 차단을 검증하고, 실제 Gameplay runtime에서 Stage 1 클리어 오버레이의 보상/별/다음 CTA, Stage 1 FTUE 실패 오버레이의 무료 재도전/수익화 문구 차단, Stage 25 near-miss 실패 오버레이의 `+3 이동 받고 계속`/`재도전` CTA, `stage_fail`, `offer_impression`, `fail_offer_show`, `fail_offer_select`, `fail_offer_dismiss`, `ad_reward_complete`, `ad_reward_fail`, `iap_purchase_start`, `iap_purchase_complete`, `iap_purchase_restore`, `iap_purchase_cancel`, `iap_purchase_fail`, `extra_moves_grant`, `continue_stage` +3 이동 재개, 보조 CTA 재시도 복구, 광고 실패/IAP 취소·실패·복구/코인 continue 성공·부족 상태 보존, IAP 성공형 continue transaction 공유, 보상형 광고/IAP continue transaction idempotency를 검증한다. `MonetizationGateway`가 SDK 공급자 결정 전 rewarded/IAP/coin continue 요청을 provider-neutral 결과 콜백으로 정규화하고 request log를 남기며, `configure_continue_adapter(provider_id, Callable)` adapter hook은 queued validation 결과 우선, invalid source adapter 호출 전 거절, deep-copy payload/result normalization, `success`/`cancelled`/`in_progress`/unknown provider result alias canonicalization, provider pending 중복 CTA 차단을 scene smoke로 검증한다. 남은 작업은 선택된 광고/IAP SDK를 이 adapter 뒤에 실제 연결하고 실제 상품/영수증 복구 QA를 수행하는 것이다.
- 소유: Development Agent + UX Planning Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - 필요 시 `scripts/fail_offer_policy.gd`
  - `scripts/monetization_gateway.gd`
  - 결과/실패 팝업 씬
- 작업:
  - Near Miss, Strategic Miss, First Fail, Repeat Fail, Hard Level Fail을 분류한다.
  - Level 1-10에서는 하트 소모, 전면 광고, IAP 직접 제안을 차단한다.
- 완료 기준:
  - 실패 유형에 따라 CTA가 달라지고 비구매 선택지가 항상 보인다.
  - SDK 공급자 결정 전에는 실패 overlay가 직접 완료 호출에 의존하지 않고 provider-neutral monetization gateway stub을 통해 rewarded/IAP/coin 결과를 수신한다.

### PAM-DEV-055: 동물 해금/풀 회전 validator 강화

- 상태: 완료됨. `stage_data_validator.gd`가 lion/elephant 해금 전 투입을 오류로 막고, `validate_stage_balance.gd`가 밴드별 pool 4회 이상 반복과 해금 이후 등장 부족을 경고한다.
- 소유: Level Planning Agent + Development Agent
- 대상 파일:
  - `scripts/stage_data_validator.gd`
  - `scripts/validate_stage_balance.gd`
  - `data/stages/*.json`
- 작업:
  - `lion`은 Stage 51 이전, `elephant`는 Stage 81 이전 보드 풀 투입을 금지한다.
  - 한 밴드 안에서 같은 pool 조합이 4회 이상 반복되면 경고한다.
  - 해금 이후 각 동물이 충분히 반복 등장하는지 검사한다.
- 완료 기준:
  - 12종 로스터가 밴드 진행에서 실제로 회전한다.

### PAM-DEV-056: 튜토리얼 해금과 mechanics 정렬

- 상태: 완료됨. Stage 1-2는 basic_match만 허용하고, Stage 3-6은 line special, Stage 7은 rainbow, Stage 8+는 combo_gauge를 validator와 Stage 1-10 데이터/튜토리얼에 맞췄다.
- 소유: Planning Agent + Development Agent
- 대상 파일:
  - `data/stages/stages_001_010.json`
  - `scripts/stage_data_validator.gd`
- 작업:
  - Stage 1-2는 기본 매치, Stage 3부터 줄 제거, Stage 7부터 rainbow, Stage 8부터 combo gauge를 기준으로 문구와 mechanics를 맞춘다.
- 완료 기준:
  - 플레이어가 처음 보는 시스템과 튜토리얼 문구가 같은 스테이지에 있다.

### PAM-DEV-057: 난이도 태그와 회복 레벨 파형 도입

- 상태: 완료됨. 모든 스테이지 밴드에 `recovery`, `score_focus`, `blocker_focus`, `mixed_goal`, `master/finale` 태그 파형을 적용했고, balance validator가 recovery/blocker/finale coverage와 pressure streak을 검증한다.
- 소유: Level Planning Agent
- 대상 파일:
  - `data/stages/*.json`
  - `scripts/validate_stage_balance.gd`
- 작업:
  - `recovery`, `score_focus`, `blocker_focus`, `mixed_goal`, `finale`, `master` 태그를 도입한다.
  - 하드/마스터/피날레가 4개 이상 연속되면 경고한다.
- 완료 기준:
  - 후반 100레벨 진행에 회복 레벨과 피날레 리듬이 생긴다.

### PAM-DEV-058: Board Mask Topology Validator

- 상태: 완료됨. `StageDataValidator`가 각 stage `board_mask` active cell을 4방향 flood-fill로 검사해 하나의 연결 component인지 확인하고, 1-2칸짜리 고립 component는 match-3 플레이 공간으로 허용하지 않는다. `validate_stage_data.gd`는 disconnected mask와 1칸 island fixture가 반드시 실패하는 contract smoke를 포함한다.
- 소유: Development Agent + QA Agent
- 대상 파일:
  - `scripts/stage_data_validator.gd`
  - `scripts/validate_stage_data.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - production 100 stages는 topology 검사를 통과한다.
  - 분리된 active island, 1-2칸짜리 active component가 stage data validation에서 실패한다.
  - 향후 의도적 분리 섬/포털 규칙이 필요하면 별도 명시 필드와 런타임 해석을 먼저 추가해야 한다.

## P6. FTUE, 컬렉션, 운영 메타

### PAM-UX-060: FTUE 1-10레벨 동기 설계 확정

- 상태: 완료됨. `project-animal-match-ftue-rescue-book-spec.md`와 core design에 Level 1-10 학습 목표, 금지 수익화, Level 4 Rescue Book 해금, Level 5 첫 세션 보상 동기를 표로 고정했다.
- 소유: Planning Agent
- 대상 문서:
  - `docs/game/project-animal-match-core-design.md`
  - `docs/game/first-stage-flow.md`
  - `docs/planning/project-animal-match-ftue-rescue-book-spec.md`
- 작업:
  - Level 1-10 학습 목표, 금지 수익화, 첫 컬렉션 해금, 스타터 미션 해금 시점을 표로 확정한다.
- 완료 기준:
  - 첫 세션 목표가 Level 5까지 문서화된다.

### PAM-PLAN-061: 결정 레지스터 운영

- 상태: 완료됨. 구현 완료된 피버 충전, 첫 Rescue Buddy, 첫 Rescue Book 해금, 우정 보상, Near Miss 기준을 DEC-012~016으로 승격하고 남은 OPEN 안건을 SDK/시즌/에셋/확장 동물 순서로 정리했다.
- 소유: PM Lead + Planning Lead
- 대상 문서:
  - `docs/planning/project-animal-match-decision-register.md`
- 작업:
  - `OPEN-*` 항목을 구현 전 확정하거나 명시 보류한다.
  - 결정 변경 시 기획/기술/QA 문서를 함께 갱신한다.
- 완료 기준:
  - 피버, Rescue Buddy, Near Miss, 분석 SDK 같은 열린 결정이 구현 전 상태값을 가진다.

### PAM-PLAN-062: 시스템 규칙 매트릭스 동기화

- 상태: 완료됨. 시스템 규칙 매트릭스를 실제 Combo Gauge/Fever, `buddy_*` 런타임 필드, 현재 analytics contract 이벤트명과 동기화했다.
- 소유: Technical Lead + QA Lead
- 대상 문서:
  - `docs/planning/project-animal-match-system-rules-matrix.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 작업:
  - 시스템 규칙이 코드 조건, validator, QA 게이트와 같은 용어를 쓰도록 맞춘다.
  - 신규 구현 후 규칙 매트릭스를 회귀 체크리스트로 사용한다.
- 완료 기준:
  - 주요 시스템별 입력/출력/예외/QA 기준이 같은 문서에서 확인된다.

### PAM-DEV-060: Rescue Book 데이터 모델과 저장 구현

- 상태: 완료됨. `data/animals.json`, `CollectionState`, `GameSession` 저장 경로가 18종 해금/토큰/우정 레벨/장착 cosmetic/new badge를 저장·정규화하고, token 누적으로 friendship level이 상승한다. `rabbit`, `frog`, `koala`는 Lv.1-5 cosmetic friendship reward track을 가지며, 레벨 기준 보상을 자동 획득해 `earned_rewards`에 idempotent하게 저장한다. Stage clear는 첫 번째 목표 동물 1종에 첫 클리어 기준 `+3 tokens`를 지급하고 `stage_id:animal_id` claim key로 중복 지급을 막는다. `GameSession.add_rescue_book_tokens()`와 stage clear grant는 `animal_token_gain`과 `animal_friendship_level_up` analytics를 기록한다.
- 소유: Development Agent
- 대상 파일 후보:
  - 신규 `scripts/collection_state.gd`
  - 신규 `data/animals.json`
  - 저장 데이터 모듈
- 완료 기준:
  - 12종 동물 해금 상태, 토큰, 우정 레벨, 장착 cosmetic을 저장/로드한다.

### PAM-DEV-061: Rescue Book UI 구현

- 상태: 완료됨. `collection_screen`이 18종 카드의 잠김/해금/NEW/토큰/우정 레벨을 표시하고, 클릭/터치 시 상세 패널 갱신 및 NEW 배지 확인 처리를 수행한다. Reward track이 있는 동물은 카드에 보상 획득 수를 표시하고 상세에 Lv.1-5 `획득`/`대기` cosmetic 보상 트랙을 텍스트로 보여 준다.
- 소유: Development Agent + Art Agent
- 대상 파일 후보:
  - 신규 `scenes/collection_screen.tscn`
  - 신규 `scripts/collection_screen.gd`
- 완료 기준:
  - 12종 카드가 잠김/해금/신규 상태를 표시하고, 표정 미리보기를 성능 제한 안에서 보여 준다.

### PAM-DEV-063: Rescue Book Cosmetic Equip MVP

- 상태: 완료됨. `CollectionState.reward_entry_by_id()`와 `GameSession.equip_rescue_book_cosmetic()`이 해금 동물의 획득한 friendship cosmetic reward만 대표 `equipped_cosmetic` 슬롯에 저장하고, 성공 시 `animal_cosmetic_equip` analytics를 기록한다. `collection_screen` 상세 영역은 획득 reward를 장착 버튼으로 표시하고, 장착 중/미획득 상태를 disabled 버튼으로 구분한다. Scene smoke는 `rabbit` 40토큰 fixture에서 `rabbit_sprout_frame` 장착, save persistence, 중복/미획득 장착 차단, 카드 라벨/버튼 상태, analytics payload를 검증한다.
- 소유: Development Agent + QA Agent
- 대상 파일:
  - `scripts/collection_state.gd`
  - `scripts/game_session.gd`
  - `scripts/collection_screen.gd`
  - `data/analytics_events.json`
  - `scripts/validate_scene_loads.gd`
- 완료 기준:
  - 획득한 cosmetic reward만 장착 가능하다.
  - 같은 cosmetic 재장착과 미획득 reward 장착은 저장 상태와 analytics를 바꾸지 않는다.
  - 실제 cosmetic 아트 적용, 홈/보드/프로필 반영, 타입별 동시 장착은 후속 작업으로 분리한다.

### PAM-DEV-064: Equipped Cosmetic Visual Application MVP

- 상태: 완료됨. Rescue Book 카드가 장착된 friendship cosmetic을 ID 텍스트만이 아니라 카드 비주얼로 표시한다. `rabbit_sprout_frame`처럼 `card_frame` 타입 reward가 장착되면 카드 테두리/그림자와 `장착 프레임` 배지가 적용되고, 카드 metadata에 `equipped_cosmetic`/`equipped_cosmetic_type`이 남아 scene smoke와 render snapshot이 회귀를 잡는다.
- 소유: Development Agent + Art Agent + QA Agent
- 대상 파일:
  - `scripts/collection_screen.gd`
  - `scripts/validate_scene_loads.gd`
  - `scripts/validate_render_snapshots.gd`
- 완료 기준:
  - 획득 후 장착된 `rabbit_sprout_frame`이 Rescue Book 카드에서 `장착 프레임` 배지와 frame 스타일로 보인다.
  - 선택/NEW/잠김 카드 상태와 충돌하지 않고 상세 `장착중` 버튼 상태와 저장 metadata가 일치한다.
  - no-device scene smoke와 render snapshot이 장착 frame badge, card metadata, 버튼 상태를 함께 검증한다.

### PAM-DEV-070: 실패 유형 분류와 제안 정책 구현

- 상태: 완료됨. `FailOfferPolicy`가 Near Miss, Strategic Miss, First Fail, Repeat Fail, Hard Level Fail을 분류하고, Level 1-10 광고/IAP/하트 제안 차단과 실패 횟수 저장 기반 반복 실패 분기를 검증한다.
- 소유: Development Agent + UX Planning Agent
- 대상 파일 후보:
  - `scripts/gameplay.gd`
  - 신규 `scripts/fail_offer_policy.gd`
  - 원격 설정 모듈
- 완료 기준:
  - 실패 유형별 CTA와 광고/IAP 제안 조건이 레벨 구간별로 다르게 동작한다.

### PAM-DEV-080: 라이브 이벤트 템플릿과 원격 설정 연결

- 상태: 완료됨. `data/events/live_events.json` 템플릿과 `data/events/remote_config.json`을 `LiveEventService`에 연결해 이벤트 해금 레벨/노출 위치를 원격 설정값으로 검증·조회한다. 홈/스테이지 선택에는 `LiveEventStrip` 노출면을 두고, 홈/스테이지 선택/결과 오버레이/컬렉션 이벤트 노출은 `live_event_impression`으로 기록한다. 홈 이벤트 상세 overlay는 이벤트 참여, 미션형 보상 집계, 보상 수령 완료 상태를 제공하며 `GameSession`의 `live_events`와 wallet에 idempotent하게 저장한다. 이벤트 기간 상태(`upcoming`, `active`, `ended`, `disabled`, `offline`)와 원격 설정 기본값 fallback, 세션별 `remote_config_exposure` 기록도 자동 검증한다. 홈/스테이지 선택 칩, 홈 상세, 결과 오버레이, 컬렉션 상세 문구는 시작 전/진행 중/종료/오프라인 상태를 사용자-facing 텍스트로 노출한다.
- 소유: Development Agent + Ops Agent
- 대상 파일 후보:
  - 신규 `data/events/*.json`
  - 신규 `scripts/live_event_service.gd`
  - 원격 설정 모듈
- 완료 기준:
  - Daily Reward, Starter Missions, Collection Event, Season Pass 해금 레벨과 노출 위치가 데이터로 제어된다.
  - 홈 이벤트 상세에서 `event_join`, `event_progress`, `event_reward_claim` 계약과 중복 수령 방지 검증이 통과한다.
  - 원격 설정 노출은 `remote_config_exposure`로 기록되고, 이벤트 기간/오프라인 fallback 상태와 사용자-facing 상태 문구가 scene smoke에서 검증된다.

### PAM-LIVEOPS-081: Live Ops Remote Config Contract Validator

- 상태: 완료됨. `scripts/validate_liveops_config.gd`/`.sh`가 `data/events/remote_config.json`과 `data/events/live_events.json`을 `LiveEventService` 계약에 맞춰 독립 검증한다. 필수 remote config/exposure key, event type별 unlock key, tuning 값 범위, placement coverage, enabled 이벤트의 unlock 전/후 query 결과, offline fallback status, disabled `season_pass` 비노출, `remote_config_exposure` 필수 payload와 세션 중복 방지를 검사한다. `validate_gameplay.sh`와 no-device CI가 이 gate를 실행한다.
- 소유: Development Agent + QA Agent + PM Lead
- 대상 파일:
  - `data/events/remote_config.json`
  - `data/events/live_events.json`
  - `scripts/live_event_service.gd`
  - `scripts/validate_liveops_config.gd`
  - `scripts/validate_liveops_config.sh`
  - `scripts/validate_gameplay.sh`
  - `.github/workflows/no-device-alpha-gate.yml`
  - `docs/planning/project-animal-match-decision-register.md`
  - `docs/planning/project-animal-match-analytics-remote-config-spec.md`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - LiveOps data/config 회귀가 scene smoke에 도달하기 전 독립 gate에서 실패한다.
  - `season_pass` 해금 레벨은 `season_pass_unlock_level` 원격 설정으로 제어하고, 실제 store product/SDK evidence 전까지 alpha fixture는 disabled 상태를 유지한다.
  - 이 gate는 실제 live backend, store product, Ads/IAP/Analytics SDK provider credentials QA를 대체하지 않는다.

### PAM-ANA-090: 분석 이벤트 계약 검증기 추가

- 상태: 완료됨. `data/analytics_events.json`와 `scripts/validate_analytics_contract.gd`가 앱/스테이지/오퍼/이벤트/Fever/Buddy/Collection 필수 이벤트와 파라미터를 검증한다. `GameSession`은 런타임 이벤트 필수 파라미터 누락을 경고하고, provider-neutral `AnalyticsGateway`에 저장된 이벤트를 dispatch한다. scene smoke가 `stage_start`, `rescue_book_open`, Level 1-5 첫 세션 카드 해금의 `animal_unlock`, Rescue Book 토큰/우정 보상의 `animal_token_gain`/`animal_friendship_level_up`, 활성 live ops 노출의 `live_event_impression`, 이벤트 참여/진행/보상 수령의 `event_join`, `event_progress`, `event_reward_claim` 실제 기록과 gateway `local_buffer` queued dispatch, disk reload 보존, 순차 flush 후 pending queue 제거, `configure_flush_adapter(provider_id, Callable)` SDK adapter hook, adapter partial failure, adapter payload mutation guard, corrupt queue tolerance, 320개 bounded queue eviction, 계약 위반 이벤트의 `rejected_contract` 격리를 검사한다.
- 소유: Technical Lead + QA Agent
- 대상 파일 후보:
  - `docs/planning/project-animal-match-analytics-remote-config-spec.md`
  - 신규 `scripts/validate_analytics_contract.gd`
  - 신규 `scripts/analytics_gateway.gd`
  - 신규 `data/analytics_events.json`
- 완료 기준:
  - 필수 이벤트명과 필수 파라미터 누락을 검증한다.

### PAM-ART-091: 동물 로스터/표정 애니메이션 제작 매트릭스 반영

- 상태: 완료됨. `data/animals.json`은 보드 12종/컬렉션 18종을 `board_enabled`와 `collection_enabled`로 분리하고, `data/animal_animation_profiles.json`과 아트 문서가 `blink/smile/match/fever/worried` 및 13프레임 이하 MVP 제작 규칙을 추적한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 문서/파일 후보:
  - `docs/planning/project-animal-match-animal-roster-animation-matrix.md`
  - `docs/art/project-animal-match-visual-style-guide.md`
  - `docs/art/project-animal-match-animation-vfx.md`
  - 신규 `data/animals.json`
  - 신규 `data/animal_animation_profiles.json`
- 작업:
  - MVP 보드 동물 12종의 `blink`, `smile`, `match`, `fever`, `worried` 표현 방향을 에셋 제작 티켓으로 분리한다.
  - 컬렉션/이벤트 예비 동물 6종을 Rescue Book 카드 기준으로 먼저 준비한다.
  - `board_enabled`와 `collection_enabled`를 분리해 보드 투입 전 컬렉션 노출을 허용한다.
  - 동물당 13프레임 이하 MVP 제작량과 atlas 분할 규칙을 유지한다.
- 완료 기준:
  - 개발 에이전트가 12종 보드 로스터와 18종 컬렉션 로스터를 데이터로 구분할 수 있다.
  - QA 에이전트가 동물별 blink/smile/match/fever/worried 검수 항목을 추적할 수 있다.

### PAM-PLAN-092: 레벨 진행 콘텐츠 바이블과 스테이지 데이터 동기화

- 상태: 완료됨. Stage data에 `difficulty_tag`, `teaches`, `previews`, `recommended_smoke`, `forbidden_monetization` 메타 필드를 도입했고 StageCatalog가 이를 정규화한다. Validator는 FTUE 1-10 수익화 금지, 핵심 학습 키, 난이도 태그 mirror 규칙을 검사하며 balance validator는 Stage 1/5/10/20/51/81/100 QA smoke coverage를 강제한다.
- 소유: Level Planning Agent + Development Agent + QA Agent
- 대상 문서/파일:
  - `docs/planning/project-animal-match-level-progression-content-bible.md`
  - `data/stages/*.json`
  - `scripts/validate_stage_balance.gd`
- 작업:
  - Stage 1-10이 FTUE 표의 학습 순서, 금지 수익화, 동물 풀과 충돌하지 않는지 확인한다.
  - 10스테이지 밴드별 `roster_group`, 새 동물 예고, hard/recovery/finale 파형을 점검한다.
  - `lion`, `elephant`, 13-18번 컬렉션 동물의 보드 투입 금지 조건을 validator 경고/오류로 확장한다.
  - `difficulty_tag`, `teaches`, `previews`, `recommended_smoke` 필드 도입 여부를 결정한다.
- 완료 기준:
  - 레벨 데이터 수정 에이전트가 밴드별 기획 의도를 보면서 stage JSON을 조정할 수 있다.
  - 밸런스 검증이 해금 순서와 hard/recovery 파형 위반을 잡을 수 있다.

### PAM-PLAN-117: Collection Animal Board Expansion Order Contract

- 상태: 완료됨. `OPEN-009`를 `DEC-021`로 승격하고 13-18번 컬렉션 동물의 시즌 1 보드 투입 후보 순서를 `koala -> hamster -> deer -> seal -> sheep -> turtle`로 고정했다. `data/animals.json`은 각 후보에 `board_expansion_order`, `board_candidate_min_stage`, `board_candidate_stage_band`를 보유하지만, 현재 alpha에서는 모두 `board_enabled=false`를 유지한다. `StageDataValidator`는 이 6종이 stage JSON의 `spawn_profile.pool`, `spawn_profile.weights`, 목표, Buddy 설정에 들어가면 명시적으로 실패한다.
- 소유: Planning Agent + Development Agent + QA Agent
- 대상 파일:
  - `data/animals.json`
  - `scripts/stage_data_validator.gd`
  - `scripts/validate_stage_data.gd`
  - `scripts/validate_scene_loads.gd`
  - `docs/planning/project-animal-match-decision-register.md`
  - `docs/planning/project-animal-match-level-progression-content-bible.md`
  - `docs/planning/project-animal-match-animal-roster-animation-matrix.md`
  - `docs/dev/project-animal-match-technical-architecture.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - `OPEN-009`가 더 이상 미결정 항목으로 남지 않는다.
  - `validate_stage_data.sh`가 board-disabled collection animal pool/target negative fixture를 실패시킨다.
  - scene smoke가 6개 launch collection 후보의 순서와 candidate band metadata를 검증한다.

## P7. 릴리즈 준비도

### PAM-REL-101: Android Export Identity / Release Preflight Validator

- 상태: 완료됨. Android export preset을 `Zoo-Zoo Pop`, `com.shinehandmac.zoozoopop`, `build/android/zoo-zoo-pop-debug.apk`로 고정했고, `scripts/validate_android_export_config.sh`가 앱명/package id/export path/version/signed/vibrate/arm64 및 starter placeholder 회귀를 검증한다. `validate_gameplay.sh`와 no-device alpha CI가 이 preflight를 실행하며, alpha QA template/report validator와 Android export helper의 기본 APK path도 `zoo-zoo-pop` 기준으로 맞췄다. 남은 승인 조건은 release keystore로 실제 release APK를 생성하고 Android 실기기 설치/실행 evidence를 기록하는 것이다.
- 소유: PM Lead + Development Agent + QA Agent
- 대상 파일:
  - `export_presets.cfg`
  - `scripts/validate_android_export_config.sh`
  - `scripts/validate_gameplay.sh`
  - `.github/workflows/no-device-alpha-gate.yml`
  - `scripts/export_android_debug.sh`
  - `scripts/export_android_release.sh`
  - `scripts/record_manual_device_checks.sh`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - Android preset placeholder가 자동 검증에서 실패한다.
  - no-device CI와 로컬 gameplay gate가 같은 export identity 기준을 사용한다.
  - 실제 keystore, APK export, 실기기 install/run은 별도 device evidence gate로 남는다.

### PAM-QA-102: Alpha QA Report Validator Contract Smoke

- 상태: 완료됨. `scripts/validate_alpha_qa_report_contract.sh`가 임시 alpha report/evidence fixture를 생성해 `validate_alpha_qa_report.sh`의 PASS 계약과 negative fixture 실패 계약을 자동 검증한다. PASS fixture는 현재 HEAD, `Overall result: Pass`, `QA result: Approve`, 필수 evidence content와 evidence 내부 commit을 채우고, negative fixture는 `Pending` 잔존, evidence 누락, Rescue Book cosmetic equip 필수 행 삭제, wrong report commit, stale debug/release/device/manual evidence commit, placeholder evidence commit, `Capture result: BLOCKED`, release `Install result: NOT_REQUESTED`가 반드시 실패하는지 확인한다. `validate_gameplay.sh`와 no-device CI는 이 contract smoke를 포함한다.
- 소유: QA Agent + Development Agent
- 대상 파일:
  - `scripts/validate_alpha_qa_report_contract.sh`
  - `scripts/validate_gameplay.sh`
  - `scripts/validate_alpha_qa_report.sh`
  - `docs/qa/templates/alpha-lock-pass-manual-qa-template.md`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - 최종 alpha report validator가 허술해져 unresolved 결과나 빈 evidence를 통과시키는 회귀가 no-device에서 잡힌다.
  - 보고서 metadata뿐 아니라 Android export/device/manual evidence 내부 commit이 현재 HEAD와 맞지 않으면 실패한다.
  - 실제 기기/keystore/SDK evidence는 여전히 최종 report와 device evidence gate에서 별도 승인한다.

### PAM-QA-105: Android QA Helper Contract Smoke

- 상태: 완료됨. `scripts/validate_android_qa_helpers_contract.sh`가 debug export, release export, device capture, manual device checks helper의 dry-run PASS 계약과 negative 계약을 검증한다. 검사 범위는 debug/device/manual/release dry-run path 해석, legacy release env alias, release password non-leak, unknown option 실패, 빈 output/package/preset 경로 실패, `--video-seconds` 범위 실패, manual tester/result 누락 실패, release signing env 누락 실패, dry-run artifact 미생성을 포함한다. `validate_gameplay.sh`와 no-device CI가 이 smoke를 실행한다.
- 소유: Development Agent + QA Agent + PM Lead
- 대상 파일:
  - `scripts/validate_android_qa_helpers_contract.sh`
  - `scripts/validate_gameplay.sh`
  - `.github/workflows/no-device-alpha-gate.yml`
  - `scripts/export_android_debug.sh`
  - `scripts/export_android_release.sh`
  - `scripts/capture_android_device_evidence.sh`
  - `scripts/record_manual_device_checks.sh`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - Android QA helper CLI가 실제 기기/서명 도구 없이도 dry-run 계약을 안정적으로 보고한다.
  - 잘못된 입력, release env 누락, release password 출력 회귀가 no-device에서 실패한다.
  - dry-run helper contract는 실제 release keystore, APK export, Android install/launch, screenshot/video/logcat, human device PASS evidence를 대체하지 않는다는 caveat를 유지한다.

### PAM-REL-103: Provider Readiness Manifest / Validator

- 상태: 완료됨. `data/provider_readiness.json`이 analytics `local_buffer`와 monetization `local_simulator`의 provider-neutral 상태를 machine-readable manifest로 고정하고, `scripts/validate_provider_readiness.gd`/`.sh`가 코드 상수와 manifest를 대조한다. 검증은 `OPEN-007` 실제 SDK 선택을 완료하지 않고, SDK 연결 전 adapter hook, source/result canonicalization, `provider_result` 보존, rejected_contract/rejected_invalid_source, queue/request log 상한이 흔들리지 않게 막는다. `validate_gameplay.sh`와 no-device alpha CI가 이 gate를 실행한다.
- 소유: Development Agent + QA Agent + PM Lead
- 대상 파일:
  - `data/provider_readiness.json`
  - `scripts/validate_provider_readiness.gd`
  - `scripts/validate_provider_readiness.sh`
  - `scripts/validate_gameplay.sh`
  - `.github/workflows/no-device-alpha-gate.yml`
  - `docs/planning/project-animal-match-decision-register.md`
  - `docs/planning/project-animal-match-analytics-remote-config-spec.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - provider readiness manifest가 analytics/monetization gateway 코드 상수와 일치한다.
  - 실제 SDK credentials, Android device, release keystore 없이 no-device CI에서 provider-neutral 준비 계약을 검증한다.
  - 실제 Firebase/GameAnalytics/광고/IAP SDK 선택과 production credential QA는 `OPEN-007` 및 alpha device evidence gate로 남는다.

### PAM-QA-104: No-device Render Snapshot Smoke

- 상태: 완료됨. `scripts/validate_render_snapshots.gd`/`.sh`가 Home, Home Settings Overlay ON/OFF, Home Live Event ended detail, Stage Select World Map, Stage Select World Progress, Stage Popup, Stage 4 Gameplay Buddy HUD 4상태, Stage 1 성공 결과 overlay, Stage 25 실패 overlay, Stage 31 특수 조합 6종, Collection을 `390x844`와 `844x390` PNG 정확히 40장으로 저장하고 파일 크기, viewport 크기, non-blank/varied pixel, 핵심 UI region 렌더 픽셀을 검증한다. Home Settings Overlay 스냅샷은 ON/OFF 상태별 설정 panel, title, auto-save summary, sound/haptics toggle, close CTA의 픽셀, bounds, 텍스트, 최소 이미지 크기를 확인한다. Stage Select World Progress 스냅샷은 Stage 1-3 클리어, Stage 4 current, Stage 5 locked fixture에서 current ring/PLAY ribbon, cleared star tray, locked badge, finale ribbon, 하단 선택 패널 비겹침을 확인한다. Home Live Event ended detail 스냅샷은 이벤트 상세 overlay, 상태 배지, 진행 카드, 보상 칩, disabled `종료됨` CTA를 확인한다. Stage 4 Buddy 스냅샷은 0/3, 2/3, 출동, 완료 상태의 라벨/게이지/landscape `LandscapeHudShell`/combo text와 `buddy_skill_charge`/`buddy_skill_ready`/`buddy_skill_trigger` payload를 확인한다. Stage 1 성공 스냅샷은 실제 클리어 후 보상/별/Zoo-Zoo Time/다음 CTA/홈 CTA와 `stage_complete`/Stage 2 해금을 확인한다. Stage 31 조합 스냅샷은 실제 `_resolve_swap`을 시작한 직후 조합별 label/flash/ring 픽셀, echo ring 필요 여부, filename combo type, `special_combo_trigger` analytics payload, transient VFX cleanup을 함께 확인한다. Collection 스냅샷은 `rabbit` 40토큰과 `rabbit_sprout_frame` 장착 fixture의 상세 reward track, `CosmeticEquipGrid`, `장착중` 버튼 region을 확인한다. 로컬 또는 지원되는 Xvfb 환경에서는 blocking으로 실행하고, GitHub-hosted no-device CI는 Xvfb renderer 실패가 전체 gate를 막지 않도록 non-blocking artifact attempt로 실행한다.
- 소유: QA Agent + Development Agent
- 대상 파일:
  - `scripts/validate_render_snapshots.gd`
  - `scripts/validate_render_snapshots.sh`
  - `scripts/validate_gameplay.sh`
  - `.github/workflows/no-device-alpha-gate.yml`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - no-device gate가 blank/transparent/offscreen/missing texture 회귀를 PNG snapshot과 pixel smoke로 잡는다.
  - snapshot artifact는 실기기 screenshot/video/logcat evidence를 대체하지 않는다는 caveat를 유지한다.

### PAM-QA-111: Commercial UI Readability & Touch Target Gate

- 상태: 완료됨. `scripts/validate_scene_loads.gd`의 mobile viewport matrix가 홈, 월드맵, Stage Popup, gameplay HUD/실패 overlay, Rescue Book의 핵심 상용 CTA에 대해 최소 터치 타깃, viewport bounds, CTA 텍스트/아이콘 식별, 버튼 대비를 검증한다. 기준은 primary CTA `144x48`, secondary CTA `88x44`, icon/stage node `44x44`, enabled 버튼 contrast `3.0:1`, disabled 버튼 contrast `2.0:1`이며, 전역 버튼 스캔 대신 실제 플레이 흐름의 핵심 CTA만 명시적으로 검사한다. Rescue Book cosmetic equip 버튼은 `44px` 높이로 상향했다.
- 소유: QA Agent + Art Agent + Development Agent
- 대상 파일:
  - `scripts/validate_scene_loads.gd`
  - `scripts/collection_screen.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - 핵심 CTA가 390x844/844x390을 포함한 viewport matrix에서 상용 터치 면적과 기본 대비를 만족한다.
  - Stage node, icon-only booster처럼 텍스트 대신 자식 라벨/아이콘/tooltip을 쓰는 버튼은 오탐 없이 식별성을 검증한다.
  - no-device scene smoke와 `validate_gameplay.sh`가 CTA 크기·대비 회귀를 실패시킨다.

### PAM-UX-112: Commercial Gameplay HUD Layout Polish

- 상태: 완료됨. 세로 gameplay HUD에 목표를 문장형 설명 대신 `HudGoalChipRow`의 동물/장애물/점수 칩으로 압축 표시하고, Stage Popup portrait 카드를 넓혀 목표, Buddy, 부스터, `PLAY` CTA가 상용 캐주얼 퍼즐처럼 한눈에 읽히도록 조정했다. 가로 gameplay는 보드 타일을 키우고 사이드바가 남은 폭을 과점하지 않도록 고정 폭 rail로 정리해 보드가 화면의 주인공으로 남는다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/stage_select.gd`
  - `scripts/validate_scene_loads.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - `390x844` render snapshot에서 gameplay 목표가 칩형 HUD로 읽히고 Stage Popup이 좁은 정보 상자가 아니라 상용형 start card 폭을 가진다.
  - `844x390` render snapshot에서 BoardFrame이 빈 tray로 늘어나지 않고 사이드바가 화면 절반을 점유하지 않는다.
  - scene smoke가 Stage Popup portrait 최소 폭, `HudTopDock`/`HudGoalDock`/`HudBoosterDock` bounds, landscape BoardFrame 과신장 방지를 검증한다.

### PAM-UX-113: Commercial Result Overlay Density Polish

- 상태: 완료됨. 결과/실패 overlay를 상용 캐주얼 퍼즐의 보상 카드처럼 읽히도록 넓히고, mascot/ribbon 비중을 줄여 본문과 CTA에 공간을 돌렸다. 성공 본문은 별점, 보상, 도감 토큰, Zoo-Zoo 보너스, 다음 행동 중심으로 압축했고, 실패 본문은 한국어 상태 문구, 남은 목표, 놓친 핵심, 다음 한 수, 추천 offer만 남겨 디버그 로그처럼 보이던 줄 수를 줄였다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/validate_scene_loads.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - Stage 1 성공 overlay와 Stage 25 실패 overlay가 `390x844`에서 핵심 정보와 CTA 중심으로 읽힌다.
  - scene smoke가 성공/near-miss 실패 overlay 본문을 6개 이하의 visible line으로 제한해 문구 과밀 회귀를 차단한다.
  - 기존 보상/별/다음 CTA, 도감 토큰, Zoo-Zoo Time 문구 계약은 유지하고, 실패 유형/booster id/rewarded offer 계약은 화면 본문이 아니라 metadata 검증으로 유지한다.

### PAM-UX-114: Collection Album & Stage Popup Landscape Polish

- 상태: 완료됨. `canvas_items` stretch의 landscape 논리 viewport에서 고정 px가 작게 보이던 문제를 비율 기반 레이아웃으로 정리했다. Collection landscape는 납작한 3열 row가 아니라 6열 앨범 그리드로 바꾸고, 이름/상태는 Button형 표시 칩으로 렌더 안정성을 확보했다. Stage Popup landscape는 화면 중앙의 큰 상용 start modal로 키우고 `PLAY` CTA가 booster보다 강하게 보이도록 폭, 높이, font, 버튼 높이를 상향했다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/collection_screen.gd`
  - `scripts/stage_select.gd`
  - `scripts/validate_scene_loads.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - `844x390` render snapshot에서 Collection이 얇은 표가 아니라 6열 앨범 카드 그리드로 보이고, 동물명/상태/장착 배지가 판독된다.
  - `844x390` Stage Popup에서 panel이 화면 중심의 상용 modal 크기를 가지며 `PLAY`가 가장 강한 CTA로 보인다.
  - scene smoke가 Collection 카드/preview collapse, Stage Popup landscape panel 크기, `PLAY` CTA 높이 회귀를 차단한다.

### PAM-UX-115: Home & World Map First Impression Polish

- 상태: 완료됨. Home의 `HomeActionPanel`, `HomePlayButton`, 동물 preview strip, 경로 노드를 viewport 비율 기반으로 키워 `canvas_items` stretch landscape에서 PLAY가 작은 개발용 버튼처럼 보이던 문제를 줄였다. Stage Select World Map의 하단 선택 패널과 `WorldPlayButton`도 landscape 논리 viewport에서 실제 PNG 픽셀 크기가 유지되도록 상향했고, render snapshot smoke에 `stage_select_world_map` 시나리오를 추가해 popup이 닫힌 기본 월드맵, `WorldMapPathRoot`, `WorldPlayButton`, 10개 `WorldStageNode*` 렌더를 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/main.gd`
  - `scripts/stage_select.gd`
  - `scripts/validate_render_snapshots.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - `390x844`, `844x390` Home snapshot에서 PLAY CTA가 첫 화면의 주 행동으로 읽히고, 동물 preview와 경로 노드가 지나치게 작아지지 않는다.
  - `390x844`, `844x390` Stage Select World Map snapshot에서 popup이 닫힌 기본 월드맵, 10개 stage node, 하단 `PLAY` CTA가 렌더된다.
  - render snapshot smoke가 Home/World Map `PLAY` CTA의 실제 PNG 이미지 크기 회귀를 차단한다.

### PAM-UX-116: Gameplay Landscape Unified HUD Shell

- 상태: 완료됨. Gameplay landscape의 우측 정보 영역을 `LandscapeHudShell` 하나로 감싸 목표, 이동 수, 콤보, 버튼이 흩어진 카드 묶음이 아니라 하나의 캔디풍 플레이 HUD 패널로 읽히게 했다. 내부 `StatsCard`/`GoalCard`는 투명도가 높은 섹션 카드로 낮추고, shell 폭을 viewport 비율 기반 compact rail로 제한해 보드가 계속 화면의 주인공으로 남는다. render snapshot gate는 Stage 4 Buddy landscape 스냅샷에서 shell 픽셀, viewport bounds, BoardFrame 비겹침을 확인하고, `.sh`는 현재 시나리오 수와 같은 PNG 40장 정확 매칭으로 누락 회귀를 막는다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/validate_scene_loads.gd`
  - `scripts/validate_render_snapshots.gd`
  - `scripts/validate_render_snapshots.sh`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - `844x390` Stage 4 gameplay snapshot에서 `LandscapeHudShell`이 보드와 겹치지 않고 하나의 compact HUD panel로 렌더된다.
  - mobile viewport matrix가 landscape shell 폭, bounds, BoardFrame 비겹침을 검증한다.
  - render snapshot smoke가 정확히 40개 PNG 산출을 요구해 Home/Settings/LiveOps/World Map/Gameplay/Collection snapshot 누락을 실패시킨다.

### PAM-LIVEOPS-118: Home Event Detail Commercial Render Snapshot

- 상태: 완료됨. Home live event 상세 overlay를 단일 본문 로그에서 상태 배지, 이벤트 메타, 진행 카드, 보상 칩 row, 강한 수령 CTA가 있는 상용 이벤트 카드 구조로 정리했다. `home_live_event_ended_detail` render snapshot은 `active`/`offline`/`upcoming`/`ended` 상태 배지와 CTA 계약을 확인한 뒤 종료 이벤트 fixture를 열어 `EventDetailOverlay`, `EventDetailStatusBadge`, `EventDetailProgressCard`, `EventRewardChipRow` 보상 텍스트, disabled `EventClaimButton`의 `종료됨` 상태를 `390x844`와 `844x390` PNG로 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/main.gd`
  - `scripts/validate_render_snapshots.gd`
  - `scripts/validate_render_snapshots.sh`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - Home 이벤트 상세가 active/upcoming/ended/offline 상태를 상태 배지와 CTA 상태로 즉시 구분한다.
  - 종료 이벤트 상세에서는 reward chip이 렌더되지만 claim CTA가 `종료됨` disabled 상태다.
  - render snapshot smoke가 정확히 40개 PNG를 요구하며 이벤트 상세 시나리오 누락을 실패시킨다.

### PAM-UX-119: Stage Select World Progress Commercial Polish

- 상태: 완료됨. Stage Select World Map 노드를 숫자 중심 버튼에서 current ring/PLAY ribbon, cleared star tray, locked badge, finale ribbon을 가진 캔디풍 진행 지도 노드로 정리했다. Portrait에서는 경로 노드 영역을 하단 `WorldSelectedPanel` 위로 올리고 하단 CTA 패널 높이를 줄여 진행 경로가 첫 화면의 주인공으로 보이게 했다. `stage_select_world_progress` render snapshot은 Stage 1-3 클리어, Stage 4 current, Stage 5 locked fixture를 열어 상태별 노드 장식과 하단 선택 패널 비겹침을 `390x844`와 `844x390` PNG로 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/stage_select.gd`
  - `scripts/validate_render_snapshots.gd`
  - `scripts/validate_render_snapshots.sh`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - Stage Select World Map에서 현재/클리어/잠김/피날레 상태가 각각 별도 장식으로 즉시 구분된다.
  - Portrait에서 하단 선택 패널이 주요 경로 노드와 겹치지 않는다.
  - render snapshot smoke가 정확히 40개 PNG를 요구하며 진행 상태 시나리오 누락을 실패시킨다.

### PAM-UX-120: Home Settings Overlay Commercial Snapshot

- 상태: 완료됨. Home Settings overlay를 밝은 캔디풍 옵션 카드로 맞추고, summary를 `자동 저장됨` 중심으로 줄이며, sound/haptics toggle을 ON/OFF 상태별 pill 스타일로 구분했다. `home_settings_overlay`와 `home_settings_overlay_off` render snapshot은 ON/OFF 상태별 설정 panel, title, auto-save summary, sound/haptics toggle, close CTA의 픽셀, bounds, 텍스트, 최소 이미지 크기를 `390x844`와 `844x390` PNG로 검증한다. scene smoke는 overlay를 실제로 열어 내부 toggle/close CTA의 viewport bounds와 secondary touch target도 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/main.gd`
  - `scripts/validate_render_snapshots.gd`
  - `scripts/validate_render_snapshots.sh`
  - `scripts/validate_scene_loads.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
- 완료 기준:
  - Settings overlay가 개발용 텍스트 패널이 아니라 상용 옵션 카드로 보인다.
  - sound/haptics toggle과 close CTA가 표시, bounds, 텍스트, 최소 터치 타깃 검증을 통과한다.
  - render snapshot smoke가 정확히 40개 PNG를 요구하며 settings overlay 시나리오 누락을 실패시킨다.

### PAM-UX-121: Stage Popup Commercial Start Card Polish

- 상태: 완료됨. Stage Popup을 목표/스테이지 메타/보상/Rescue Buddy 정보가 한눈에 분리되는 캔디풍 start card로 보정했다. 목표 영역은 초록 goal chip, 스테이지 정보는 하늘색 status chip, 보상은 노랑 reward chip, buddy 안내는 하늘색 helper chip으로 읽히게 했고, `PLAY` CTA와 title typography를 세로/가로 viewport별로 키웠다. 기존 `stage_popup` render snapshot과 scene mobile matrix가 panel, buddy label, booster buttons, close, PLAY CTA bounds/touch target을 계속 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/stage_select.gd`
  - `docs/dev/project-animal-match-implementation-backlog.md`
- 완료 기준:
  - Stage Popup이 개발용 텍스트 묶음이 아니라 상용 시작 전 카드처럼 읽힌다.
  - Portrait와 landscape snapshot에서 목표, 메타, 보상, buddy, booster, PLAY CTA가 겹치지 않는다.
  - 기존 render snapshot smoke 40개와 scene mobile matrix가 회귀 없이 통과한다.

### PAM-UX-122: Gameplay Portrait Board Density Polish

- 상태: 완료됨. Gameplay portrait에서 보드가 상단 HUD 아래에 너무 붙고 하단 booster dock이 화면 끝에 떨어져 있어 플레이 화면 절반이 비어 보이던 문제를 줄였다. 보드 시작 위치를 낮추고 booster dock을 보드 가까이 올렸으며, portrait booster 버튼 크기를 키워 하단 도구 영역이 상용 퍼즐 UI처럼 읽히게 했다. Scene mobile matrix는 `BoardFrame`과 `HudBoosterDock`이 겹치지 않으면서 보드-부스터 간격이 viewport 높이의 20%를 넘지 않는지 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/validate_scene_loads.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
  - `docs/dev/project-animal-match-implementation-backlog.md`
- 완료 기준:
  - `390x844` gameplay portrait snapshot에서 보드와 booster dock 사이 빈 공간이 과하지 않다.
  - 하단 booster 버튼이 아이콘형 도구 CTA로 읽힐 만큼 충분히 크다.
  - `validate_gameplay.sh`와 render snapshot smoke 40개가 통과한다.

### PAM-UX-123: Gameplay Landscape HUD Commercial Readability Polish

- 상태: 완료됨. Gameplay landscape에서 보드 패널의 과한 최소 폭이 우측 `LandscapeHudShell`을 실제 PNG에서 좁은 개발용 rail처럼 누르던 문제를 줄였다. 보드 패널의 landscape 강제 폭을 제거하고, HUD shell 폭/여백/카드 높이/글자 크기를 상용 퍼즐게임 side HUD처럼 키웠으며, render snapshot gate가 `LandscapeHudShell`, `StatsCard`, `GoalCard`의 실제 PNG 픽셀 최소 크기를 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/validate_scene_loads.gd`
  - `scripts/validate_render_snapshots.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
  - `docs/dev/project-animal-match-implementation-backlog.md`
- 완료 기준:
  - `844x390` gameplay landscape snapshot에서 우측 HUD가 얇은 debug panel이 아니라 목표/이동/콤보가 분리된 상용 side HUD로 보인다.
  - `LandscapeHudShell`은 보드와 겹치지 않고 실제 PNG 너비의 20% 이상을 확보한다.
  - `validate_gameplay.sh`와 render snapshot smoke 40개가 통과한다.

### PAM-UX-124: Gameplay Landscape Board-HUD Cluster Polish

- 상태: 완료됨. Gameplay landscape에서 보드와 `LandscapeHudShell` 사이가 과하게 벌어져 좌우 배경이 빈 공간처럼 보이던 문제를 줄였다. 가로 모드에서는 `BoardPanel`이 남은 폭을 전부 확장하지 않도록 바꾸고 `LayoutRoot`를 중앙 정렬해 보드와 HUD가 하나의 플레이 클러스터로 붙어 보이게 했다. 보드 패널 높이도 콘텐츠 중심으로 줄여 아래까지 늘어진 개발용 panel 느낌을 제거했고, scene/render snapshot gate가 `BoardFrame`과 `LandscapeHudShell` 사이 실제 간격 상한을 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/validate_scene_loads.gd`
  - `scripts/validate_render_snapshots.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
  - `docs/dev/project-animal-match-implementation-backlog.md`
- 완료 기준:
  - `844x390` gameplay landscape snapshot에서 보드와 HUD가 분리된 섬처럼 보이지 않고 중앙의 한 gameplay cluster로 읽힌다.
  - `BoardFrame`과 `LandscapeHudShell`은 겹치지 않으면서 실제 PNG 너비의 14%를 넘는 빈 gap을 만들지 않는다.
  - `validate_gameplay.sh`와 render snapshot smoke 40개가 통과한다.

### PAM-UX-125: Gameplay Landscape Support Dock Density Polish

- 상태: 완료됨. Gameplay landscape의 `LandscapeHudShell` 하단이 크림색 빈 패널처럼 남아 보이던 문제를 줄였다. 기존 `TipsCard`를 landscape 전용 `지원 도구` 카드로 재활용해 부스터/Buddy 보조 정보를 보여 주고, 카드가 남는 세로 공간을 채워 우측 HUD가 정보/목표/지원/CTA로 이어지는 상용 조작 패널처럼 읽히게 했다. Scene smoke와 render snapshot gate는 `LandscapeSupportCard`의 viewport bounds, 실제 PNG 픽셀 최소 크기, landscape `Retry`/`Next`/`Quit` CTA의 shell 내부 배치와 터치 타깃을 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/validate_scene_loads.gd`
  - `scripts/validate_render_snapshots.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
  - `docs/dev/project-animal-match-implementation-backlog.md`
- 완료 기준:
  - `844x390` gameplay landscape snapshot에서 `LandscapeHudShell` 하단이 빈 패널이 아니라 지원/조작 영역으로 보인다.
  - `LandscapeSupportCard`와 landscape action CTA가 실제 PNG에 렌더되고, CTA는 shell 내부와 commercial touch target을 유지한다.
  - `validate_gameplay.sh`와 render snapshot smoke 40개가 통과한다.

### PAM-UX-126: Collection Portrait Album Card Polish

- 상태: 완료됨. Collection portrait가 3열 표처럼 보이던 문제를 줄이고 2열 앨범 카드로 전환했다. 카드 높이와 `AnimalPreview` 슬롯을 키워 해금 동물의 얼굴이 첫 시선의 주인공이 되게 하고, 카드 내부 cosmetic 장문 라벨은 상세 영역으로만 남겨 카드 표면의 텍스트 밀도를 낮췄다. 이름/상태 표시는 회색 행 대신 밝은 캔디풍 칩으로 정리해 잠금/해금/NEW/장착 프레임 상태를 유지하면서도 상용 캐주얼 퍼즐 UI에 가까운 밀도를 만든다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/collection_screen.gd`
  - `scripts/validate_scene_loads.gd`
  - `scripts/validate_render_snapshots.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
  - `docs/dev/project-animal-match-implementation-backlog.md`
- 완료 기준:
  - `390x844` Collection snapshot에서 카드가 2열 앨범 그리드로 보이고, 첫 `rabbit` 카드와 `AnimalPreview`가 실제 PNG에서 상용 판독 크기를 유지한다.
  - Scene smoke가 portrait 2열/landscape 6열 Collection grid와 카드/preview collapse 회귀를 차단한다.
  - `validate_gameplay.sh`와 render snapshot smoke 40개가 통과한다.

### PAM-UX-127: Collection Compact Header & Locked Card Tone Polish

- 상태: 완료됨. Collection 상단 패널이 보상 버튼 표처럼 보이던 문제를 줄였다. 선택 동물 상세 문구는 portrait에서 한 줄 말줄임으로 압축하고, cosmetic reward action은 3열 compact ribbon으로 고정해 카드 그리드가 첫 화면에서 더 빨리 시작되게 했다. 잠금 카드는 무거운 회색 덩어리 대신 옅은 파스텔 카드와 흐린 동물 실루엣으로 낮은 위계를 유지하면서도 `Stage N 해금` 상태가 읽히도록 톤을 조정했다. Scene smoke와 render snapshot은 compact header/ribbon height, locked dog card/preview/status region, portrait 2열 album grid 회귀를 함께 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/collection_screen.gd`
  - `scripts/validate_scene_loads.gd`
  - `scripts/validate_render_snapshots.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
  - `docs/dev/project-animal-match-implementation-backlog.md`
- 완료 기준:
  - `390x844` Collection snapshot에서 header가 보상 버튼 표처럼 길어지지 않고 compact ribbon으로 보인다.
  - 잠금 dog 카드의 preview/status가 실제 PNG에서 non-blank로 렌더되고 `Stage 7 해금` 상태를 유지한다.
  - `validate_gameplay.sh`와 render snapshot smoke 40개가 통과한다.

### PAM-UX-128: Result Overlay Reward Chip Polish

- 상태: 완료됨. Stage clear/failure overlay가 텍스트만 작은 보상 카드처럼 보이던 문제를 줄였다. 성공 overlay는 골드/별/점수, Rescue Book 토큰, Zoo-Zoo Time을 `OverlayChipGrid` 보상 칩으로 분리하고 mascot과 CTA를 키워 보상감이 먼저 읽히게 했다. Near-miss 실패 overlay는 남은 목표, 놓친 핵심, 다음 한 수를 action chip으로 분리해 실패 원인과 다음 행동을 즉시 읽게 했다. Render snapshot은 성공/실패 overlay panel, mascot, chip grid, primary CTA 최소 PNG 크기와 chip 텍스트를 검증하고, scene smoke는 reward chip 조건과 기존 실패 오퍼/monetization 계약을 함께 확인한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scenes/gameplay.tscn`
  - `scripts/gameplay.gd`
  - `scripts/validate_scene_loads.gd`
  - `scripts/validate_render_snapshots.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
  - `docs/dev/project-animal-match-implementation-backlog.md`
- 완료 기준:
  - `390x844`와 `844x390` Stage 1 성공 overlay에서 보상 칩, mascot, `다음 스테이지` CTA가 실제 PNG에서 상용 판독 크기를 유지한다.
  - Stage 25 near-miss 실패 overlay에서 목표/핵심/다음 action chip과 `+3 이동 받고 계속` CTA가 실제 PNG에 렌더된다.
  - `validate_gameplay.sh`와 render snapshot smoke 40개가 통과한다.

### PAM-UX-129: Stage Select Selected Panel Info Chips

- 상태: 완료됨. Stage Select World Map의 하단 `WorldSelectedPanel`이 landscape에서 큰 흰 빈 패널처럼 보이던 문제를 줄였다. 선택 스테이지 제목을 한 줄로 정리하고 목표, 이동 수, 보상을 `WorldSelectedChipRow`의 pastel info chip으로 분리해 `PLAY` CTA 옆 빈 면을 상용 월드맵 선택 카드처럼 채웠다. Scene smoke는 선택 패널, info column, 목표/이동/보상 chip이 viewport와 panel 안에 있고 `PLAY`와 겹치지 않는지 확인하며, render snapshot은 `390x844`/`844x390` Stage Select World Map/Progress PNG에서 chip region과 최소 PNG 크기, chip 텍스트를 검증한다.
- 소유: Art Agent + Development Agent + QA Agent
- 대상 파일:
  - `scripts/stage_select.gd`
  - `scripts/validate_scene_loads.gd`
  - `scripts/validate_render_snapshots.gd`
  - `docs/dev/validation-process.md`
  - `docs/qa/project-animal-match-development-gates.md`
  - `docs/dev/project-animal-match-implementation-backlog.md`
- 완료 기준:
  - `390x844`와 `844x390` Stage Select World Map/Progress snapshot에서 `WorldSelectedGoalChip`, `WorldSelectedMovesChip`, `WorldSelectedRewardChip`이 실제 PNG에 렌더된다.
  - 하단 선택 패널의 info column과 `WorldPlayButton`이 겹치지 않고, `PLAY` CTA가 primary 위계를 유지한다.
  - `validate_gameplay.sh`와 render snapshot smoke 40개가 통과한다.

## 추천 구현 순서

완료된 초기 구현 카드(`PAM-DEV-050`, `PAM-DEV-052`, `PAM-DEV-053`, `PAM-DEV-055`, `PAM-DEV-058`, `PAM-DEV-060`, `PAM-UX-060`, `PAM-PLAN-061`, `PAM-LIVEOPS-081`, `PAM-ART-091`, `PAM-PLAN-092`, `PAM-QA-041`, `PAM-REL-101`, `PAM-QA-102`, `PAM-REL-103`, `PAM-QA-104`, `PAM-QA-105`, `PAM-QA-111`, `PAM-UX-112`, `PAM-UX-113`, `PAM-UX-114`, `PAM-UX-115`, `PAM-UX-116`, `PAM-LIVEOPS-118`, `PAM-UX-119`, `PAM-UX-120`, `PAM-UX-121`, `PAM-UX-122`, `PAM-UX-123`, `PAM-UX-124`, `PAM-UX-125`, `PAM-UX-126`, `PAM-UX-127`, `PAM-UX-128`, `PAM-UX-129`)는 회귀 검증 대상으로 유지한다. `PAM-QA-104`에는 Stage 31 특수 조합 6종 render snapshot preflight가 포함된다.

다음 고가치 순서:

1. `PAM-QA-040` - 실제 기기/수동 플레이 표정·Buddy·특수조합 QA
2. `PAM-DEV-051` - 특수 조합 수동 플레이 QA 및 밸런스 튜닝
3. `PAM-DEV-053` 후속 - Rescue Buddy 수치 튜닝과 실제 기기 플레이 감각 QA
