# Validation Process

## 목적

- 기능 추가 후 `로드만 되는 상태`를 통과로 보지 않는다.
- 최소한 `실제 한 판 플레이` 기준의 검증을 통과해야 Android 재설치로 넘어간다.

## 기본 절차

1. `./scripts/validate_gameplay.sh`
2. Godot 에디터 또는 Android 기기에서 수동 플레이 1회
3. 아래 체크리스트를 모두 통과하면 APK 재빌드

`validate_gameplay.sh`는 아래를 순서대로 검사한다.

- 스테이지 JSON 구조 검증
- 출시 스테이지 100개 로드 여부 검증
- 밴드별 이동 수/덤불 수 밸런스 검증
- Godot 임포트 캐시 준비 (`.godot/`가 없는 클린 체크아웃 대응)
- 핵심 씬 로드 스모크 체크 (`main`, `stage_select`, `gameplay`, 카드/타일/목표 칩)
- 게임플레이 보드 64칸 생성과 스테이지 선택 카드 100장 생성 확인
- Godot 헤드리스 로드
- 파일 직접 읽기 안티패턴 스캔
- 수동 스모크 체크리스트 출력

검증 스크립트는 임시 `HOME`을 사용해 `user://save_game.json`을 격리한다. 따라서 자동 검증은 로컬 플레이 진행도, 튜토리얼 확인 여부, 사운드/햅틱 설정을 변경하지 않는다.

로그/소스 스캔은 `rg`가 있으면 사용하고, 없으면 `grep -R -E -n`으로 자동 대체한다. 검증 환경의 PATH에 `rg`가 없어도 위 절차가 실패하지 않아야 한다.

## No-device 표정 애니메이션 readiness

`./scripts/validate_gameplay.sh`의 scene load smoke는 기기 없이 아래 항목을 먼저 막는다.

- `blink`: 8x8 보드에서 최소 1개, 동시에 최대 4개만 시작된다.
- `blink`: `is_busy == true` 또는 결과 overlay 표시 중에는 새 idle expression이 시작되지 않는다.
- `smile`: `_select_cell()` 경로에서 선택 타일에 연결된다.
- `match`: 제거 직전 우선순위가 가장 높고 `blink`, `smile`, `worried`가 덮지 못한다.
- `worried`: 이동 수 3 이하 HUD 갱신 경로에서 목표 타일 일부에만 표시되고 동시에 4개 이하로 제한된다.
- `fever`: 표정 자체는 Tween 기반이며 목표 UI, 특수 배지, 이동 수 HUD 판독성은 논리 앵커 smoke로 1차 확인한다.

아래 항목은 no-device readiness로 승인하지 않는다. 실제 기기 또는 시뮬레이터에서 portrait/landscape 물리 viewport를 확인해야 한다.

- 블록 얼굴이 safe area, board scroll, HUD에 의해 잘리지 않는지 확인한다.
- 빠른 연쇄 매치, 낙하, 리필 중 표정/VFX 겹침이 과하지 않은지 확인한다.
- 터치감, UI 사운드, 햅틱 강도가 플레이 흐름을 방해하지 않는지 확인한다.

## No-device Stage Popup / 시작 부스터 readiness

`./scripts/validate_gameplay.sh`의 scene load smoke는 기기 없이 아래 항목을 먼저 막는다.

- `WorldStageNode*` press 경로에서 바로 gameplay로 가지 않고 `StagePopupOverlay`가 표시된다.
- Stage Popup은 Level 제목, 목표, 이동 수/난이도/테마, 보상, `START` 버튼을 가진다.
- Buddy가 있는 스테이지의 Stage Popup은 Rescue Buddy 동물명, 스킬명, 충전 조건, 짧은 효과 설명을 보여 준다.
- Buddy가 없는 스테이지의 Stage Popup은 빈 Buddy 영역을 보여 주지 않는다.
- Stage Popup은 `rainbow_paw`, `striped`, `bomb` 시작 부스터 3종 버튼과 아이콘을 가진다.
- 부스터 버튼 선택은 `selected_pre_boosters`와 버튼 pressed 상태에 즉시 반영된다.
- Gameplay 시작 시 `GameSession.selected_pre_boosters`가 소비되고, 선택한 3종이 보드 특수 블록과 `stage_start`/`booster_used` analytics에 반영된다.

아래 항목은 no-device readiness로 승인하지 않는다. 실제 기기 또는 시뮬레이터에서 수동 확인해야 한다.

