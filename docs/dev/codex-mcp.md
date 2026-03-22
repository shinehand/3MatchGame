# Codex MCP Setup

## 등록된 MCP

- `docs-filesystem`
  - 용도: 기획 문서, 백로그, 작업 브리프 같은 Markdown 문서를 Codex가 MCP 경유로 다룰 때 사용
  - 실행 명령: `npx -y @modelcontextprotocol/server-filesystem /Users/shinehandmac/Documents/puzzle`
- `image-gen`
  - 용도: 로컬 Stable Diffusion WebUI API를 Codex에서 직접 호출해 이미지 생성/업스케일링
  - 실행 명령: `node /Users/shinehandmac/Documents/puzzle/.tools/image-gen-mcp/build/index.js`

## 선택 이유

- `docs-filesystem`은 공식 MCP 서버라서 안정적이고, 별도 API 키 없이 로컬 문서 작업에 바로 쓸 수 있다.
- `image-gen`은 로컬 WebUI를 쓰므로 API 비용 없이 실제 이미지를 생성할 수 있다.
- `Gemini CLI`는 여전히 기획 초안과 아트 프롬프트 초안 생성에 유효하다.

## 확인 명령

- `codex mcp list`
- `codex mcp get docs-filesystem`
- `codex mcp get image-gen`

## 메모

- MCP 등록은 전역 Codex 설정(`~/.codex/config.toml`)에 저장된다.
- 아트 초안과 이미지 프롬프트 작업은 [gemini-cli.md](/Users/shinehandmac/Documents/puzzle/docs/dev/gemini-cli.md)를 기준으로 진행한다.
- 로컬 SD 실행 메모는 [local-sd-mcp.md](/Users/shinehandmac/Documents/puzzle/docs/dev/local-sd-mcp.md)를 본다.
