# 3MatchGame

Godot 4 기반 모바일 3매치 퍼즐 게임 프로젝트입니다.

## 포함 내용

- `project.godot`: 모바일 기준 해상도와 스트레치 설정
- `scenes/main.tscn`: 홈 화면 시작 씬
- `scenes/gameplay.tscn`: 실제 Stage 1 진입용 플레이 씬
- `scenes/block_tile.tscn`: 개별 블록 타일 씬
- `scenes/goal_chip.tscn`: 목표 진행 칩 씬
- `scripts/main.gd`: 홈 화면과 스테이지 선택 오버레이 흐름 스크립트
- `scripts/gameplay.gd`: 스테이지 목표, 이동 수, 점수, 낙하, 연쇄, 리필 로직
- `scripts/block_tile.gd`: 블록 선택 glow, invalid shake, drop-in, pop 연출 처리
- `scripts/goal_chip.gd`: 목표 칩 UI 갱신
- `scripts/game_session.gd`: 진행 저장, 해금, 별 점수, 마지막 선택 스테이지 저장
- `scripts/feedback.gd`: 코드 기반 SFX 합성과 모바일 햅틱 피드백
- `scripts/stage_catalog.gd`: JSON 기반 스테이지 로더
- `scripts/stage_data_validator.gd`: 스테이지 데이터 검증기
- `scripts/validate_stage_balance.gd`: 밴드별 밸런스 규칙 검증기
- `scripts/check_android_setup.sh`: Android 개발 환경 점검 스크립트
- `scripts/validate_stage_data.sh`: JSON 스테이지 데이터 검증 스크립트
- `scripts/validate_stage_balance.sh`: 밴드별 밸런스 검증 스크립트
- `data/stages/`: 밴드 단위 스테이지 JSON 데이터 (`001-100` 이관 완료)
- `AGENTS.md`: Codex 멀티 에이전트 운영 규칙
- `.codex/`: 역할 문서와 작업 템플릿
- `icon.svg`: 프로젝트 아이콘
- `.gitignore`: Godot 캐시와 로컬 빌드 산출물 제외

## 현재 설치 상태

- Godot: `4.6.1`
- JDK: `openjdk@17`
- Android SDK: `~/Library/Android/sdk`
- Godot export templates: `~/Library/Application Support/Godot/export_templates/4.6.1.stable`
- Debug keystore: `~/Library/Application Support/Godot/keystores/debug.keystore`
- 모바일 방향: 가로 고정 (`landscape`)

## 시작 방법

1. 새 터미널을 열거나 `source ~/.zshrc` 를 실행합니다.
2. 프로젝트 루트에서 `./scripts/check_android_setup.sh` 로 환경을 점검합니다.
3. Godot 에디터에서 이 폴더를 Import 합니다.
4. 프로젝트를 열고 `F5`로 기본 씬이 실행되는지 확인합니다.
5. `Project > Export`에서 Android 프리셋을 추가합니다.
6. Android 기기를 USB 디버깅으로 연결한 뒤 디버그 빌드를 테스트합니다.

## 검증 절차

- 자동 점검: `./scripts/validate_gameplay.sh`
- 스테이지 데이터 점검: `zsh scripts/validate_stage_data.sh`
- 스테이지 밸런스 점검: `zsh scripts/validate_stage_balance.sh`
- 검증 문서: [validation-process.md](/Users/shinehandmac/Documents/puzzle/docs/dev/validation-process.md)

## CLI 빌드

- Debug APK 생성: `godot --headless --path . --export-debug Android build/android/puzzle-mobile-starter-debug.apk`
- 기기 설치: `adb install -r build/android/puzzle-mobile-starter-debug.apk`

## Codex 멀티 에이전트

- 루트 규칙: [AGENTS.md](/Users/shinehandmac/Documents/puzzle/AGENTS.md)
- 운영 흐름: [.codex/workflows/multi-agent.md](/Users/shinehandmac/Documents/puzzle/.codex/workflows/multi-agent.md)
- 작업 템플릿: [.codex/templates/task-brief.md](/Users/shinehandmac/Documents/puzzle/.codex/templates/task-brief.md)
- 역할 문서:
  [.codex/agents/planning.md](/Users/shinehandmac/Documents/puzzle/.codex/agents/planning.md)
  [.codex/agents/art.md](/Users/shinehandmac/Documents/puzzle/.codex/agents/art.md)
  [.codex/agents/development.md](/Users/shinehandmac/Documents/puzzle/.codex/agents/development.md)
- MCP 설정 메모: [docs/dev/codex-mcp.md](/Users/shinehandmac/Documents/puzzle/docs/dev/codex-mcp.md)
- Gemini CLI 메모: [docs/dev/gemini-cli.md](/Users/shinehandmac/Documents/puzzle/docs/dev/gemini-cli.md)
- 로컬 SD MCP 메모: [docs/dev/local-sd-mcp.md](/Users/shinehandmac/Documents/puzzle/docs/dev/local-sd-mcp.md)

## 권장 운영

