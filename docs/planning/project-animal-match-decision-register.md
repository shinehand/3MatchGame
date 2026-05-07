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
| DEC-015 | 우정 레벨 보상은 MVP에서 cosmetic 중심 | Accepted | 초반 pay-to-win 방지. booster/event XP는 소프트 런칭 이후 실험 | BM/UX |

## 2. 아직 열려 있는 결정

| ID | 질문 | 후보 | 결정 필요 시점 | 소유 |
| --- | --- | --- | --- | --- |
| OPEN-005 | 실패 Near Miss 기준 | 남은 목표 1-2개, 진행률 80%, 장애물 hp 총합 기준 | PAM-DEV-070 전 | UX/Balance |
| OPEN-006 | 시즌 패스 해금 레벨 | 20 고정 또는 원격 설정 | PAM-DEV-080 전 | BM |
| OPEN-007 | 분석 SDK 실제 공급자 | Firebase, GameAnalytics, custom adapter | Analytics 구현 전 | Tech/PM |
| OPEN-008 | 최종 `lion`, `elephant` 전용 에셋 제작 시점 | MVP 전, 소프트 런칭 전, 이벤트 전 | PAM-DEV-011 후속 | Art/PM |
| OPEN-009 | 13-18번 컬렉션 동물의 보드 투입 순서 | koala, hamster, deer, seal, sheep, turtle 중 이벤트 성과 기준 | 시즌 1 보드 확장 전 | Planning/Balance |

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

1. `OPEN-005`: Near Miss 판정 기준.
2. `OPEN-007`: 분석 SDK 추상화 범위.
3. `OPEN-009`: 컬렉션 전용 동물의 보드 투입 우선순위.
4. `OPEN-006`: 시즌 패스 해금 레벨 원격 설정 여부.
5. `OPEN-008`: lion/elephant 전용 에셋 제작 시점.
