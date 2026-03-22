# Art Refinement Execution

## 목표

- `block-first` 방향을 실제 게임 자산 패키지로 번역한다.

## 아트 우선순위

1. UI 테마 팩
2. HUD/목표 세트
3. 보드 상태 배지 세트
4. 메타 UI 세트
5. 밴드 배경 1-20

## 패키지 정의

### Package A: UI Theme Core

- `button_primary`
- `button_secondary`
- `button_pressed`
- `panel_card`
- `popup_frame`
- `topbar_frame`

### Package B: Goal and HUD

- `goal_chip_frame`
- `moves_badge`
- `score_badge`
- `pause_icon`
- `goal_complete_flash`

### Package C: Board State

- `badge_row`
- `badge_col`
- `badge_bomb`
- `selection_glow`
- `invalid_feedback_overlay`
- `blocker_hit_overlay`

### Package D: Meta UI

- `home_mascot_faces`
- `stage_card_frame`
- `stage_lock`
- `stage_star_1`
- `stage_star_2`
- `stage_star_3`

### Package E: Backgrounds 1-20

- `bg_band_01_main`
- `bg_band_01_sub`
- `bg_band_02_main`
- `bg_band_02_sub`

## 제작 방식

- 컨셉 탐색: Gemini
- 실제 자산 생성: Local SD
- UI 프레임과 배지는 벡터/SVG 우선
- 필요한 경우만 OpenAI Image API로 고난도 편집 보완

## 화면별 결과물

### 홈

- 마스코트 얼굴 3종
- CTA 버튼 1종
- 카드형 로고 패널 1종

### 플레이

- HUD 카드 프레임
- 목표 칩 프레임
- 일시정지 버튼 스타일
- 보드 상태 배지 세트

### 오버레이

- 시작 팝업 프레임
- 클리어 표정형 리소스
- 실패 표정형 리소스

## 품질 기준

- 블록 얼굴을 가리면 반려
- 256px와 소형 축소에서 식별 안 되면 반려
- 배경이 보드보다 먼저 보이면 반려
- 눌림/선택/성공/실패 상태가 즉시 구분되지 않으면 반려

## Art Team 역할 분담

- Art Lead
- 패키지 우선순위와 품질 기준 잠금
- UI UX Artist
- 홈, 플레이, 오버레이 레이아웃 보드
- Asset Spec Artist
- 파일명, 해상도, 연결 규격, 패키지 구조 정의
- World Artist
- 밴드 배경 1-20 제작
- FX Feedback Artist
- 배지, selection, invalid, clear/fail 보조 연출 정의
