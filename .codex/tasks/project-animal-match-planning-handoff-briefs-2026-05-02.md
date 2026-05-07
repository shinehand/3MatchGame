# Project Animal Match Planning Handoff Briefs

작성일: 2026-05-02
용도: 기획 고도화 이후 개발/아트/QA 에이전트가 바로 착수할 수 있는 작업 브리프 묶음이다. 각 에이전트는 한 번에 하나의 브리프만 선택하고, 대상 파일이 겹치면 작업을 나눈다.

## 공통 사전 읽기

1. `docs/project-animal-match-agent-start-here.md`
2. `docs/project-animal-match-agent-output-index.md`
3. `docs/planning/project-animal-match-planning-council-synthesis.md`
4. `docs/planning/project-animal-match-decision-register.md`
5. `docs/dev/project-animal-match-implementation-backlog.md`

## Brief A: PAM-DEV-052 FeverController MVP

### 목표

`Zoo-Zoo Fever`를 3회 플레이어 이동 기준으로 고정하고, 점수 2배/목표 수집 +1 보너스/HUD 상태를 코드와 테스트로 연결한다.

### 포함 범위

- `FeverController` 또는 동등한 작은 책임 모듈 도입 검토
- 피버 게이지 충전/발동/잔여 턴/종료 처리
- `scripts/gameplay.gd`의 기존 콤보/목표 수집 흐름과 통합
- HUD 표시와 VFX 호출 지점 정리

### 제외 범위

- 모든 동물별 개별 스킬 구현
- 피버 중 랜덤 폭발 같은 MVP 이후 후보
- 광고/IAP 연동

### 필수 참조

- `docs/planning/project-animal-match-system-rules-matrix.md`
- `docs/planning/project-animal-match-analytics-remote-config-spec.md`
- `docs/game/project-animal-match-core-design.md`
- `docs/art/project-animal-match-animation-vfx.md`

### 대상 파일 후보

- `scripts/gameplay.gd`
- 신규 `scripts/fever_controller.gd`
- `scenes/gameplay.tscn`
- 관련 HUD 스크립트/씬

### 완료 조건

- 피버는 실제 플레이어 이동 3회 동안 지속된다.
- 연쇄 중 즉시 끊기지 않고 보드 안정화 후 시작/종료된다.
- 점수 2배와 목표 수집 +1 보너스가 중복/누락 없이 적용된다.
- `./scripts/validate_gameplay.sh`가 통과한다.

## Brief B: PAM-DEV-053 Rescue Buddy 동물 스킬 시스템

### 목표

스테이지별 `Rescue Buddy` 1종을 자동 발동 가능한 MVP 동물 스킬로 구현한다.

### 포함 범위

- 스테이지 데이터의 buddy 후보 필드 설계
- 충전 조건, 발동 조건, 1회 자동 발동 제한
- 실패 직전/목표 근접 상황에서 과도한 자동 클리어 방지
- `buddy_skill_charge`, `buddy_skill_ready`, `buddy_skill_trigger` 이벤트 훅

### 제외 범위

- 12종 전체 수동 스킬 버튼
- 강화/레벨업형 유료 스킬
- 시즌 이벤트 전용 스킬

### 필수 참조

- `docs/planning/project-animal-match-rescue-buddy-skill-spec.md`
- `docs/planning/project-animal-match-decision-register.md`
- `docs/planning/project-animal-match-animal-roster-animation-matrix.md`

### 대상 파일 후보

- `scripts/gameplay.gd`
- 신규 `scripts/animal_skill_controller.gd`
- `data/stages/*.json`
- 신규 `data/animal_skills.json`
- `scripts/stage_data_validator.gd`

### 완료 조건

- 한 스테이지에는 buddy 1종만 활성화된다.
- 첫 자동 발동 후 같은 스테이지에서 재발동하지 않는다.
- 알 수 없는 buddy/skill id는 validator가 잡는다.
- `./scripts/validate_stage_data.sh`, `./scripts/validate_stage_balance.sh`, `./scripts/validate_gameplay.sh`가 통과한다.

## Brief C: PAM-ART-091 동물 로스터/표정 애니메이션 제작 매트릭스 반영