- Stage Popup 페이드/팝인/닫기 애니메이션이 모바일에서 끊기거나 입력을 막지 않는지 확인한다.
- 시작 부스터가 배치된 첫 보드가 목표 칩, Buddy HUD, 특수 배지와 겹쳐 읽기 어렵지 않은지 확인한다.
- Stage Popup에 표시될 Rescue Buddy 정보 문구와 실제 Gameplay HUD 문구의 톤이 일관적인지 확인한다.

## No-device 결과/실패 오버레이 readiness

`./scripts/validate_gameplay.sh`의 scene load smoke는 기기 없이 아래 항목을 먼저 막는다.

- Stage 1 클리어 판정 경로에서 결과 overlay가 표시되고, 보상/별/점수/다음 행동과 `다음 스테이지`/`홈으로` CTA를 보여 준다.
- Stage 25 near-miss 실패 판정 경로에서 실패 overlay가 표시되고, 실패 유형, 남은 목표, 추천 부스터, `+3 이동 받고 계속`/`재도전` CTA를 보여 준다.
- `+3 이동 받고 계속` primary CTA는 overlay를 닫고 `remaining_moves = 3`, `stage_state = playing`으로 실제 재개한다.
- 실패 overlay 노출, 선택, 추가 이동 지급은 `stage_fail`, `offer_impression`, `fail_offer_show`, `fail_offer_select`, `fail_offer_dismiss`, `extra_moves_grant` analytics에 near-miss 및 보상형 continue 정보를 기록한다.
- `FailOfferPolicy`는 near miss, strategic miss, first fail, repeat fail, hard fail, Level 1-10 수익화 차단을 분리 검증한다.

아래 항목은 no-device readiness로 승인하지 않는다. 실제 기기 또는 시뮬레이터에서 수동 확인해야 한다.

- 보상형 광고 SDK 로드/완료/중단/실패와 구매 취소/실패가 하트, 코인, 이동 수를 꼬이게 하지 않는지 확인한다.
- 결과/실패 overlay 애니메이션, 사운드, 햅틱, 버튼 터치감이 모바일에서 자연스러운지 확인한다.

## 수동 체크리스트

- 홈 화면에서 이어하기 정보와 스테이지 선택 오버레이가 정상 표시된다.
- 스테이지 선택에서 잠금/해금/별 수가 정상 표시된다.
- 스테이지 노드를 누르면 바로 게임으로 가지 않고 Stage Popup이 뜬다.
- Stage Popup에서 목표, 이동 수, 보상, 아이콘이 있는 시작 부스터 3종, START 버튼이 정상 표시된다.
- Stage 4 같은 Buddy 스테이지에서는 Stage Popup의 Buddy 문구와 Gameplay HUD Buddy 문구가 같은 동물/스킬을 가리킨다.
- 부스터를 선택하고 START를 누르면 게임 시작 보드에 선택 부스터가 배치된다.
- 홈 화면 버튼 탭 시 짧은 UI 사운드가 재생된다.
- 앱 시작 후 보드 8x8 블록이 바로 보인다.
- 첫 매치 후 화면 전체가 사라지거나 과하게 깜빡이지 않는다.
- 선택 `smile`, 제거 직전 `match`, 이동 수 3 이하 `worried` 반응이 보이되 보드 판독을 방해하지 않는다.
- 유효 스왑과 실패 스왑의 사운드/진동 느낌이 구분된다.
- 리필 후 남아 있는 블록 위치가 안정적이다.
- 4매치 특수 블록이 생성된다.
- 5매치 특수 블록이 생성된다.
- 자동 headless fixture가 row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb 6종 특수 조합을 중복 제거 없이 검증하고, Stage 31 row+column 실제 swap smoke가 이동 수/점수/장애물/`is_busy` 복귀를 검증한다.
- Stage 31 실제 플레이에서 6종 특수 조합의 VFX 겹침, 낙하/리필 연결, 터치감을 수동 확인한다.
- Stage 4/5/8/16/18/20/24/25/31/41/51/81 첫 등장 Rescue Buddy가 보드/게이지/장애물/점수/추천/구조 이동에 과한 지연 없이 반응한다.
- 덤불 스테이지에서 장애물 오버레이와 목표 칩이 함께 보인다.
- 클리어와 실패 오버레이가 각각 정상 표시된다.
- 클리어/실패 시 피드백 사운드와 진동이 과하지 않은지 확인한다.

## 실패 시 우선 점검

- `Image.load_from_file`, `ProjectSettings.globalize_path` 같은 파일 직접 읽기 사용 여부
- `_refresh_all_tiles()`처럼 보드 전체를 불필요하게 갱신하는 코드 여부
- 모바일에서만 다른 경로를 타는 로직 여부
