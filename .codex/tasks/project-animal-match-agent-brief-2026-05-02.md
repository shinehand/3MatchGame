# Project Animal Match Agent Brief

## 작업명

- Project Animal Match 6인 멀티 에이전트 산출물 체계 구축

## 목표

- Godot 4.x 기반 글로벌 모바일 매치3 프로젝트를 기획, PM, 아트, 기술, 연출, BM 관점에서 동시에 확장 가능한 상태로 만든다.

## 범위

- 포함
  - 6인 에이전트별 역할 문서
  - 에이전트 실행 워크플로
  - 핵심 기획서, 마스터 개발 플랜, 비주얼 스타일 가이드, 기술 아키텍처, 애니메이션/VFX 문서, BM/운영 문서
  - 에이전트 시작점, 구현 백로그, 동물 표정 시스템 명세, QA 게이트
  - 산출물 인덱스
- 제외
  - 실제 Godot 씬/스크립트 구현 변경
  - 신규 이미지 생성 또는 에셋 파일 제작
  - 스토어 계정 생성, SDK 실제 연동

## 승인 기준

1. 모든 에이전트가 같은 공통 컨텍스트를 가진다.
2. 각 에이전트의 입력, 산출물, 핸드오프 대상이 명확하다.
3. 실제 문서 산출물이 `docs/` 하위에 존재한다.
4. 개발팀이 기술 문서를 보고 구현 범위와 검증 방향을 잡을 수 있다.
5. PM이 로드맵과 리스크를 기준으로 다음 작업을 쪼갤 수 있다.

## 주요 문서

- `.codex/workflows/project-animal-match-multi-agent.md`
- `docs/project-animal-match-agent-start-here.md`
- `docs/project-animal-match-agent-output-index.md`
- `docs/dev/project-animal-match-implementation-backlog.md`
- `docs/dev/project-animal-match-animal-expression-system.md`
- `docs/qa/project-animal-match-development-gates.md`
- `docs/game/project-animal-match-core-design.md`
- `docs/pm/project-animal-match-master-development-plan.md`
- `docs/art/project-animal-match-visual-style-guide.md`
- `docs/dev/project-animal-match-technical-architecture.md`
- `docs/art/project-animal-match-animation-vfx.md`
- `docs/ops/project-animal-match-business-operations.md`

## 다음 작업 후보

1. 기술 문서 기준으로 Godot 스크립트 리팩터링 범위를 확정한다.
2. 비주얼 스타일 가이드 기준으로 동물 12종 최종 에셋과 표정 프레임을 생성한다.
3. BM 문서 기준으로 분석 이벤트와 원격 설정 스키마를 구현한다.
