# Project Animal Match Multi-Agent Workflow

## 목적

`Project Animal Match`의 6인 전문 에이전트가 같은 전제와 산출물 체계를 공유하도록 고정한다. 모든 산출물은 Godot 4.x 기반 글로벌 모바일 런칭을 기준으로 작성한다.

## 공통 전제

- 프로젝트명: `Project Animal Match` (가칭)
- 장르: 귀여운 동물 테마의 스테이지 기반 매치3 퍼즐
- 엔진: Godot 4.x
- 타겟: Android/iOS 글로벌 모바일 런칭
- 기본 UX: 짧은 세션, 즉시 이해 가능한 스와이프 조작, 높은 시각 피드백
- 기술 기준: 모바일 성능, 데이터 주도 레벨 운영, 반복 가능한 QA

## 6인 에이전트

| 순서 | 에이전트 | 책임 | 주요 산출물 |
| --- | --- | --- | --- |
| 1 | Game Director | 코어 루프, 특수 블록, 밸런싱, 차별화 | `docs/game/project-animal-match-core-design.md` |
| 2 | Project Manager | 로드맵, WBS, 리스크, 런칭 준비 | `docs/pm/project-animal-match-master-development-plan.md` |
| 3 | Art Director | 캐릭터, UI/UX, 에셋 파이프라인, 팔레트 | `docs/art/project-animal-match-visual-style-guide.md` |
| 4 | Technical Lead | 데이터, 알고리즘, 노드/시그널, 최적화 | `docs/dev/project-animal-match-technical-architecture.md` |
| 5 | Animation & VFX Artist | Tween, VFX, 피드백, 사운드 타이밍 | `docs/art/project-animal-match-animation-vfx.md` |
| 6 | Business & Operations Modeler | BM, 이벤트, 로그, 라이브 운영 | `docs/ops/project-animal-match-business-operations.md` |

## 권장 실행 순서

1. 모든 에이전트는 먼저 `docs/project-animal-match-agent-start-here.md`를 읽는다.
2. 기획 변경이 있으면 `docs/planning/project-animal-match-planning-council-synthesis.md`를 먼저 확인한다.
3. Game Director가 핵심 기획서를 작성하거나 변경한다.
4. Art Director와 Technical Lead가 핵심 기획서를 동시에 참조해 비주얼/기술 기준을 작성한다.
5. Animation & VFX Artist가 아트 기준과 코어 루프를 참조해 연출 파라미터를 작성한다.
6. Business & Operations Modeler가 밸런스와 로드맵을 참조해 수익화/운영 기준을 작성한다.
7. Project Manager가 모든 산출물을 모아 마스터 개발 플랜과 게이트 기준을 확정한다.
8. Development Agent는 `docs/dev/project-animal-match-implementation-backlog.md`에서 작업 카드를 선택해 구현한다.
9. QA Agent는 `docs/qa/project-animal-match-development-gates.md` 기준으로 승인 또는 반려한다.

## 핸드오프 규칙

- 기획에서 수치가 정해지지 않은 규칙은 개발 문서에 `TBD`로 넘기지 않는다. 임시 수치와 검증 방법을 함께 둔다.
- 아트 산출물은 파일명, 해상도, 사용 씬, 대체 가능 여부를 포함한다.
- 개발 산출물은 데이터 스키마, 노드 책임, 시그널 이름, 검증 명령을 포함한다.
- BM 산출물은 UX에 영향을 주는 결제/광고 지점을 기획 문서에 되돌려 확인한다.
- QA는 PM 플랜의 게이트 기준을 기준으로 승인 또는 반려한다.

## 통합 인덱스

- 산출물 지도: `docs/project-animal-match-agent-output-index.md`
- 에이전트 시작점: `docs/project-animal-match-agent-start-here.md`
- 기획 협의 통합본: `docs/planning/project-animal-match-planning-council-synthesis.md`
- 기획 고도화 보고서: `docs/planning/project-animal-match-planning-upgrade-report-2026-05-02.md`
- 세부 기획 리뷰: `docs/planning/project-animal-match-core-loop-agent-review.md`, `docs/planning/project-animal-match-level-balance-agent-review.md`, `docs/planning/project-animal-match-ux-retention-agent-review.md`
- 동물 로스터/애니메이션 매트릭스: `docs/planning/project-animal-match-animal-roster-animation-matrix.md`
- 레벨 진행 콘텐츠 바이블: `docs/planning/project-animal-match-level-progression-content-bible.md`
- 개발 실행 백로그: `docs/dev/project-animal-match-implementation-backlog.md`
- 동물 표정 구현 명세: `docs/dev/project-animal-match-animal-expression-system.md`
- QA 게이트: `docs/qa/project-animal-match-development-gates.md`
- 작업 브리프: `.codex/tasks/project-animal-match-agent-brief-2026-05-02.md`
