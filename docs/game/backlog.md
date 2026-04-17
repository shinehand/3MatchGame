# Backlog

## Done (구현 완료)

- `JSON` 기반 100스테이지 카탈로그 구조 추가
- `stage_id` 기반 저장 구조 설계 및 구현
- 스테이지 데이터 검증 도구 추가 (`validate_stage_data.sh`, `stage_data_validator.gd`)
- 스테이지 밸런스 검증 도구 추가 (`validate_stage_balance.sh`, `validate_stage_balance.gd`)
- 스테이지 선택 화면 설계 및 구현 (`scenes/stage_select.tscn`)
- 1-100 스테이지 JSON 데이터 이관 완료
- 스토리 캠페인 문서화 (`docs/game/story-campaign.md`)
- 밴드별 구역 이름과 카피 정리 (`stage_select.gd`의 BAND_META)
- 밴드별 배경 에셋 세트 (1-100, `bg_band_01`~`bg_band_10`)
- 튜토리얼 소프트 가이드 (Stage 1·3·7·11·15·25·45·65·85·95)
- 튜토리얼 1회성 저장 (`seen_tutorial_stage_ids`)
- 사운드 SFX (코드 기반, `feedback.gd`)
- 햅틱 피드백 (`Input.vibrate_handheld`, Android VIBRATE 권한 반영)
- 진행 저장 / 해금 / 별점 저장 (`game_session.gd`)
- 홈 화면 설정 오버레이 (사운드·햅틱 ON/OFF)
- 이동수 경고 색상 (≤5 주황, ≤3 빨강)
- 별 등급 비율 기반 계산 (총이동수 대비)
- 콤보 배너 배수 텍스트 표시
- 개별 목표 달성 사운드 피드백
- 일시정지 버튼 및 일시정지 오버레이

## Now

- 릴리즈 keystore 분리 및 export preset 연결
- 오버레이 가독성 개선 (별 등급·해금 정보 인지성)
- 대표 스테이지 QA 게이트 통과 검증 (Stage 1, 11, 25, 50, 75, 100)

## Next

- 후반 밴드 장애물 확장 (기획·데이터·QA 준비)
- 31~100 밸런스 패스
- 클리어 별 팝 애니메이션
- 동물 구출 감정형 이펙트
- BGM 루프 추가

## Later

- 광고/과금
- 이벤트 스테이지
- 라이브 운영용 레벨 조정
