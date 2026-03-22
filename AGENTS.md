# Codex Team Operating System

이 저장소는 특정 프로젝트에 종속되지 않는 `범용 멀티 에이전트 팀 운영 구조`를 기본값으로 사용한다. 어떤 제품이든 `PM팀`, `기획팀`, `아트팀`, `개발팀`, `QA팀`으로 시작할 수 있고, 각 팀은 `팀장 에이전트`와 여러 `서브 에이전트`로 구성한다.

## 팀 구조

- `PM Team`
  - 목표, 범위, 일정, 우선순위, 담당 배분, 승인 기준을 관리한다.
- `Planning Team`
  - 요구사항, 사용자 흐름, 시스템 기획, 스토리, 밸런스, 세부 명세를 담당한다.
- `Art Team`
  - 비주얼 방향, UI/UX, 에셋 요구사항, 리소스 명세와 스타일 시스템을 담당한다.
- `Development Team`
  - 실제 구현, 통합, 내부 코드 리뷰, 빌드, 개발 검증을 담당한다.
- `QA Team`
  - 최종 사용자 관점 검증, 회귀 테스트, 기기/환경 검증, 릴리즈 승인 전 검수를 담당한다.

## 운영 원칙

- 모든 팀은 `팀장 에이전트 1명 + 서브 에이전트 여러 명` 구조를 기본으로 한다.
- 팀장은 방향, 우선순위, 품질 기준, 핸드오프를 관리한다.
- 서브 에이전트는 좁은 책임 범위에서 빠르게 실행한다.
- `개발팀 내부 리뷰`와 `QA팀 최종 검증`은 분리한다.
- 같은 파일, 같은 데이터, 같은 산출물을 동시에 수정해야 하면 작업 단위를 더 쪼갠다.

## 권장 작업 순서

1. `PM Team`이 작업 브리프와 승인 기준을 만든다.
2. `Planning Team`이 요구사항과 완료 조건을 정리한다.
3. `Art Team`이 UI/비주얼 기준과 리소스 요구사항을 정리한다.
4. `Development Team`이 구현과 내부 리뷰를 진행한다.
5. `QA Team`이 최종 검증 후 승인/반려를 결정한다.
6. `PM Team`이 결과를 통합하고 다음 작업으로 넘긴다.

## 파일 위치

- 팀 문서: `.codex/teams/`
- 역할 문서: `.codex/agents/`
- 운영 흐름: `.codex/workflows/multi-agent.md`
- 작업 템플릿: `.codex/templates/task-brief.md`
- 모델 정책: `.codex/teams/model-policy.md`

## 모델 운영 원칙

- 팀장 에이전트
  - 긴 문맥, 우선순위, 충돌 해결, 승인 기준 정리에 강한 모델을 사용한다.
- 기획/QA 계열
  - 모호성 제거와 깊은 검토가 중요하므로 기본 `high`를 사용한다.
- 아트 계열
  - 반복 생성과 빠른 시안 피드백은 `medium`, 스타일 재정의는 `high`를 사용한다.
- 개발 계열
  - 구현은 `medium`, 구조 변경과 위험한 리팩터링은 `high`를 사용한다.

## 범용 도입 원칙

- 이 문서는 어떤 저장소에서도 그대로 복사해 초기 조직 구조로 사용할 수 있다.
- 실제 프로젝트에서는 각 팀의 서브 에이전트 이름과 파일 소유 범위만 따로 매핑하면 된다.
- 특정 기술 스택, 제품 장르, 플랫폼 제약은 팀 문서가 아니라 해당 프로젝트의 기획/개발 문서에 둔다.

## 시작점

- 새 기능 시작: `.codex/templates/task-brief.md` 복사 후 작성
- 팀 구조 정의: [team-structure.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/team-structure.md)
- 모델 정책 정의: [model-policy.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/model-policy.md)
- PM팀 정의: [pm-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/pm-team.md)
- 기획팀 정의: [planning-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/planning-team.md)
- 아트팀 정의: [art-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/art-team.md)
- 개발팀 정의: [development-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/development-team.md)
- QA팀 정의: [qa-team.md](/Users/shinehandmac/Documents/puzzle/.codex/teams/qa-team.md)
