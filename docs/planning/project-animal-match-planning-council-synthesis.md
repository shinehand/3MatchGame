# Project Animal Match Planning Council Synthesis

작성일: 2026-05-02
참여 에이전트:

- Planning Agent 1: Core Loop & Systems Planner
- Planning Agent 2: Level Balance & Progression Planner
- Planning Agent 3: UX Retention & Player Motivation Planner

## 1. 결론

세 기획 에이전트의 공통 결론은 같다. `Project Animal Match`는 이미 매치3 기본 구현, 12종 로스터 기반, 표정 애니메이션 fallback, 100스테이지 데이터 구조를 갖췄으므로, 다음 고도화는 새 아이디어 추가보다 `규칙의 명확화`, `초반 동기 설계`, `피버/스킬/메타 루프의 데이터화`, `검증 가능한 밸런스 기준`에 집중해야 한다.

## 2. 확정 결정

| 항목 | 확정안 | 이유 |
| --- | --- | --- |
| 피버 지속 | MVP는 `3회 플레이어 이동` 기준. 8초는 연출 상한으로만 사용 | 기기 성능과 연쇄 시간 차이로 초 단위 체감이 흔들림 |
| 스테이지 원본 스키마 | JSON 원본은 `spawn_profile.pool/weights`, 런타임 정규화는 `animal_pool/spawn_weights` | 현재 `StageCatalog` 구조와 개발 편의성을 모두 유지 |
| 동물 로스터 | MVP 보드 12종, 글로벌 런칭 컬렉션 18종, 시즌 운영 24종 목표. 보드별 활성 풀은 4-6종 | 수집감과 라이브 확장성을 키우되 매치 확률을 유지 |
| 동물 스킬 | MVP는 스테이지별 `Rescue Buddy` 1종 자동 발동부터 시작 | 모든 동물 동시 스킬은 학습량과 밸런스 비용이 큼 |
| 초반 수익화 | Level 1-10에서는 하트 소모, 전면 광고, IAP 팝업 금지 | D1 유지율과 첫 세션 신뢰 확보 |
| 첫 세션 목표 | Level 5까지 첫 컬렉션 카드와 스타터 미션 보상을 경험 | 다음 접속 동기를 남김 |
| 컬렉션 메타 | `Rescue Book`을 상시 메타 루프로 도입 | 12종 로스터를 단순 보드 스킨이 아닌 장기 동기로 전환 |
| 실패 후 제안 | Near Miss, Strategic Miss, First Fail, Repeat Fail, Hard Level Fail로 분류 | 광고/IAP 반감을 줄이고 공정성을 확보 |

## 3. 현재 기획에서 보강해야 할 지점

### 3.1 코어 루프

- 현재 기본 루프는 충분하나 `StageIntro`, `ResolveTurn`, `EndTurnCheck`, `Result`의 책임을 문서와 코드에서 같은 용어로 맞춰야 한다.
- 특수 블록 처리 순서는 `특수+특수 조합 -> 단일 특수 발동 -> 일반 매치 제거`로 고정한다.
- 피버는 연쇄 도중 즉시 시작하지 않고, 현재 연쇄가 모두 끝난 뒤 시작한다.
- 클리어/실패 판정은 보드 안정화 이후 1회 실행한다.

### 3.2 레벨/밸런스

- 10개 밴드 구조는 유지하되 각 밴드에 `주 학습`, `로스터 진행`, `난이도 파형`, `검증 포인트`를 붙인다.
- 후반부 `Hard` 연속 구조는 `Normal/Recovery -> Hard -> Finale/Master` 파형으로 조정한다.
- `lion`은 Stage 51 이후, `elephant`는 Stage 81 이후 핵심 동물로 쓰는 방향을 기준으로 한다.
- 각 밴드 마지막 스테이지는 `finale` 또는 `boss_stage` 태그로 PM/QA가 별도 추적한다.

### 3.3 UX/리텐션

- 첫 세션 종료 목표는 `Level 5 클리어 + 첫 컬렉션 카드 해금 + 다음 동물 예고`다.
- 표정 애니메이션은 보드뿐 아니라 홈, 컬렉션, 승리, 실패, 이벤트 화면까지 확장한다.
- `Rescue Book`은 12종 동물의 해금, 토큰, 우정 레벨, 표정 미리보기, 장착 요소를 표시한다.
- 글로벌 런칭 전 컬렉션/이벤트 예비 동물 6종을 추가로 준비하되, 보드 투입은 validator와 밸런스 검증이 확장된 뒤 진행한다.
- 이벤트는 Level 5 이후 Starter Missions, Level 12 이후 Collection Event, Level 20 이후 Season Pass 순서로 개방한다.

## 4. 개발 핸드오프

### Development

- `FeverController`, `SpecialEffectQueue`, `AnimalSkillController`, `FailOfferPolicy`, `CollectionState`는 지금부터 독립 책임 후보로 본다.
- 기존 `gameplay.gd`가 너무 커지고 있으므로 새 기능은 작은 컨트롤러로 분리할 수 있는지 먼저 판단한다.
- 데이터 변경은 10스테이지 밴드 단위로 소유권을 나눠 동시 수정 충돌을 피한다.

