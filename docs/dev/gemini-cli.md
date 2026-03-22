# Gemini CLI Setup

## 왜 Gemini CLI를 쓰는가

- API 키 기반 과금 대신 Google 로그인 기반 무료 사용 흐름을 우선하려는 목적에 맞다.
- 기획 문서 초안과 아트용 프롬프트 정리에 모두 활용할 수 있다.
- Codex의 MCP와는 별개로, 로컬 보조 에이전트처럼 사용할 수 있다.

## 현재 상태

- `gemini` 실행 파일은 이 Mac에 이미 설치되어 있다.
- 프로젝트 래퍼 스크립트:
  - [gemini-plan.sh](/Users/shinehandmac/Documents/puzzle/scripts/gemini-plan.sh)
  - [gemini-art.sh](/Users/shinehandmac/Documents/puzzle/scripts/gemini-art.sh)

## 첫 설정

1. 터미널에서 `gemini` 또는 `gemini auth login` 을 실행한다.
2. 브라우저 로그인 흐름이 뜨면 개인 Google 계정으로 로그인한다.
3. 로그인 후 아래 예시 명령으로 응답이 오는지 확인한다.

## 사용 예시

- 기획 초안:
  - `./scripts/gemini-plan.sh "초반 3분 플레이 루프를 설계해줘"`
- 아트 초안:
  - `./scripts/gemini-art.sh "밝고 선명한 2D 퍼즐 게임 HUD 컨셉을 정리해줘"`

## 운영 권장

- 기획 에이전트는 Gemini CLI로 초안을 만든 뒤 `docs/game/` 문서에 정리한다.
- 아트 에이전트는 Gemini CLI로 스타일 방향과 이미지 생성 프롬프트를 만든 뒤 실제 제작 또는 이미지 생성 도구로 넘긴다.
- Codex 안에서 자동 도구처럼 쓰기보다, 로컬 보조 CLI로 사용하는 편이 구조상 안정적이다.

## 참고

- Gemini CLI 공식 저장소: https://github.com/google-gemini/gemini-cli
- Gemini API 이미지 생성 문서: https://ai.google.dev/gemini-api/docs/image-generation
