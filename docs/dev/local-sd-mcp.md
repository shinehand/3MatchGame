# Local Stable Diffusion MCP

로컬 Stable Diffusion WebUI를 `AUTOMATIC1111`으로 띄우고, 이를 `image-gen-mcp`로 Codex에 연결하는 설정 메모다.

## 목표 구조

- WebUI 설치 경로: `~/Applications/stable-diffusion-webui`
- 기본 API 주소: `http://127.0.0.1:7860`
- 기본 모델 경로: `~/Applications/stable-diffusion-webui/models/Stable-diffusion/`
- 현재 기본 모델: `dreamshaper_8.safetensors`
- 실행 스크립트: [start_sd_webui.sh](/Users/shinehandmac/Documents/puzzle/scripts/start_sd_webui.sh)
- 상태 점검: [check_sd_webui.sh](/Users/shinehandmac/Documents/puzzle/scripts/check_sd_webui.sh)
- 호환 스텁: [.tools/sd-webui-stubs/sitecustomize.py](/Users/shinehandmac/Documents/puzzle/.tools/sd-webui-stubs/sitecustomize.py)

## 전제

- Apple Silicon macOS
- `protobuf`, `rust`, `wget`, `python@3.10`
- `AUTOMATIC1111` WebUI clone 완료
- 모델 checkpoint 1개 이상 배치

## 현재 상태

- Codex 전역 MCP에 `image-gen` 등록 완료
- `http://127.0.0.1:7860/sdapi/v1/sd-models` 응답 확인 완료
- 로컬 `txt2img` 생성 확인 완료
- 생성 테스트 결과: [rabbit_local_sd_test.png](/Users/shinehandmac/Documents/puzzle/assets/generated/local-sd/rabbit_local_sd_test.png)
- 현재 가장 안정적인 실행 방식은 `포그라운드 실행`이다

## 실행

가장 안정적인 방식:

```bash
cd /Users/shinehandmac/Documents/puzzle
./scripts/start_sd_webui.sh
```

별도 터미널에서 API 확인:

```bash
cd /Users/shinehandmac/Documents/puzzle
./scripts/check_sd_webui.sh
```

현재 `nohup` 백그라운드 기동은 이 환경에서 재현성 있게 유지되지 않아, 필요할 때 `포그라운드 실행` 기준으로 사용하는 것이 안전하다.

## MCP 연결 목표

- 환경 변수: `SD_WEBUI_URL=http://127.0.0.1:7860`
- MCP 서버: `image-gen-mcp`
- Codex 역할:
  - 기획/아트 문서 초안: Gemini CLI
  - 로컬 실제 이미지 생성: Stable Diffusion WebUI + MCP

## 참고

- AUTOMATIC1111 API 문서: https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/API
- image-gen-mcp 저장소: https://github.com/Ichigo3766/image-gen-mcp