### Art

- 12종 기본 블록은 현재 런타임 파일명 규칙 `assets/generated/candy/{animal_id}_candy_block.png`를 우선한다.
- 표정 확장은 `blink`, `smile`, `match`, `fever`, `worried` 상태명을 코드와 동일하게 사용한다.
- `Rescue Book`용 카드 일러스트는 보드용 작은 블록보다 큰 해상도와 표정 미리보기를 전제로 별도 제작한다.
- 동물별 애니메이션 방향과 18종 컬렉션 확장은 `docs/planning/project-animal-match-animal-roster-animation-matrix.md`를 기준으로 한다.

### QA

- smoke stage는 Stage 1, 5, 10, 20, 첫 하드 레벨, 81, 100으로 고정한다.
- 초반 10레벨은 수익화 비노출, 튜토리얼 반복 없음, 첫 컬렉션 보상 경험을 확인한다.
- 실패 분류, Rescue Book 저장/복구, 원격 설정 fallback, 분석 이벤트 파라미터를 별도 게이트로 추가한다.

## 5. 백로그 승격 항목

| ID | 이름 | 핵심 산출 |
| --- | --- | --- |
| PAM-DEV-050 | 스테이지 스키마 canonical 정리 | 원본 JSON과 런타임 정규화 용어 충돌 제거 |
| PAM-DEV-051 | SpecialEffectQueue와 조합 테스트 | 특수 조합 처리 순서와 장애물 피해 검증 |
| PAM-DEV-052 | FeverController MVP | 3턴 피버, 점수 2배, 목표 수집 +1, HUD |
| PAM-DEV-053 | Rescue Buddy 동물 스킬 시스템 | 스테이지별 buddy/skill 데이터와 자동 1회 발동 |
| PAM-DEV-054 | 결과/실패 near-miss 플로우 | 실패 유형 분류와 제안 정책의 입력 데이터 |
| PAM-DEV-055 | 동물 해금/풀 회전 validator 강화 | 해금 전 등장 금지, 풀 반복, lion/elephant 후반 사용 검증 |
| PAM-DEV-056 | 튜토리얼 해금과 mechanics 정렬 | Stage 1-10 튜토리얼과 실제 메커닉 허용 시점 일치 |
| PAM-DEV-057 | 난이도 태그와 회복 레벨 파형 | recovery/finale/master 태그와 하드 연속 경고 |
| PAM-UX-060 | FTUE 1-10레벨 동기 설계 확정 | 첫 컬렉션, 스타터 미션, 금지 수익화 기준 |
| PAM-DEV-060 | Rescue Book 데이터 모델 | 12종 해금/토큰/우정/장착 저장 |
| PAM-DEV-061 | Rescue Book UI | 12종 카드, 표정 미리보기, 홈/결과 진입 |
| PAM-DEV-070 | 실패 유형 분류와 제안 정책 | Near Miss/Repeat Fail/Hard Fail별 CTA |
| PAM-DEV-080 | 라이브 이벤트 템플릿과 원격 설정 | 데일리/스타터/수집/시즌 데이터화 |
| PAM-ANA-090 | 분석 이벤트 계약 검증기 | 필수 이벤트/파라미터 스키마 검증 |
| PAM-ART-091 | 동물 로스터/표정 애니메이션 제작 매트릭스 반영 | 12종 보드 표현과 18종 컬렉션 로스터 데이터화 |

## 6. 다음 구현 우선순위

1. `PAM-DEV-050`: 스키마 용어를 문서/validator에서 확정한다.
2. `PAM-DEV-052`: 피버를 3턴 MVP로 고정하고 HUD/검증을 붙인다.
3. `PAM-UX-060`: Level 1-10 FTUE/첫 보상/첫 컬렉션 동기를 확정한다.
4. `PAM-DEV-055`: 로스터 해금과 풀 회전 validator를 강화한다.
5. `PAM-DEV-060`: Rescue Book 저장 모델을 만든다.

## 7. 확장 기획 명세

- FTUE/Rescue Book 상세 기획: `docs/planning/project-animal-match-ftue-rescue-book-spec.md`
- 결정 레지스터: `docs/planning/project-animal-match-decision-register.md`
- 시스템 규칙 매트릭스: `docs/planning/project-animal-match-system-rules-matrix.md`
- 분석/원격 설정 계약: `docs/planning/project-animal-match-analytics-remote-config-spec.md`
- Rescue Buddy 스킬 명세: `docs/planning/project-animal-match-rescue-buddy-skill-spec.md`
- 동물 로스터/애니메이션 매트릭스: `docs/planning/project-animal-match-animal-roster-animation-matrix.md`
- 레벨 진행 콘텐츠 바이블: `docs/planning/project-animal-match-level-progression-content-bible.md`

## 8. 원문 리뷰

- `docs/planning/project-animal-match-core-loop-agent-review.md`
- `docs/planning/project-animal-match-level-balance-agent-review.md`
- `docs/planning/project-animal-match-ux-retention-agent-review.md`
