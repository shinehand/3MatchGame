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
- 실제 홈 첫 화면의 `GameHomeLayer` CTA/하단 내비게이션과 설정 overlay 토글 확인
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

## No-device 홈/설정 readiness

`./scripts/validate_gameplay.sh`의 scene load smoke는 기기 없이 아래 항목을 먼저 막는다.

- 실제 런타임 홈 UI인 `GameHomeLayer`가 첫 화면에서 보이고, `HomePlayButton`, `BottomNav`, `HomeMapButton`, `HomeCollectionButton`, `HomeSettingsButton`이 논리 viewport 안에 있다.
- 설정 버튼은 `SettingsOverlay`를 열고, 닫기 버튼은 overlay를 숨긴다.
- 사운드/햅틱 토글은 `GameSession` 저장값과 `/root/Feedback`의 `sound_enabled`, `haptics_enabled` 상태를 함께 갱신한다.
- 토글 버튼 라벨은 OFF 상태를 즉시 반영한다.

아래 항목은 no-device readiness로 승인하지 않는다. 실제 기기 또는 시뮬레이터에서 수동 확인해야 한다.

- 실제 스피커/무음 모드/OS 볼륨에서 UI 사운드가 의도한 크기로 들리는지 확인한다.
- Android/iOS 햅틱 강도와 반복 빈도가 플레이 흐름을 방해하지 않는지 확인한다.

## No-device Stage Popup / 시작 부스터 readiness

`./scripts/validate_gameplay.sh`의 scene load smoke는 기기 없이 아래 항목을 먼저 막는다.

- `WorldStageNode*` press 경로에서 바로 gameplay로 가지 않고 `StagePopupOverlay`가 표시된다.
- Stage Popup은 Level 제목, 목표, 이동 수/난이도/테마, 보상, `START` 버튼을 가진다.
- Buddy가 있는 스테이지의 Stage Popup은 Rescue Buddy 동물명, 스킬명, 충전 조건, 짧은 효과 설명을 보여 준다.
- Buddy가 없는 스테이지의 Stage Popup은 빈 Buddy 영역을 보여 주지 않는다.
- Stage Popup은 `rainbow_paw`, `striped`, `bomb` 시작 부스터 3종 버튼과 아이콘을 가진다.
- 부스터 버튼 선택은 `selected_pre_boosters`와 버튼 pressed 상태에 즉시 반영된다.
- Stage Popup 닫기는 tween 이후 overlay를 숨기고 panel scale을 복구한다.
- START 선택값 commit helper는 `GameSession.selected_stage_id`와 `GameSession.selected_pre_boosters`를 gameplay 전환 전에 저장한다.
- Gameplay 시작 시 `GameSession.selected_pre_boosters`가 소비되고, 선택한 3종이 보드 특수 블록과 `stage_start`/`booster_used` analytics에 반영된다.

아래 항목은 no-device readiness로 승인하지 않는다. 실제 기기 또는 시뮬레이터에서 수동 확인해야 한다.

- Stage Popup 페이드/팝인/닫기 애니메이션이 모바일에서 끊기거나 입력을 막지 않는지 확인한다.
- 시작 부스터가 배치된 첫 보드가 목표 칩, Buddy HUD, 특수 배지와 겹쳐 읽기 어렵지 않은지 확인한다.
- Stage Popup에 표시될 Rescue Buddy 정보 문구와 실제 Gameplay HUD 문구의 톤이 일관적인지 확인한다.

## No-device Rescue Book / 라이브 운영 readiness

`./scripts/validate_gameplay.sh`의 scene load smoke는 기기 없이 아래 항목을 먼저 막는다.

- Rescue Book 카드가 토큰 수, 우정 레벨, `NEW`, 잠김 해금 스테이지 문구를 실제 UI 라벨로 표시한다.
- 첫 세션 Level 1-5 순차 클리어가 Stage 6과 `frog`/`koala`/`hamster` Rescue Book 신규 카드를 해금하고 `animal_unlock` analytics를 남긴다.
- Rescue Book 카드 입력 경로가 선택 상세, `NEW` 제거, 토큰/우정 레벨 저장 상태를 유지하는지 확인한다.
- Rescue Book 표정/미리보기 Tween은 화면에 보이는 해금 카드에서 최대 4개만 실행되고, 컬렉션 화면이 숨겨지면 모두 정지한다.
- 라이브 이벤트 노출은 `home`, `stage_select`, `result_overlay`, `collection` placement별 `live_event_impression`을 남긴다.
- 현재 로드된 remote config key는 `remote_config_exposure`로 `variant_id`, `config_key`, `config_value_hash`를 비우지 않고 기록한다.