### 목표

MVP 보드 12종과 글로벌 런칭 컬렉션 18종의 역할을 데이터/에셋 제작 단위로 분리하고, 각 동물의 표정 애니메이션 요구사항을 추적 가능하게 만든다.

### 포함 범위

- `data/animals.json` 초안
- `data/animal_animation_profiles.json` 초안
- 12종 `blink`, `smile`, `match`, `fever`, `worried` 프로필
- 13-18번 컬렉션 전용 동물의 `board_enabled: false` 정의

### 제외 범위

- 최종 PNG/atlas 생성
- 런타임 atlas region renderer 구현
- 보드에 13-18번 동물 투입

### 필수 참조

- `docs/planning/project-animal-match-animal-roster-animation-matrix.md`
- `docs/dev/project-animal-match-animal-expression-system.md`
- `docs/art/project-animal-match-visual-style-guide.md`
- `docs/art/project-animal-match-animation-vfx.md`

### 대상 파일 후보

- 신규 `data/animals.json`
- 신규 `data/animal_animation_profiles.json`
- `scripts/stage_data_validator.gd`
- `docs/art/project-animal-match-visual-style-guide.md`

### 완료 조건

- 12종 보드 동물과 18종 컬렉션 동물이 데이터에서 구분된다.
- stage JSON은 `board_enabled == true` 동물만 사용할 수 있다.
- QA가 동물별 표현 상태를 데이터 기준으로 체크할 수 있다.

## Brief D: PAM-PLAN-092 레벨 진행 콘텐츠 바이블 동기화

### 목표

100스테이지 데이터가 레벨 진행 콘텐츠 바이블의 FTUE, 해금 순서, hard/recovery 파형과 충돌하지 않도록 검증 기준을 강화한다.

### 포함 범위

- Stage 1-10 FTUE 표와 실제 JSON 비교
- `lion` Stage 51 이전 금지, `elephant` Stage 81 이전 금지
- hard/finale/master 연속 경고
- recovery 레벨 배치 검토
- 필요 시 `difficulty_tag`, `teaches`, `previews`, `recommended_smoke` 도입 제안

### 제외 범위

- 모든 스테이지 수동 리밸런싱
- 신규 장애물 구현
- 수익화 UI 구현

### 필수 참조

- `docs/planning/project-animal-match-level-progression-content-bible.md`
- `docs/planning/project-animal-match-level-balance-agent-review.md`
- `docs/dev/project-animal-match-implementation-backlog.md`

### 대상 파일 후보

- `data/stages/*.json`
- `scripts/validate_stage_balance.gd`
- `scripts/stage_data_validator.gd`

### 완료 조건

- 밴드별 동물 투입과 tutorial/mechanic 순서가 문서와 맞는다.
- validator 또는 balance 검증이 해금 전 동물 투입을 잡는다.
- `./scripts/validate_stage_data.sh`와 `./scripts/validate_stage_balance.sh`가 통과한다.

## Brief E: PAM-ANA-090 분석 이벤트 계약 검증기

### 목표

FTUE, 피버, Rescue Buddy, Rescue Book, 실패 제안, 광고/IAP, 이벤트의 필수 로그 이벤트와 파라미터를 검증 가능한 계약으로 만든다.

### 포함 범위

- `data/analytics_events.json` 초안
- 필수 이벤트명/파라미터 검증 스크립트
- remote config key 누락 검증 후보

### 제외 범위

- 실제 SDK 연동
- 서버 대시보드 구성
- A/B 테스트 운영

### 필수 참조

- `docs/planning/project-animal-match-analytics-remote-config-spec.md`
- `docs/planning/project-animal-match-system-rules-matrix.md`
- `docs/ops/project-animal-match-business-operations.md`

### 대상 파일 후보

- 신규 `data/analytics_events.json`
- 신규 `scripts/validate_analytics_contract.gd`
- 검증 shell script

### 완료 조건

- 필수 이벤트명과 필수 파라미터 누락을 로컬에서 검출할 수 있다.
- 신규 시스템 이벤트가 들어올 때 문서와 데이터 계약을 함께 갱신하는 흐름이 생긴다.
