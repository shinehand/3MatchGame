# Project Animal Match Implementation Backlog

## 목적

이 백로그는 문서 기획을 실제 Godot 개발 작업으로 바꾸는 실행 목록이다. 각 작업은 에이전트가 독립적으로 맡을 수 있도록 대상 파일, 선행 조건, 완료 기준, 검증 방법을 포함한다.

## 현재 상태 요약

- 구현됨: 8x8 보드, 스와이프, 매치 판정, 낙하/리필, 특수 블록, 콤보 게이지, 덤불 장애물, HUD, 100개 스테이지 로딩/검증.
- 구현됨: 12종 동물 로스터 인식, `lion`/`elephant` 명시 fallback, 스테이지 `roster_group`, 표정 fallback API와 idle blink scheduler.
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
- 선행: Art Director가 `lion`, `elephant` 임시 에셋 또는 fallback 정책 승인
- 대상 파일:
  - `scripts/gameplay.gd`
  - `scripts/stage_data_validator.gd`
  - `assets/generated/candy/`
- 작업:
  - `ANIMAL_IDS`에 `lion`, `elephant`를 추가한다.
  - `ANIMAL_NAMES`에 `사자`, `코끼리`를 추가한다.
  - `_slot_color()`에 사자/코끼리 색을 추가한다.
  - validator의 `VALID_ANIMALS`를 12종으로 맞춘다.
  - 에셋이 없으면 기존 동물 texture fallback을 명시적으로 사용한다.
- 완료 기준:
  - 새 동물 id가 스테이지 데이터, 목표 텍스트, 타일 표시, 검증기에서 모두 통과한다.
- 검증:
  - `./scripts/validate_stage_data.sh`
  - `./scripts/validate_gameplay.sh`

### PAM-DEV-011: 12종 에셋 경로와 import 규칙 정리

- 상태: 완료됨. `lion`, `elephant` 전용 `assets/generated/candy/{animal_id}_candy_block.png` 에셋을 추가했고, 런타임 fallback은 에셋 누락 방어용으로 유지한다.
- 소유: Art + Development Agent
- 대상 파일:
  - `docs/art/project-animal-match-visual-style-guide.md`
  - `assets/generated/candy/`
  - Godot `.import` 파일
- 작업:
  - 12종 기본 블록 파일명을 1차 런타임 기준 `assets/generated/candy/{animal_id}_candy_block.png`로 통일한다.
  - 표정 확장 파일명은 `animal_{id}_{expression}.png` 및 atlas 규칙으로 분리한다.
  - `lion_candy_block.png`, `elephant_candy_block.png`를 추가하거나 fallback 이미지를 둔다.
  - 에셋 import 후 Godot에서 Texture2D로 로드되는지 확인한다.
- 완료 기준:
  - `_load_animal_textures()`와 scene load 검증이 12종 모두 null 없이 로드하거나 명시 fallback을 사용함을 확인한다.

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

- 상태: no-device readiness 자동화됨. Scene load smoke가 `WorldStageNode*` press로 Stage Popup 표시, 목표/이동 수/보상/START/시작 부스터 3종 버튼과 아이콘, 부스터 선택 상태 반영, 닫기 후 overlay 해제, START 선택값 commit helper를 검증한다. Stage 4/51/81 Buddy Preview는 동물명, 스킬명, 충전 조건/효과 설명과 후반 동물 한글명을 검증하고, Stage 1은 Buddy 영역을 숨기는지 검증한다. Gameplay smoke는 `rainbow_paw`, `striped`, `bomb` 선택값이 `GameSession`에서 한 번 소비되고 보드 특수 블록, `stage_start.selected_boosters`, `stage_start.start_boosters_applied`, `booster_used.source = pre_stage`로 이어지는지 검증한다. 남은 작업은 실제 기기에서 팝업 열기/닫기 애니메이션, 터치감, 시작 보드 판독성을 확인하는 것이다.
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

- 상태: 부분 완료. 인접한 non-rainbow 특수 블록끼리 교환하면 일반 매치가 없어도 유효 이동으로 처리되어 공통 특수 효과 큐를 먼저 해결한다. scene load smoke가 row+column 15칸 제거, row 경로 위 bomb 연쇄 21칸 제거, clear 경로 인접 장애물 피해, rainbow+special 우선순위 라우팅, row+row/column+column 8칸 중복 제거, row+bomb/column+bomb 14칸 합집합, bomb+bomb 12칸 합집합, 4매치 row/column 특수 생성, 5매치 rainbow 생성, T/L 교차 bomb 생성까지 headless fixture로 검증한다. runtime scene smoke는 Stage 31에서 row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb 6종 실제 `_resolve_swap` 경로의 이동 수 1회 소모, 점수 증가, 경로 장애물 제거, `is_busy` 복귀, playing 상태 유지, `special_combo_trigger` analytics의 조합 타입/제거 수/장애물 수를 검증한다. `FxLayer.play_special_combo` 전용 flash/ring/조합별 label VFX와 smoke 검증을 추가해 특수+특수 발동 시작점이 일반 매치 burst와 구분된다. 6종 조합별 beam/ring 형태를 분리했고, FX smoke가 각 라벨과 explosive 조합 echo ring, child count, cleanup을 검증한다. Stage 31은 `combo_focus` + `recommended_smoke`로 31-40 특수 조합 밴드의 수동 smoke 진입점이 되며, balance validator가 이를 강제한다. 남은 작업은 실제 기기에서 6종 조합의 전용 flash/ring/label이 보드 판독을 해치지 않는지, 강한 사운드/햅틱/보드 shake가 과하지 않은지, 제거 후 낙하·리필이 자연스럽게 이어지는지 수동 QA로 판정하는 것이다.
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

