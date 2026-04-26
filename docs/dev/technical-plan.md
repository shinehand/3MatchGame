# Technical Plan

## 현재 구조

- 시작 씬: `scenes/main.tscn`
- 홈 스크립트: `scripts/main.gd`
- 스테이지 선택 씬: `scenes/stage_select.tscn`
- 스테이지 선택 스크립트: `scripts/stage_select.gd`
- 플레이 씬: `scenes/gameplay.tscn`
- 플레이 스크립트: `scripts/gameplay.gd`
- 타일 씬: `scenes/block_tile.tscn`
- 타일 스크립트: `scripts/block_tile.gd`
- 목표 칩 씬: `scenes/goal_chip.tscn`
- 목표 칩 스크립트: `scripts/goal_chip.gd`
- 스테이지 카드 씬: `scenes/stage_card.tscn`
- 스테이지 카드 스크립트: `scripts/stage_card.gd`
- 진행 저장: `scripts/game_session.gd`
- 피드백 시스템: `scripts/feedback.gd`
- 스테이지 데이터 로더: `scripts/stage_catalog.gd`
- 스테이지 JSON: `data/stages/stages_001_010.json` ~ `data/stages/stages_091_100.json`
- 반응형 레이아웃 헬퍼: `scripts/mobile_layout.gd`

## 구현 완료 항목

- 동물 블록 5종 텍스처 연결
- 선택 glow, invalid shake, 매치 pop 연출
- 스테이지 목표, 이동 수, 점수 HUD
- 낙하, 리필, 연쇄 처리
- 난이도별 블록 출현 가중치
- 4매치 줄 제거, 5매치 폭발 특수 블록
- 배경 이미지와 매치 버스트 이미지
- 덤불 장애물 레이어와 목표 칩
- 비정형 `board_mask` 보드 지원
- 1-100 스테이지 JSON 데이터 이관 완료
- `stage_data_validator.gd` + `validate_stage_data.sh`
- `validate_stage_balance.gd` + `validate_stage_balance.sh`
- `validate_gameplay.sh` 통합 검증
- `stage_id` 기반 저장 구조
- 전용 스테이지 선택 씬 (스토리 라인, 밴드 진행, 선택 스테이지 포커스)
- 코드 기반 SFX (9종 사운드 스트림)
- 모바일 햅틱 피드백 (iOS·Android, VIBRATE 권한 반영)
- 사운드·햅틱 ON/OFF 설정 오버레이 (홈 화면)
- 소프트 튜토리얼 (10개 지점) + 1회성 저장
- 이동수 경고 색상 (주황·빨강)
- 별 등급 비율 기반 계산
- 콤보 배너 배수 텍스트
- 개별 목표 달성 사운드 피드백
- 일시정지 버튼 및 오버레이
- portrait/landscape 반응형 레이아웃
- 밴드별 배경 (bg_band_01~bg_band_10)
- Android debug export (arm64-v8a, VIBRATE 권한)

## 다음 구현 후보

- 릴리즈 keystore 분리 및 export preset 연결
- 클리어 별 팝 애니메이션
- 후반 밴드 장애물 확장
- BGM 루프

## 개발 원칙

- 씬과 스크립트 책임을 명확히 분리한다.
- 임시 구현도 실행 가능 상태를 유지한다.
- 큰 기능은 작은 검증 가능한 단위로 나눈다.