아래 항목은 no-device readiness로 승인하지 않는다. 실제 기기 또는 시뮬레이터에서 수동 확인해야 한다.

- Rescue Book 스크롤과 카드 탭 반응, 홈/결과/이벤트 진입 복귀 흐름이 모바일에서 자연스러운지 확인한다.
- 라이브 이벤트 칩, 상세 overlay, 결과/컬렉션 이벤트 문구가 실제 해상도에서 잘리지 않는지 확인한다.

## No-device 결과/실패 오버레이 readiness

`./scripts/validate_gameplay.sh`의 scene load smoke는 기기 없이 아래 항목을 먼저 막는다.

- Stage 1 클리어 판정 경로에서 결과 overlay가 표시되고, 보상/별/점수/다음 행동과 `다음 스테이지`/`홈으로` CTA를 보여 준다.
- Stage 1 FTUE 실패 판정 경로에서 실패 overlay는 `무료 재도전` CTA를 보여 주고 보상형 광고/IAP 문구를 노출하지 않는다.
- Stage 25 near-miss 실패 판정 경로에서 실패 overlay가 표시되고, 실패 유형, 남은 목표, `놓친 핵심`, `다음 한 수`, 추천 부스터, `+3 이동 받고 계속`/`재도전` CTA를 보여 준다.
- 실패 overlay helper smoke는 수집 동물 미달, 점수 미달, 덤불 미달의 `놓친 핵심`/`다음 한 수` 문구를 분리 검증한다.
- Stage 20 `loyal_fetch`는 `_check_stage_state()`의 실패 판정 경로에서 실패 overlay와 `stage_fail`/`fail_offer_show`를 띄우기 전에 구조 이동 1회를 지급하는지 검증한다.
- `+3 이동 받고 계속` primary CTA는 overlay를 닫고 `remaining_moves = 3`, `stage_state = playing`으로 실제 재개한다.
- `재도전` secondary CTA는 같은 Stage 25를 새 이동 수/점수 0/장애물 0/overlay hidden 상태로 다시 시작한다.
- 광고 실패/IAP 취소·실패·복구는 overlay, 이동 수, 점수, 목표 진행, wallet을 보존하고 추가 이동을 지급하지 않는다.
- IAP 성공형 continue는 `iap_purchase_complete`와 `extra_moves_grant`가 같은 `transaction_id`를 공유하고 추가 이동을 1회만 지급한다.
- 보상형 광고와 IAP continue는 같은 `transaction_id`가 새 실패 오퍼에서 다시 들어와도 추가 이동과 완료 analytics를 중복 지급하지 않는다.
- 코인 continue는 충분한 gold가 있을 때만 gold를 차감하고 `coin_continue_moves`만큼 재개하며, gold 부족 시 상태를 보존한다.
- 실패 overlay 노출, 선택, 광고/IAP 결과, 추가 이동 지급은 `stage_fail`, `offer_impression`, `fail_offer_show`, `fail_offer_select`, `fail_offer_dismiss`, `ad_reward_complete`, `ad_reward_fail`, `iap_purchase_start`, `iap_purchase_complete`, `iap_purchase_restore`, `iap_purchase_cancel`, `iap_purchase_fail`, `extra_moves_grant` analytics에 near-miss 및 continue 정보를 기록한다.
- `FailOfferPolicy`는 near miss, strategic miss, first fail, repeat fail, hard fail, Level 1-10 수익화 차단을 분리 검증한다.

아래 항목은 no-device readiness로 승인하지 않는다. 실제 기기 또는 시뮬레이터에서 수동 확인해야 한다.

- 보상형 광고 SDK 로드/완료/중단/실패와 구매 성공/취소/실패/복구가 하트, 코인, 이동 수를 꼬이게 하지 않는지 확인한다.
- 결과/실패 overlay 애니메이션, 사운드, 햅틱, 버튼 터치감이 모바일에서 자연스러운지 확인한다.

## 수동 체크리스트

