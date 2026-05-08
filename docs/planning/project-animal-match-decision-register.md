# Project Animal Match Planning Decision Register

작성일: 2026-05-02
목적: 기획 결정과 미결정 항목을 한곳에서 추적해 에이전트가 같은 논쟁을 반복하지 않게 한다.

## 1. 확정 결정

| ID | 결정 | 상태 | 근거 | 소유 |
| --- | --- | --- | --- | --- |
| DEC-001 | 프로젝트 기준명은 `Project Animal Match`, 기존명은 이전 가칭으로 처리 | Locked | 문서 통합 필요 | PM |
| DEC-002 | MVP 보드 로스터는 12종 | Locked | 보드 가독성과 현재 런타임/validator 기준 | Planning/Art |
| DEC-003 | 한 스테이지 활성 동물 풀은 4-6종 | Locked | 매치 확률과 보드 가독성 | Level Planning |
| DEC-004 | 원본 JSON은 `spawn_profile.pool/weights`, 런타임은 `animal_pool/spawn_weights` | Locked | 현재 `StageCatalog` 패턴 유지 | Tech |
| DEC-005 | 피버 MVP는 3회 플레이어 이동 기준 | Locked | 초 단위 피버는 기기/연쇄 시간에 흔들림 | Systems Planning |
| DEC-006 | Level 1-10은 하트, 전면 광고, 직접 IAP 금지 | Locked | D1 리텐션 보호 | UX/BM |
| DEC-007 | 첫 세션 목표는 Level 5 컬렉션 해금 | Locked | 다음 접속 동기 확보 | UX |
| DEC-008 | 동물 스킬은 Rescue Buddy 1종 자동 발동부터 시작 | Locked | 학습량과 밸런스 비용 절감 | Systems Planning |
| DEC-009 | 표정 상태명은 `idle`, `blink`, `smile`, `match`, `fever`, `worried` | Locked | 코드/아트/VFX 공통 계약 | Art/Tech |
| DEC-010 | 신규 기능은 가능하면 controller/service로 분리 | Accepted | `gameplay.gd` 비대화 방지 | Tech |
| DEC-011 | 글로벌 런칭 컬렉션 목표는 18종, 시즌 운영 확장 목표는 24종 | Accepted | 보드 풀은 제한하면서 수집감과 라이브 운영 여지 확보 | Planning/Art/BM |
| DEC-012 | 피버 충전은 기존 Combo Gauge 6칸 충전 완료 시 발동하고, 보상은 3턴 지속 | Locked | PAM-DEV-052 구현 완료. 별도 초 단위/수치 게이지는 MVP 후 재검토 | Systems/Balance |
| DEC-013 | 첫 Rescue Buddy 대상은 Stage 4의 rabbit `quick_refill` | Locked | PAM-DEV-053 1차 구현 완료. 목표 동물 매치 3회 충전 후 1회 자동 발동 | Planning/Tech |
| DEC-014 | Rescue Book 첫 해금 동물은 rabbit 고정 | Locked | FTUE 표와 Level 4 첫 카드 해금 기준 확정 | UX |
| DEC-015 | 우정 레벨 보상은 MVP에서 cosmetic 중심 | Accepted | 초반 pay-to-win 방지. 획득 cosmetic은 Rescue Book 대표 슬롯 장착까지만 지원하고, booster/event XP와 타입별 동시 장착은 소프트 런칭 이후 실험 | BM/UX |
| DEC-016 | Near Miss 기준은 남은 목표 2개 이하 또는 목표 진행률 80% 이상 | Locked | `FailOfferPolicy` 기본값과 remote config `near_miss_goal_threshold`, `near_miss_progress_threshold`로 조정 가능 | UX/Balance/Tech |
| DEC-017 | 분석 SDK 공급자 선택 전 이벤트 경계는 `AnalyticsGateway` `local_buffer` queued dispatch로 고정 | Accepted | 계약 위반 이벤트는 `rejected_contract`로 격리하고, Firebase/GameAnalytics/custom adapter는 `configure_flush_adapter(provider_id, Callable)` 뒤에 연결 | Tech/PM |
| DEC-018 | SDK 공급자 선택 전 provider readiness는 `data/provider_readiness.json` manifest와 validator로 고정 | Accepted | Analytics `local_buffer`, Monetization `local_simulator`, adapter hook, source/result canonicalization, provider_result 보존, queue/request log 상한을 `validate_provider_readiness.sh`가 코드와 대조 | Tech/QA |
| DEC-019 | 시즌 패스 해금 레벨은 `season_pass_unlock_level` 원격 설정으로 제어 | Accepted | baseline은 Stage 21이며, 실제 store product/SDK evidence 전까지 alpha `season_pass` fixture는 disabled로 유지하고 `validate_liveops_config.sh`가 검증 | BM/Tech/QA |
| DEC-020 | `lion`, `elephant` MVP 기본 블록은 전용 256px PNG 에셋으로 고정 | Locked | `assets/generated/candy/lion_candy_block.png`와 `elephant_candy_block.png`가 추가되었고, scene smoke가 MVP 보드 12종 직접 Texture2D/256x256 로드를 검증한다. 표정 atlas/고급 애니메이션 에셋은 후속 아트 QA로 분리 | Art/Tech/QA |
| DEC-021 | 13-18번 컬렉션 동물의 시즌 1 보드 투입 순서는 `koala -> hamster -> deer -> seal -> sheep -> turtle` | Locked | `data/animals.json`의 `board_expansion_order`, `board_candidate_min_stage`, `board_candidate_stage_band`로 고정한다. 현재 alpha에서는 6종 모두 `board_enabled=false`를 유지하고, stage JSON의 pool/target/weights/buddy에 들어가면 validator가 실패해야 한다 | Planning/Balance/QA |

## 2. 아직 열려 있는 결정

| ID | 질문 | 후보 | 결정 필요 시점 | 소유 |
| --- | --- | --- | --- | --- |
| OPEN-007 | 분석 SDK 실제 공급자 | Firebase, GameAnalytics, custom adapter | SDK adapter 연결 전. 선택된 provider는 `data/provider_readiness.json`의 adapter 계약을 지켜야 함 | Tech/PM |

## 3. 변경 금지선

- Level 1-10 수익화 금지는 소프트 런칭 지표 검증 전까지 해제하지 않는다.
- 활성 풀 4-6종 원칙은 보드 확률 검증 없이 확장하지 않는다.
- Rescue Book 보상은 초반에 pay-to-win 성능 보상으로 만들지 않는다.
- 동물 스킬은 스테이지 클리어 필수 조건이 되어서는 안 된다.

## 4. 결정 변경 절차

1. 변경 제안자는 변경 이유와 영향 파일을 적는다.
2. 관련 문서 3종을 함께 갱신한다: 기획, 기술/백로그, QA.
3. 변경이 밸런스나 수익화에 영향을 주면 분석 이벤트 또는 원격 설정도 갱신한다.
4. `autonomy_execution_log.md`에 결정 변경 기록을 남긴다.

## 5. 다음 회의 안건

1. `OPEN-007`: 분석 SDK 실제 공급자와 adapter 연결 범위.
