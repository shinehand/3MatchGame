# Development Team 템플릿

## 팀 목표

- 요구사항을 실제 동작하는 제품으로 구현하고, 팀 내부 코드 리뷰까지 완료한다.

## 기본 구성

- `Development Lead`
- `Core Developer`
- `UI Developer`
- `Data Tools Developer`
- `Build Integration Developer`
- `Code Reviewer`

## 팀장 책임

1. 구현 범위를 쪼개고 파일 소유 범위를 정한다.
2. 팀 내부에서 코드 리뷰와 수정 루프를 빠르게 돌린다.
3. 빌드 가능한 상태를 유지한다.

## 서브 에이전트 책임

- `Core Developer`
  - 핵심 로직, 상태, 규칙 구현
- `UI Developer`
  - 화면, 입력, HUD, 전환 구현
- `Data Tools Developer`
  - 데이터 구조, 저장, 검증 도구 구현
- `Build Integration Developer`
  - 빌드, 환경, 배포 연결
- `Code Reviewer`
  - 구현 직후 리뷰, 오류 검출, 수정 요청, 재확인

## 운영 규칙

- 코드 리뷰어는 개발팀 안에서 즉시 리뷰한다.
- 같은 파일을 동시에 수정할 수 없으면 작업을 다시 쪼갠다.
- 리뷰가 끝난 뒤에만 QA로 넘긴다.

## 추천 모델

- Development Lead: `gpt-5.3-codex` / `high`
- Development Members: `gpt-5.3-codex` / `medium`
- Code Reviewer: `gpt-5.4` / `high`