- 상태: 부분 완료. `FailOfferPolicy`가 Near Miss, Strategic Miss, First Fail, Repeat Fail, Hard Level Fail을 분류하고 Level 1-10 광고/IAP 제안을 차단한다. Near Miss 기준은 `near_miss_goal_threshold`와 `near_miss_progress_threshold` remote config 기본값으로 조정 가능하며 scene smoke가 튜닝 분기를 검증한다. Scene load smoke는 정책 단위에서 near miss, strategic miss, first fail, repeat fail, hard fail, 초반 수익화 차단을 검증하고, 실제 Gameplay runtime에서 Stage 1 클리어 오버레이의 보상/별/다음 CTA, Stage 1 FTUE 실패 오버레이의 무료 재도전/수익화 문구 차단, Stage 25 near-miss 실패 오버레이의 `+3 이동 받고 계속`/`재도전` CTA, `stage_fail`, `offer_impression`, `fail_offer_show`, `fail_offer_select`, `fail_offer_dismiss`, `ad_reward_complete`, `ad_reward_fail`, `iap_purchase_start`, `iap_purchase_complete`, `iap_purchase_restore`, `iap_purchase_cancel`, `iap_purchase_fail`, `extra_moves_grant`, `continue_stage` +3 이동 재개, 보조 CTA 재시도 복구, 광고 실패/IAP 취소·실패·복구/코인 continue 성공·부족 상태 보존, IAP 성공형 continue transaction 공유, 보상형 광고/IAP continue transaction idempotency를 검증한다. `MonetizationGateway`가 SDK 공급자 결정 전 rewarded/IAP/coin continue 요청을 provider-neutral 결과 콜백으로 정규화하고 request log를 남기며, `configure_continue_adapter(provider_id, Callable)` adapter hook은 queued validation 결과 우선, invalid source adapter 호출 전 거절, deep-copy payload/result normalization, provider pending 중복 CTA 차단을 scene smoke로 검증한다. 남은 작업은 선택된 광고/IAP SDK를 이 adapter 뒤에 실제 연결하고 실제 상품/영수증 복구 QA를 수행하는 것이다.
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

- 상태: 완료됨. `data/animals.json`, `CollectionState`, `GameSession` 저장 경로가 18종 해금/토큰/우정 레벨/장착 cosmetic/new badge를 저장·정규화하고, token 누적으로 friendship level이 상승한다.
- 소유: Development Agent
- 대상 파일 후보:
  - 신규 `scripts/collection_state.gd`
  - 신규 `data/animals.json`
  - 저장 데이터 모듈
- 완료 기준:
  - 12종 동물 해금 상태, 토큰, 우정 레벨, 장착 cosmetic을 저장/로드한다.

### PAM-DEV-061: Rescue Book UI 구현

- 상태: 완료됨. `collection_screen`이 18종 카드의 잠김/해금/NEW/토큰/우정 레벨을 표시하고, 클릭/터치 시 상세 패널 갱신 및 NEW 배지 확인 처리를 수행한다.
- 소유: Development Agent + Art Agent
- 대상 파일 후보:
  - 신규 `scenes/collection_screen.tscn`
  - 신규 `scripts/collection_screen.gd`
- 완료 기준:
  - 12종 카드가 잠김/해금/신규 상태를 표시하고, 표정 미리보기를 성능 제한 안에서 보여 준다.

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

### PAM-ANA-090: 분석 이벤트 계약 검증기 추가

- 상태: 완료됨. `data/analytics_events.json`와 `scripts/validate_analytics_contract.gd`가 앱/스테이지/오퍼/이벤트/Fever/Buddy/Collection 필수 이벤트와 파라미터를 검증한다. `GameSession`은 런타임 이벤트 필수 파라미터 누락을 경고하고, provider-neutral `AnalyticsGateway`에 저장된 이벤트를 dispatch한다. scene smoke가 `stage_start`, `rescue_book_open`, Level 1-5 첫 세션 카드 해금의 `animal_unlock`, 활성 live ops 노출의 `live_event_impression`, 이벤트 참여/진행/보상 수령의 `event_join`, `event_progress`, `event_reward_claim` 실제 기록과 gateway `local_buffer` queued dispatch, disk reload 보존, 순차 flush 후 pending queue 제거, `configure_flush_adapter(provider_id, Callable)` SDK adapter hook, adapter partial failure, adapter payload mutation guard, corrupt queue tolerance, 320개 bounded queue eviction, 계약 위반 이벤트의 `rejected_contract` 격리를 검사한다.
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

## 추천 구현 순서

완료된 초기 구현 카드(`PAM-DEV-050`, `PAM-DEV-052`, `PAM-DEV-053`, `PAM-DEV-055`, `PAM-DEV-060`, `PAM-UX-060`, `PAM-PLAN-061`, `PAM-ART-091`, `PAM-PLAN-092`, `PAM-QA-041`)는 회귀 검증 대상으로 유지한다.

다음 고가치 순서:

1. `PAM-QA-040` - 실제 기기/수동 플레이 표정·Buddy·특수조합 QA
2. `PAM-DEV-051` - 특수 조합 수동 플레이 QA 및 밸런스 튜닝
3. `PAM-DEV-053` 후속 - Rescue Buddy 수치 튜닝과 실제 기기 플레이 감각 QA