- Codex 문서 작업: `docs-filesystem` MCP
- 기획 초안 생성: `gemini-plan.sh`
- 아트 방향/이미지 프롬프트 초안 생성: `gemini-art.sh`
- 로컬 이미지 생성 백엔드: `AUTOMATIC1111 + image-gen-mcp`
- 로컬 생성 테스트 결과: [rabbit_local_sd_test.png](/Users/shinehandmac/Documents/puzzle/assets/generated/local-sd/rabbit_local_sd_test.png)
- 최종 동물 블록 에셋: [assets/animals](/Users/shinehandmac/Documents/puzzle/assets/animals)
- 배경 이미지: [stage_meadow_bg_v1.png](/Users/shinehandmac/Documents/puzzle/assets/backgrounds/stage_meadow_bg_v1.png)
- 매치 이펙트 이미지: [match_burst_v1.png](/Users/shinehandmac/Documents/puzzle/assets/effects/match_burst_v1.png)
- 장애물 이미지: [bush_obstacle_v1.png](/Users/shinehandmac/Documents/puzzle/assets/effects/bush_obstacle_v1.png)
- 로컬 SD 생성 기록: [local-sd-animal-blocks-2026-03-18.md](/Users/shinehandmac/Documents/puzzle/docs/art/generated/local-sd-animal-blocks-2026-03-18.md)

## 기획 문서

- 요약: [docs/game/brief.md](/Users/shinehandmac/Documents/puzzle/docs/game/brief.md)
- 전체 개요: [game-plan-overview.md](/Users/shinehandmac/Documents/puzzle/docs/game/game-plan-overview.md)
- 상세 기획: [docs/game/game-design.md](/Users/shinehandmac/Documents/puzzle/docs/game/game-design.md)
- 첫 화면부터 첫 스테이지: [first-stage-flow.md](/Users/shinehandmac/Documents/puzzle/docs/game/first-stage-flow.md)
- 스테이지 제작 방식: [stage-production-guide.md](/Users/shinehandmac/Documents/puzzle/docs/game/stage-production-guide.md)
- 100스테이지 곡선: [level-progression-100.md](/Users/shinehandmac/Documents/puzzle/docs/game/level-progression-100.md)
- 100스테이지 명세: [stage-map-spec-001-100.md](/Users/shinehandmac/Documents/puzzle/docs/game/stage-map-spec-001-100.md)
- 밸런스 패스 메모: [balance-pass-2026-03-18.md](/Users/shinehandmac/Documents/puzzle/docs/game/balance-pass-2026-03-18.md)
- 백로그: [docs/game/backlog.md](/Users/shinehandmac/Documents/puzzle/docs/game/backlog.md)
- UX 벤치마크: [docs/game/ux-benchmark.md](/Users/shinehandmac/Documents/puzzle/docs/game/ux-benchmark.md)
- 구현 점검: [implementation-review-2026-03-18.md](/Users/shinehandmac/Documents/puzzle/docs/game/implementation-review-2026-03-18.md)
- 현재 버전 감사: [current-version-audit-2026-03-18.md](/Users/shinehandmac/Documents/puzzle/docs/game/current-version-audit-2026-03-18.md)

## 아트 문서

- 총괄 방향: [docs/art/art-direction.md](/Users/shinehandmac/Documents/puzzle/docs/art/art-direction.md)
- 씬별 아트 컨셉: [scene-art-concept.md](/Users/shinehandmac/Documents/puzzle/docs/art/scene-art-concept.md)
- 씬 레이아웃 보드: [scene-layout-boards.md](/Users/shinehandmac/Documents/puzzle/docs/art/scene-layout-boards.md)
- 블록 퍼스트 씬 설계: [block-first-scene-design.md](/Users/shinehandmac/Documents/puzzle/docs/art/block-first-scene-design.md)
- 컨셉 보드: [concept-board.md](/Users/shinehandmac/Documents/puzzle/docs/art/concept-board.md)
- 동물 블록 명세: [docs/art/animal-blocks.md](/Users/shinehandmac/Documents/puzzle/docs/art/animal-blocks.md)
- HUD/UI 명세: [docs/art/ui-hud.md](/Users/shinehandmac/Documents/puzzle/docs/art/ui-hud.md)
- 현재 아트 감사: [current-art-audit-2026-03-18.md](/Users/shinehandmac/Documents/puzzle/docs/art/current-art-audit-2026-03-18.md)
- 100스테이지 시각 진행: [level-visual-progression.md](/Users/shinehandmac/Documents/puzzle/docs/art/level-visual-progression.md)
- Gemini 프롬프트 팩: [docs/art/gemini-prompts.md](/Users/shinehandmac/Documents/puzzle/docs/art/gemini-prompts.md)
- 실제 생성 결과: [docs/art/generated/gemini-art-draft-2026-03-17.md](/Users/shinehandmac/Documents/puzzle/docs/art/generated/gemini-art-draft-2026-03-17.md)

## 다음 작업

1. 사운드와 햅틱 on/off 설정 화면을 추가합니다.
2. 후반 밴드용 장애물 확장을 준비합니다.
3. 실제 기기 기준 사운드 볼륨과 진동 강도를 미세 조정합니다.
4. 릴리즈 빌드용 별도 keystore 를 만들고 Export preset 에 연결합니다.
