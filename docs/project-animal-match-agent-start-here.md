# Project Animal Match Agent Start Here

## 목적

이 문서는 `Project Animal Match` 작업을 맡은 에이전트가 가장 먼저 읽는 진입점이다. 각 에이전트는 여기에서 현재 기준, 읽기 순서, 구현 우선순위, 검증 게이트를 확인한 뒤 개발을 진행한다.

## 프로젝트 기준

- 프로젝트명: `Project Animal Match` (가칭)
- 기존 저장소 명칭 연결: `Zoo-Zoo Pop`, `Animal Pop Match` 문서는 같은 프로젝트의 이전 가칭으로 본다.
- 엔진: Godot 4.x
- 플랫폼: Android/iOS 글로벌 모바일
- 장르: 귀여운 동물 테마의 스테이지 기반 매치3 퍼즐
- 현재 코드 기준: Godot 씬/스크립트는 이미 100스테이지, 특수 블록, 콤보 게이지, 덤불 장애물, HUD, 기초 VFX를 가진 상태다.

## 먼저 읽을 문서

1. 산출물 지도: `docs/project-animal-match-agent-output-index.md`
2. 기획 협의 통합본: `docs/planning/project-animal-match-planning-council-synthesis.md`
3. 기획 고도화 보고서: `docs/planning/project-animal-match-planning-upgrade-report-2026-05-02.md`
4. 결정 레지스터: `docs/planning/project-animal-match-decision-register.md`
5. 시스템 규칙 매트릭스: `docs/planning/project-animal-match-system-rules-matrix.md`
6. FTUE/Rescue Book 상세 기획: `docs/planning/project-animal-match-ftue-rescue-book-spec.md`
7. 분석/원격 설정 계약: `docs/planning/project-animal-match-analytics-remote-config-spec.md`
8. Rescue Buddy 스킬 명세: `docs/planning/project-animal-match-rescue-buddy-skill-spec.md`
9. 동물 로스터/애니메이션 매트릭스: `docs/planning/project-animal-match-animal-roster-animation-matrix.md`
10. 레벨 진행 콘텐츠 바이블: `docs/planning/project-animal-match-level-progression-content-bible.md`
11. 핵심 기획: `docs/game/project-animal-match-core-design.md`
12. 개발 실행 백로그: `docs/dev/project-animal-match-implementation-backlog.md`
13. 기술 아키텍처: `docs/dev/project-animal-match-technical-architecture.md`
14. 동물 표정 시스템 구현 명세: `docs/dev/project-animal-match-animal-expression-system.md`
15. 비주얼 기준: `docs/art/project-animal-match-visual-style-guide.md`
16. 연출 기준: `docs/art/project-animal-match-animation-vfx.md`
17. QA 게이트: `docs/qa/project-animal-match-development-gates.md`
18. 다음 작업 브리프: `.codex/tasks/project-animal-match-planning-handoff-briefs-2026-05-02.md`

## 역할별 읽기 순서

| 역할 | 필수 문서 | 개발 전 확인 |
| --- | --- | --- |
| PM Lead | Start Here, Output Index, Planning Council, Decision Register, Master Plan, Implementation Backlog | 마일스톤, 승인 기준, 파일 소유 범위 |
| Game Director | Planning Council, Decision Register, System Rules, Level Progression Bible, Core Design, Implementation Backlog | 12종 로스터, 피버 3턴, Rescue Buddy, FTUE 결정 |
| Art Director | Visual Style Guide, Animation/VFX, Roster Animation Matrix, Expression System | 12종 에셋, 18종 컬렉션 확장, 표정 프레임, atlas 규칙 |
| Technical Lead | Technical Architecture, Expression System, Implementation Backlog | 스키마, 노드 책임, 검증 명령 |
| Development Agent | Implementation Backlog, Expression System, current scripts | 작업 카드, 대상 파일, 테스트 |
| QA Agent | Development Gates, Level Progression Bible, Roster Animation Matrix, Core Design, Technical Architecture | 승인/반려 기준과 재현 절차 |

## 현재 결정 사항

- MVP 보드 로스터는 12종이다.
- 글로벌 런칭 콘텐츠 목표는 보드 12종과 컬렉션/이벤트 예비 6종을 합친 18종이며, 시즌 운영은 24종까지 확장한다.
- 현재 코드와 validator는 12종을 인식하며, `lion`, `elephant`는 전용 256px 기본 블록 PNG를 사용한다. 명시 fallback은 에셋 누락 시 보드를 깨뜨리지 않는 방어 경로로만 남긴다.
- 한 스테이지의 `animal_pool`은 5-6종으로 제한한다.
- 스테이지 JSON 원본은 `spawn_profile.pool/weights`, 런타임 정규화 필드는 `animal_pool/spawn_weights`를 기준으로 한다.
- 피버 MVP 지속은 `3회 플레이어 이동`으로 고정한다.
- 동물 스킬은 스테이지별 `Rescue Buddy` 1종 자동 발동부터 시작한다.
- 첫 세션 목표는 `Level 5 클리어 + 첫 컬렉션 카드 해금 + 다음 동물 예고`다.
- Level 1-10은 하트 소모, 전면 광고, IAP 팝업을 금지한다.
- 확정/미결정 기획 판단은 `docs/planning/project-animal-match-decision-register.md`를 기준으로 한다.
- 표정 애니메이션은 `idle`, `blink`, `smile`, `match`, `fever`, `worried` 상태를 기본으로 한다.
- 1차 구현은 full-frame 애니메이션보다 atlas region 변경과 눈/입 overlay를 우선한다.
- idle blink는 동시에 최대 4개 타일만 재생한다.

## 현재 코드 주요 위치

| 영역 | 파일 |
| --- | --- |
| 플레이 전체 컨트롤 | `scripts/gameplay.gd` |
| 블록 타일 입력/연출 | `scripts/block_tile.gd` |
| VFX 레이어 | `scripts/fx_layer.gd` |
| 스테이지 로딩 | `scripts/stage_catalog.gd` |
| 스테이지 검증 | `scripts/stage_data_validator.gd` |
| 밸런스 검증 | `scripts/validate_stage_balance.gd` |
| 스테이지 JSON | `data/stages/` |
| 플레이 씬 | `scenes/gameplay.tscn` |
| 블록 타일 씬 | `scenes/block_tile.tscn` |

## 개발 시작 규칙

1. 작업 전 `docs/dev/project-animal-match-implementation-backlog.md` 또는 `.codex/tasks/project-animal-match-planning-handoff-briefs-2026-05-02.md`에서 작업 카드를 하나 고른다.
2. 같은 카드에 적힌 대상 파일 외 변경이 필요하면 PM/Technical Lead 문서에 이유를 남긴다.
3. 스테이지 데이터 변경은 반드시 `scripts/validate_stage_data.sh`와 `scripts/validate_stage_balance.sh` 기준을 확인한다.
4. 코드 변경은 `scripts/validate_gameplay.sh` 또는 최소 씬 로드 검증을 실행한다.
5. 신규 동물/표정 에셋이 없어도 fallback이 보이도록 구현한다.

## 개발 완료 보고 형식

```text
작업 카드:
변경 파일:
구현 내용:
검증 명령:
통과/실패 결과:
남은 리스크:
다음 추천 작업:
```
