#!/bin/zsh

set -euo pipefail

if ! command -v gemini >/dev/null 2>&1; then
	echo "gemini CLI not found. Install or fix PATH first." >&2
	exit 1
fi

PROMPT="${1:-}"

if [ -z "$PROMPT" ]; then
	cat <<'EOF' >&2
Usage:
  ./scripts/gemini-plan.sh "기획 프롬프트"

Example:
  ./scripts/gemini-plan.sh "가로형 모바일 퍼즐 게임의 코어 루프 3가지를 제안해줘"
EOF
	exit 1
fi

gemini -p "너는 모바일 퍼즐 게임 기획 보조 에이전트다. 출력은 한국어 Markdown으로 작성하고, 핵심 루프, 플레이어 목표, 실패 조건, UX 주의점, 구현 우선순위를 분리해서 답해라. 프로젝트 전제는 Godot 4, Android 우선, landscape 고정이다. 요청: ${PROMPT}"