- 홈 화면에서 이어하기 정보와 스테이지 선택 오버레이가 정상 표시된다.
- 스테이지 선택에서 잠금/해금/별 수가 정상 표시된다.
- 스테이지 노드를 누르면 바로 게임으로 가지 않고 Stage Popup이 뜬다.
- Stage Popup에서 목표, 이동 수, 보상, 아이콘이 있는 시작 부스터 3종, START 버튼이 정상 표시된다.
- Stage 4 같은 Buddy 스테이지에서는 Stage Popup의 Buddy 문구와 Gameplay HUD Buddy 문구가 같은 동물/스킬을 가리킨다.
- 자동 scene smoke는 Stage 4 Rescue Buddy HUD가 숨김 없음, 0/3, 2/3, 출동, 완료 상태를 순서대로 표시하는지 확인한다.
- 자동 scene smoke는 목표 동물 3매치 하나가 Buddy 차지 1회로만 집계되고, 단일 매치만으로 준비 상태가 되지 않는지 확인한다.
- 자동 scene smoke는 Stage 18 `leap_clear`와 Stage 81 `mighty_push`가 마지막 덤불 목표를 Buddy 단독으로 완료하려 할 때 차단되는지 확인한다.
- 부스터를 선택하고 START를 누르면 게임 시작 보드에 선택 부스터가 배치된다.
- Rescue Book 카드에서 해금 동물의 토큰/우정 레벨/NEW 상태와 잠김 동물의 해금 스테이지 문구가 정상 표시되는지 확인한다.
- 라이브 이벤트 노출이 홈, 스테이지 선택, 결과 오버레이, 컬렉션에서 각각 `live_event_impression`으로 기록되는지 확인한다.
- 홈 화면 버튼 탭 시 짧은 UI 사운드가 재생된다.
- 앱 시작 후 보드 8x8 블록이 바로 보인다.
- 첫 매치 후 화면 전체가 사라지거나 과하게 깜빡이지 않는다.
- 선택 `smile`, 제거 직전 `match`, 이동 수 3 이하 `worried` 반응이 보이되 보드 판독을 방해하지 않는다.
- 목표 완료 시 동물명 구출, 덤불 정리, 점수 달성 피드백이 구분되어 보인다.
- 유효 스왑과 실패 스왑의 사운드/진동 느낌이 구분된다.
- 리필 후 남아 있는 블록 위치가 안정적이다.
- 4매치 특수 블록이 생성된다.
- 5매치 특수 블록이 생성된다.
- 자동 headless fixture가 row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb 6종 특수 조합을 중복 제거 없이 검증하고, Stage 31 실제 swap smoke가 6종 모두의 이동 수/점수/장애물/`is_busy` 복귀를 검증한다. `FxLayer` smoke는 특수 조합 전용 flash/ring/label VFX 생성도 확인한다.
- Stage 31 실제 swap smoke는 6종 특수 조합의 `special_combo_trigger` analytics가 조합 타입, from/to 특수, 제거 수, 장애물 제거 수를 남기는지도 확인한다.
- Stage 31 실제 swap smoke는 6종 특수 조합이 일반 매치 사운드가 아니라 `special_combo` 전용 피드백과 강한 햅틱 요청을 남기는지도 확인한다.
- `FxLayer` smoke는 매치 burst, 특수 생성, 특수 조합, 콤보 배너, 목표 완료, 덤불 제거, 이동 경고, 보너스 점수, 무지개 VFX를 동시에 호출한 뒤 child count 상한과 transient node cleanup을 확인한다.
- Stage 31 실제 플레이에서 6종 특수 조합의 VFX 겹침, 낙하/리필 연결, 터치감을 수동 확인한다.
- Stage 4/5/8/16/18/20/24/25/31/41/51/81 첫 등장 Rescue Buddy가 보드/게이지/장애물/점수/추천/구조 이동에 과한 지연 없이 반응한다.
- 덤불 스테이지에서 장애물 오버레이, 목표 칩, 덤불 제거 전용 사운드/진동/VFX가 함께 보인다.
- 클리어와 실패 오버레이가 각각 정상 표시된다.
- 클리어/실패 시 피드백 사운드와 진동이 과하지 않은지 확인한다.

## 실패 시 우선 점검

- `Image.load_from_file`, `ProjectSettings.globalize_path` 같은 파일 직접 읽기 사용 여부
- `_refresh_all_tiles()`처럼 보드 전체를 불필요하게 갱신하는 코드 여부
- 모바일에서만 다른 경로를 타는 로직 여부
