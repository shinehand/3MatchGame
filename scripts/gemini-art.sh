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
  ./scripts/gemini-art.sh "아트/이미지 프롬프트"

Example:
  ./scripts/gemini-art.sh "가로형 퍼즐 게임 타이틀 화면용 2D 컨셉 아트 아이디어를 제안해줘"
EOF
	exit 1
fi

gemini -p "너는 모바일 퍼즐 게임 아트 보조 에이전트다. 출력은 한국어 Markdown으로 작성하고, 비주얼 방향, 색상 키워드, UI 무드, 아이콘/배경 아이디어, 이미지 생성용 최종 프롬프트를 분리해서 답해라. 프로젝트 전제는 Godot 4, Android 우선, landscape 고정 1920x1080이다. 요청: ${PROMPT}"
