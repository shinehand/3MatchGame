# Zoo-Zoo Pop 재구축 개발 적용 로드맵

## 진단

현재 프로젝트는 10종 동물, 무지개 구슬, Combo Gauge, 기본 매치 로직을 갖췄다. 그러나 화면 구조가 게임 연출 중심이 아니라 정보 카드 중심이며, 상위 이펙트 레이어가 없어 매치와 보상이 플레이어에게 크게 보이지 않는다.

## 1차 개발 목표

1. 문서 기준을 고정한다.
2. Gameplay에 `FxLayer`를 추가한다.
3. 매치, 특수 생성, 콤보, 목표 완료, 이동 수 경고, 결과 별 연출을 VFXLayer에서 재생한다.
4. 비활성 보드 칸을 보이게 해 보드 형태를 명확히 한다.
5. 기존 검증 스크립트를 통과시킨다.

## 신규 구조

### Scene

- `scenes/fx_layer.tscn`
  - `CanvasLayer`
  - `BoardFxRoot`
  - `HudFxRoot`
  - `ScreenFxRoot`

### Script

- `scripts/fx_layer.gd`
  - 상위 VFX API 제공
  - 짧은 Tween 기반 연출
  - 보드 로직과 분리

### Gameplay 연결

- `scripts/gameplay.gd`
  - `@onready var fx_layer`
  - `_play_fx_method(method, args)` 헬퍼
  - `_tile_global_center(cell)` 헬퍼
  - 매치 처리 루프에서 `play_match_burst_at`
  - 특수 생성에서 `play_special_created`
  - 콤보 배너에서 `play_combo_banner`
  - 목표 완료에서 `play_goal_rescue`
  - 이동 수 5 이하에서 `play_last_moves_warning`
  - 클리어에서 `play_star_reveal`
  - 무지개 발동에서 `play_rainbow_clear`

## 작업 단계

### Phase 1: 즉시 게임감 회복

- 상위 VFX 레이어 추가.
- 비활성 슬롯 시각화.
- 결과 별 프리뷰 연출 추가.
- 완료 조건: 매치/특수/콤보 효과가 보드 위 레이어에서 보인다.

### Phase 2: 화면 재구성

- Home을 타이틀/마스코트/PLAY 중심으로 재배치.
- World Map 전용 화면 도입.
- Stage Popup 도입.
- 결과 화면을 별/보상/다음 행동 중심으로 재배치.

### Phase 3: Zoo-Zoo Time

- 클리어 후 남은 이동 수를 특수 블록으로 변환.
- 변환 및 폭발 순차 처리.
- 보너스 점수 정산.

### Phase 4: 상용 품질

- Sound/Haptic 패턴 정리.
- 부스터 수량/재화/하트 UI 연결.
- 대표 해상도 스크린샷 QA.
- 스테이지 1~20 밸런스 점검.

## 리스크와 대응

- VFX가 보드 입력을 막는 문제: `mouse_filter = ignore`로 처리.
- 과도한 노드 생성: 1차는 짧은 자동 제거, 2차에서 풀링.
- CanvasLayer가 결과 팝업보다 위에 뜨는 문제: 결과 연출은 의도적으로 위에 두고, 입력 가능한 UI는 마우스 필터로 보호.
- 모바일 텍스트 겹침: 세로 레이아웃에서는 아이콘 버튼과 목표 요약을 우선한다.

## 검증

```bash
zsh scripts/validate_gameplay.sh
```

추가 시각 검증:

- 홈 화면 캡처
- 게임플레이 시작 화면 캡처
- 매치 발생 후 VFX 캡처
- 결과 화면 캡처

## 승인 기준

- `validate_gameplay.sh`가 통과한다.
- Godot가 `scenes/gameplay.tscn`을 에러 없이 로드한다.
- 비활성 보드 칸이 완전히 사라지지 않는다.
- 매치, 특수, 콤보, 목표 완료, 결과 별 연출이 상위 레이어 API를 통해 호출된다.
- 다음 개발자가 Phase 2를 바로 이어갈 수 있도록 문서와 코드가 일치한다.
