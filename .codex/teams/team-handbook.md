# Codex 범용 멀티 에이전트 팀 운영안

## 개요

이 문서는 특정 프로젝트나 특정 기술 스택에 종속되지 않는 범용 팀 운영안이다. 새 프로젝트를 시작할 때 그대로 가져와 `PM팀`, `기획팀`, `아트팀`, `개발팀`, `QA팀` 체계를 빠르게 구성할 수 있도록 설계했다.

## 1. 기본 팀 구조

### PM Team

- 목표, 범위, 일정, 우선순위, 승인 기준을 관리한다.
- 여러 팀의 산출물을 연결하고 다음 작업 순서를 정한다.

### Planning Team

- 요구사항, 사용자 흐름, 시스템 구조, 세부 명세를 정의한다.
- 모호한 표현을 규칙, 수치, 예시로 바꿔 개발과 아트가 같은 목표를 보게 만든다.

### Art Team

- 비주얼 방향, UI/UX 원칙, 에셋 요구사항, 스타일 시스템을 정의한다.
- 사용자가 읽기 쉽고 눌리기 쉬운 화면을 만드는 기준을 관리한다.

### Development Team

- 실제 구현, 통합, 내부 코드 리뷰, 빌드, 개발 검증을 담당한다.
- 요구사항을 동작하는 제품으로 바꾸고, 개발팀 내부에서 빠르게 수정 루프를 돌린다.

### QA Team

- 최종 사용자 관점에서 기능, UX, 기기, 환경, 회귀 이슈를 검증한다.
- 최종 승인 또는 반려 기준을 관리한다.

## 2. 팀 구성 방식

- 모든 팀은 `팀장 에이전트 1명 + 서브 에이전트 여러 명` 구조를 기본으로 한다.
- 팀장은 방향, 우선순위, 승인 기준, 핸드오프를 관리한다.
- 서브 에이전트는 좁은 책임 범위를 맡아 빠르게 실행한다.

## 3. 권장 작업 흐름

1. `PM Team`이 작업 브리프와 승인 기준을 만든다.
2. `Planning Team`이 요구사항과 완료 조건을 정리한다.
3. `Art Team`이 UI/비주얼 기준과 리소스 요구사항을 정리한다.
4. `Development Team`이 구현과 내부 리뷰를 진행한다.
5. `QA Team`이 최종 검증 후 승인 또는 반려를 결정한다.
6. `PM Team`이 결과를 통합하고 다음 작업으로 넘긴다.

## 4. 개발팀과 QA팀의 역할 분리

### 개발팀 내부 리뷰

- 개발팀 안에 `Code Reviewer`를 두고 구현 직후 바로 리뷰한다.
- 목적은 속도와 수정 루프 단축이다.
- 구현자가 만든 변경을 빠르게 검토하고, 즉시 수정 요청과 재확인을 돌린다.

### QA팀 최종 검증

- QA팀은 개발팀과 독립적으로 최종 품질을 본다.
- 목적은 실제 사용자 관점의 안정성과 완성도 확인이다.
- 기능, UX, 기기, 환경, 회귀 관점에서 다시 검증한다.

즉, 개발팀 리뷰는 `빠른 내부 품질 보증`, QA팀은 `출시 전 최종 품질 승인` 역할이다.

## 5. 팀별 기본 서브 에이전트 예시

### PM Team

- `PM Lead`
- `Priority Manager`
- `Risk Manager`
- `Delivery Coordinator`

### Planning Team

- `Planning Lead`
- `Systems Planner`
- `Flow Planner`
- `Balance Planner`
- `Story Planner`

### Art Team

- `Art Lead`
- `UI UX Artist`
- `Asset Spec Artist`
- `World Artist`
- `FX Feedback Artist`

### Development Team

- `Development Lead`
- `Core Developer`
- `UI Developer`
- `Data Tools Developer`
- `Build Integration Developer`
- `Code Reviewer`

### QA Team

- `QA Lead`
- `Feature QA`
- `UX QA`
- `Device QA`
- `Regression QA`

## 6. 권장 AI 모델과 이성 수준

| 역할 | 권장 모델 | 기본 이성 수준 | 사용 이유 |
| --- | --- | --- | --- |
| PM Team Lead | `gpt-5.2` | `high` | 긴 문맥 유지, 우선순위 조정, 다팀 조율에 강함 |
| PM Team Members | `gpt-5.4-mini` | `medium` | 일정 정리, 리스크 정리, 상태 업데이트에 효율적 |
| Planning Team Lead | `gpt-5.4` | `high` | 시스템 기획, 구조화, 모호성 제거에 강함 |
| Planning Team Members | `gpt-5.4` | `medium` 또는 `high` | 밸런스, 스토리, UX 플로우에 유연함 |
| Art Team Lead | `gpt-5.4` | `high` | 비주얼 방향성과 UX 원칙 정리에 적합 |
| Art Team Members | `gpt-5.4` | `medium` | 반복 시안, 에셋 명세, 화면 피드백에 적합 |
| Development Team Lead | `gpt-5.3-codex` | `high` | 구현 범위 분배, 통합, 기술 판단에 적합 |
| Development Team Members | `gpt-5.3-codex` | `medium` | 실제 코드 작업 속도와 안정성 균형이 좋음 |
| Code Reviewer | `gpt-5.4` | `high` | 회귀, 논리 구멍, 리뷰 품질에 강함 |
| QA Team Lead | `gpt-5.4` | `high` | 승인/반려 기준과 품질 판단에 적합 |
| QA Team Members | `gpt-5.4-mini` | `high` | 재현 절차, 체크리스트, 기기별 확인에 효율적 |

## 7. 운영 원칙 요약

- 팀장 에이전트는 더 강한 모델과 더 높은 이성 수준을 사용한다.
- 실행 담당은 빠르고 안정적인 모델을 기본으로 사용한다.
- 리뷰와 QA는 일반 구현보다 한 단계 높은 검토 수준을 유지한다.
- 같은 파일, 같은 데이터, 같은 산출물을 동시에 수정해야 하면 작업 단위를 더 쪼갠다.
- 이 구조는 프로젝트 규모에 따라 축소하거나 확장할 수 있지만, `PM -> Planning/Art -> Development -> QA` 흐름은 유지하는 것이 좋다.

## 8. 바로 적용하는 방법

1. 팀 구조를 먼저 정한다.
2. 각 팀의 팀장과 서브 에이전트 이름을 정한다.
3. 모델과 이성 수준을 역할에 맞게 매핑한다.
4. 작업 브리프와 핸드오프 규칙을 고정한다.
5. 개발팀 내부 리뷰와 QA팀 최종 검증을 분리한다.

## 관련 문서

- [AGENTS.md](/Users/shinehandmac/Documents/puzzle/AGENTS.md)
- [team-structure.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/team-structure.md)
- [model-policy.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/model-policy.md)
- [pm-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/pm-team.md)
- [planning-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/planning-team.md)
- [art-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/art-team.md)
- [development-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/development-team.md)
- [qa-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/qa-team.md)
- [multi-agent.md](/Users/shinehandmac/Documents/puzzle/.codex/workflows/multi-agent.md)
- [task-brief.md](/Users/shinehandmac/Documents/puzzle/.codex/templates/task-brief.md)
