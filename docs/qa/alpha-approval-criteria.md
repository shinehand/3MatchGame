# Alpha Approval Criteria

알파 승인은 자동 검증과 대표 수동 QA가 함께 통과해야 한다.

## 자동 게이트

- `zsh scripts/validate_gameplay.sh` 통과
- `zsh scripts/validate_alpha_qa_report_contract.sh` 통과
- `zsh scripts/check_android_setup.sh` 통과
- `zsh scripts/export_android_debug.sh` 통과 및 `output/alpha-lock-pass/YYYY-MM-DD/captures/android-debug-export.txt` evidence 생성
- 실기기 QA 시 `zsh scripts/export_android_debug.sh --install` 및 `zsh scripts/capture_android_device_evidence.sh --allow-orientation-change` 통과
- 실기기 수동 판정 후 `zsh scripts/record_manual_device_checks.sh`로 sound/haptics/touch `PASS` evidence 생성
- 수동 QA 완료 후 `zsh scripts/validate_alpha_qa_report.sh --report=output/alpha-lock-pass/YYYY-MM-DD/alpha-lock-pass-manual-qa-YYYY-MM-DD.md` 통과
- 릴리즈 후보는 `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` 설정 후 `zsh scripts/check_android_setup.sh --release`와 `zsh scripts/export_android_release.sh --install` 통과
- 100개 출시 스테이지 JSON 로드
- 대표 스테이지 `1, 11, 25, 50, 75, 100` 존재
- 튜토리얼 체크포인트 `1, 11, 25, 45, 65, 85, 95` 안내 문구 존재
- 핵심 씬 로드: 홈, 스테이지 선택, 게임플레이, 스테이지 카드, 블록 타일, 목표 칩
- Mobile viewport matrix의 홈/월드맵/컬렉션/Stage 4 HUD/Stage Popup/Stage 25 실패 overlay bounds smoke 통과
- Stage Popup, Stage 4 Gameplay HUD, Stage 25 실패 overlay 장문 pseudo-localization bounds/CTA overlap smoke 통과
- 게임플레이 보드 64칸 생성
- 스테이지 선택 카드 100장 생성
- 파일 직접 읽기 기반 텍스처 로딩 안티패턴 없음

## 수동 대표 코스

대표 코스 결과는 [Alpha Lock Pass Manual QA Template](templates/alpha-lock-pass-manual-qa-template.md)로 기록하고, 캡처 경로와 Pass/Fail/Blocked 판정을 남긴다. `zsh scripts/create_alpha_qa_packet.sh --dry-run`은 아래 필수 증거 섹션이 빠지면 실패해야 한다.

- 홈에서 `시작`, `스테이지 라인`, `설정`의 우선순위가 명확하다.
- Stage 1에서 목표, 이동 수, 첫 행동이 10초 안에 이해된다.
- Stage 11, 25에서 새 학습 지점이 진행을 방해하지 않고 방향을 제시한다.
- Stage 50, 75, 100에서 목표/장애물/남은 이동 수가 작은 화면에서도 읽힌다.
- 클리어 오버레이에서 별 등급, 다음 해금, 다음 행동이 명확하다.
- 실패 오버레이에서 부족한 목표와 재도전 행동이 명확하다.
- 저장/해금/별 수가 대표 스테이지 전환 후 유지된다.
- Stage Data Smoke Coverage가 `StageCatalog.recommended_smoke` 스테이지를 `STAGE_SMOKE_###` 행으로 기록하고, Buddy 스테이지는 `BUDDY_STAGE_###` 행과 skill evidence를 남긴다.
- Device Evidence Pack이 build source commit, APK/AAB, install result, device/OS, portrait/landscape screenshot, 10s video, sound/haptics/touch/log evidence를 기록한다.
- Focused Device Gate Matrix가 PAM-QA-040 표정, PAM-QA-041 Stage Popup, Rescue Buddy, Stage 31 특수 조합, monetization gateway, analytics local buffer를 stable scenario ID와 evidence path로 기록한다.
- Stage 31 Special Combo Evidence는 특수+특수 조합 6종을 각각 portrait/landscape evidence, `special_combo_trigger`, 보드 판독성, 사운드/햅틱, 낙하/리필 안정성과 함께 기록한다.
- Rescue Buddy Stage Matrix는 Stage 4, 8, 18, 81 및 첫 등장 대표군 `4/5/8/16/18/20/24/25/31/41/51/81`을 evidence path와 analytics event로 기록한다.
- Failure Continue Gateway와 Analytics Gateway Local Buffer는 rewarded/IAP pending, invalid source, duplicate transaction, local_buffer flush/reload, rejected_contract 격리를 Pass/Fail/Blocked로 기록한다.

## 차단 조건

- 개발용 UI 노출
- HUD가 보드 가독성을 침범
- 특수 블록, 덤불, 선택 상태가 즉시 구분되지 않음
- Android 실기기에서 사운드/햅틱 설정이 동작하지 않음
- 릴리즈 keystore/export preset 프리플라이트 실패
