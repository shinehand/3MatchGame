# Technical Plan

## 현재 구조

- 시작 씬: `scenes/main.tscn`
- 홈 스크립트: `scripts/main.gd`
- 플레이 씬: `scenes/gameplay.tscn`
- 플레이 스크립트: `scripts/gameplay.gd`
- 타일 씬: `scenes/block_tile.tscn`
- 타일 스크립트: `scripts/block_tile.gd`
- 목표 칩 씬: `scenes/goal_chip.tscn`
- 진행 저장: `scripts/game_session.gd`
- 피드백 시스템: `scripts/feedback.gd`
- 스테이지 데이터: `scripts/stage_catalog.gd`
- 스테이지 JSON: `data/stages/stages_001_010.json`, `data/stages/stages_011_020.json`, `data/stages/stages_021_030.json`, `data/stages/stages_031_040.json`, `data/stages/stages_041_050.json`, `data/stages/stages_051_060.json`, `data/stages/stages_061_070.json`, `data/stages/stages_071_080.json`, `data/stages/stages_081_090.json`, `data/stages/stages_091_100.json`
- 로컬 SD 동물 블록 연결 완료
- 선택 glow, invalid shake, 매치 pop 연출 연결 완료
- 스테이지 목표, 이동 수, 점수 HUD 연결 완료
- 낙하, 리필, 연쇄 처리 연결 완료
- 난이도별 블록 출현 가중치 연결 완료
- 4매치 줄 제거, 5매치 폭발 특수 블록 연결 완료
- 귀여운 배경 이미지와 매치 버스트 이미지 연결 완료
- 덤불 장애물 레이어와 목표 칩 연결 완료
- Android debug export 준비 완료
- 비정형 `board_mask` 보드 지원 완료
- 100스테이지용 데이터 아키텍처 문서 정리 완료
- 1-100 스테이지 JSON 이관 완료
- `scripts/stage_data_validator.gd`와 `scripts/validate_stage_data.sh` 추가 완료
- `scripts/validate_stage_balance.gd`와 `scripts/validate_stage_balance.sh` 추가 완료
- `validate_gameplay.sh`에 구조 검증과 밸런스 검증 통합 완료
- `stage_id` 기반 저장 구조 완료
- 홈 화면 스테이지 선택 오버레이 완료
- 코드 기반 SFX와 모바일 햅틱 피드백 연결 완료

## 다음 구현 후보

- 100스테이지 밸런스 패스
- 사운드와 햅틱 on/off 설정 화면
- 후반 밴드용 장애물 확장

## 개발 원칙

- 씬과 스크립트 책임을 명확히 분리한다.
- 임시 구현도 실행 가능 상태를 유지한다.
- 큰 기능은 작은 검증 가능한 단위로 나눈다.
