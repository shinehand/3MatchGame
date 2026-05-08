# Project Animal Match Development Gates

## 목적

기획 보고서를 실제 개발로 옮긴 뒤 QA 에이전트가 승인/반려를 판단하는 기준을 정의한다.

## 공통 게이트

모든 개발 작업은 다음 항목을 보고해야 한다.

- 작업 카드 id
- 변경 파일
- 실행한 검증 명령
- 통과/실패 결과
- 남은 리스크

## Gate 0A. Alpha QA Report Validator Contract

- `zsh scripts/validate_alpha_qa_report_contract.sh`는 임시 PASS report/evidence fixture가 `validate_alpha_qa_report.sh`를 통과하는지 검증한다.
- 같은 contract smoke는 `Pending`/`Blocked` 잔존, evidence 누락/빈 파일, Rescue Book cosmetic equip 필수 행 삭제, 현재 HEAD와 다른 build commit, Android device evidence `BLOCKED`, release install `NOT_REQUESTED` fixture가 반드시 실패하는지도 검증한다.
- 이 gate는 최종 실기기 evidence를 대체하지 않고, 최종 alpha report validator가 느슨해지는 회귀만 차단한다.

## Gate 0B. No-device Render Snapshot Smoke

- `zsh scripts/validate_render_snapshots.sh`는 Home, Stage Popup, Stage 4 Gameplay Buddy HUD 4상태, Stage 1 성공 결과 overlay, Stage 25 실패 overlay, Stage 31 특수 조합 6종, Collection을 `390x844`와 `844x390` PNG 30장으로 저장한다.
- 각 snapshot은 파일 생성, 요청 viewport 크기, non-blank/varied pixel, 핵심 UI region의 실제 렌더 픽셀을 검증한다.
- Stage 1 성공 결과 snapshot은 보상/별/Zoo-Zoo Time/`다음 스테이지`/`홈으로` CTA, `stage_complete` analytics, Stage 2 해금을 검증한다.
- Stage 4 Buddy HUD snapshot은 0/3, 2/3, 출동, 완료 상태에서 portrait 라벨/게이지와 landscape combo text가 읽히고, `buddy_skill_charge`/`buddy_skill_ready`/`buddy_skill_trigger` analytics payload가 중복 없이 기록되는지 검증한다.
- Stage 31 특수 조합 snapshot은 실제 `_resolve_swap` 발동 직후 조합별 label/flash/ring, explosive echo ring 필요 여부, filename combo type, `special_combo_trigger` analytics payload, transient VFX cleanup을 검증한다.
- Collection snapshot은 `rabbit` 40토큰과 `rabbit_sprout_frame` 장착 fixture에서 상세 reward track, `CosmeticEquipGrid`, `장착중` 버튼 region을 검증한다.
- GitHub-hosted runner에서는 Xvfb renderer 실패가 전체 no-device gate를 막지 않도록 non-blocking artifact attempt로만 실행하며, 로컬 또는 지원되는 Xvfb 환경에서는 blocking으로 실행한다.
- 이 gate는 blank/transparent/offscreen/missing texture 회귀를 차단하지만, 최종 Android 실기기 screenshot/video/logcat evidence를 대체하지 않는다.

## Gate 0C. Commercial UI Readability & Touch Target

- 자동 scene smoke는 홈, 월드맵, Stage Popup, gameplay HUD/실패 overlay, Rescue Book 핵심 CTA가 mobile viewport matrix에서 논리 viewport 안에 남는지 검증한다.
- 핵심 상용 CTA는 primary `144x48`, secondary `88x44`, icon/stage node `44x44` 이상 터치 타깃을 가져야 한다.
- 버튼은 visible text, child label, icon, tooltip 중 하나로 식별 가능해야 하며, enabled 버튼 대비는 `3.0:1`, disabled 버튼 대비는 `2.0:1` 이상이어야 한다.
- 이 gate는 논리 px 기반 no-device 회귀 방지용이며, 실제 Android 물리 터치감과 색감은 최종 device evidence에서 별도 승인한다.

## Gate 1. 문서 일치

- `docs/project-animal-match-agent-start-here.md`의 현재 결정 사항과 충돌하지 않는다.
- `docs/planning/project-animal-match-decision-register.md`의 Locked 결정과 충돌하지 않는다.
- `docs/planning/project-animal-match-system-rules-matrix.md`의 입력/출력/예외 조건과 구현이 일치한다.
- `docs/planning/project-animal-match-analytics-remote-config-spec.md`의 필수 이벤트/파라미터와 충돌하지 않는다.
- `docs/planning/project-animal-match-animal-roster-animation-matrix.md`의 보드 12종/컬렉션 18종 구분과 구현 데이터가 일치한다.
- `docs/planning/project-animal-match-level-progression-content-bible.md`의 Stage 1-10 FTUE와 밴드별 난이도 파형을 위반하지 않는다.
- 작업 결과가 `docs/dev/project-animal-match-implementation-backlog.md`의 완료 기준을 만족한다.
- 새 규칙이 생기면 관련 기획/기술/QA 문서가 함께 갱신된다.

## Gate 2. 스테이지 데이터

- `data/stages/*.json`이 모두 로드된다.
- 각 스테이지의 `spawn_profile.pool`은 기본 5-6종이다.
- 튜토리얼 구간은 4-5종을 허용한다.
- 목표 동물은 반드시 pool과 weights에 포함된다.
- 검증 명령:

```sh
./scripts/validate_stage_data.sh
./scripts/validate_stage_balance.sh
```

## Gate 3. 12종 로스터

- `rabbit`, `bear`, `cat`, `chick`, `frog`, `dog`, `panda`, `pig`, `penguin`, `fox`, `lion`, `elephant`가 코드와 validator에서 같은 기준으로 존재한다.
- MVP 보드 12종은 `assets/generated/candy/{id}_candy_block.png` 전용 256px 기본 블록 Texture2D로 직접 로드된다.
- 컬렉션 전용 동물이나 atlas/overlay 에셋 누락은 명시 fallback으로 표시되어 게임 진행을 막지 않는다.
- 목표 UI와 결과 UI에서 동물명이 누락되지 않는다.

## Gate 4. 표정 애니메이션

- 대기 중 blink는 동시에 최대 4개 타일이다.
- `is_busy == true`일 때 새 idle expression이 시작되지 않는다.
- 타일 선택 시 smile 반응이 보인다.
- 매치 제거 직전 match 반응이 보인다.
- 이동 수 부족 또는 실패 직전 worried 반응이 과하지 않게 보인다.
- 표정 연출이 스와이프, 낙하, 리필, 특수 블록 발동을 막지 않는다.
- 목표 완료 피드백은 수집 동물명, 덤불 정리, 점수 달성을 구분해 표시한다.
- 실제 기기 최종 QA는 `docs/qa/project-animal-match-expression-qa-readiness-2026-05-08.md` 실행표에 build commit, 기기/OS, orientation, evidence path, result를 남긴다.

## Gate 4A. 특수 블록 조합

- 특수+특수 조합은 일반 매치보다 먼저 처리된다.
- 4매치는 방향에 맞는 row/column 특수를 만들고, 5매치는 rainbow 특수를 만든다.
- row+column, row+row, column+column, row+bomb, column+bomb, bomb+bomb 6종은 중복 제거 없이 1회씩 처리된다.
- 특수 조합 경로 위의 chained special과 인접 장애물 피해가 scene smoke에서 검증된다.
- Stage 31 특수 조합 6종은 실제 `_resolve_swap` runtime smoke에서 이동 수 1회 소모, 점수 증가, 장애물 제거, `is_busy` 복귀를 검증한다.
- 특수+특수 발동 시작점은 `FxLayer.play_special_combo` 전용 shaped flash/beam, ring, 조합별 label VFX로 일반 매치 burst와 구분된다.
- 특수+특수 발동은 `Feedback.play_special_combo` 전용 SFX/haptic 경로를 사용해 일반 매치 피드백과 구분된다.
- 특수+특수 발동은 조합 타입별 VFX 라벨과 `special_combo_trigger` analytics로 6종 타입/제거 수/장애물 수를 기록한다.
- no-device render snapshot은 Stage 31 실제 `_resolve_swap` 발동 직후 6종 조합의 label/flash/ring이 portrait/landscape PNG에서 보이고 화면 안에 들어오는지 확인한다.
- 덤불/장애물 제거는 전용 VFX와 SFX/haptic 경로를 가져 일반 매치 피드백과 구분된다.
- rainbow+special은 특수+특수 큐보다 rainbow resolution 경로를 우선한다.
- 실제 기기 최종 QA는 Stage 31에서 특수+특수 조합 6종 모두를 portrait/landscape 증거 영상 또는 연속 캡처로 남기고, 보드 판독성 반려 여부를 기록한다.

## Gate 5. 모바일 UI

- portrait와 landscape에서 보드가 잘리지 않는다.
- 동물 얼굴과 특수 배지가 서로 가리지 않는다.
- 목표 칩 숫자와 동물 아이콘이 작은 화면에서도 구분된다.
- 피버/표정/VFX가 겹쳐도 목표 UI가 읽힌다.

## Gate 6. 성능

- 일반 매치 파티클은 10개 이하, 특수 블록 파티클은 40개 이하를 기준으로 한다.
- FxLayer scene smoke는 매치/특수 생성/특수 조합/무지개/목표/경고/점수 VFX 동시 호출 시 child count 상한과 cleanup을 검증한다.
- idle expression은 atlas region 변경 또는 단일 Tween 위주로 처리한다.
- 동물별 개별 Timer를 64개 타일 전체에 붙이지 않는다.
- 저사양 기준에서 콤보 5단계 연출 중 체감 입력 지연이 없어야 한다.
- 홈 설정의 사운드/햅틱 토글은 저장값과 실제 `Feedback` 상태를 함께 바꾸며, 자동 scene smoke가 이 연결을 검증한다.

## Gate 7. FTUE/첫 세션 리텐션

- 신규 설치 후 3탭 이내 Stage 1에 진입할 수 있다.
- Stage 1 시작 후 30초 이내 첫 유효 매치가 가능하다.
- 완료한 튜토리얼 설명이 같은 계정/기기에서 반복 노출되지 않는다.
- Level 1-10에서 하트 소모, 전면 광고, IAP 팝업이 나오지 않는다.
- Level 5 이내 첫 컬렉션 카드 또는 스타터 미션 보상을 경험한다.
- 자동 scene smoke는 Level 1-5 순차 클리어 후 Stage 6 해금, Rescue Book 신규 카드 `frog`/`koala`/`hamster`의 `NEW`, `animal_unlock` analytics를 검증한다.
- 한국어/영어/일본어 pseudo-localization에서 목표 칩과 버튼 텍스트가 겹치지 않는다.
- 자동 scene smoke는 Stage Popup, Gameplay HUD, 실패 overlay에 장문 pseudo-localization title/body/CTA를 주입해 viewport, panel bounds, CTA vertical overlap을 검증한다.
- 자동 scene smoke는 6개 요청 window size의 mobile viewport matrix에서 홈, 월드맵, 컬렉션, Stage 4 Gameplay HUD, Stage Popup, Stage 25 실패 overlay의 실제 logical viewport bounds를 검증한다.
- 자동 scene smoke는 핵심 CTA 최소 터치 타깃과 버튼 대비를 검증해 상용 UI readability 회귀를 차단한다.

## Gate 7A. Stage Popup / 시작 부스터

- 스테이지 노드를 누르면 gameplay로 바로 전환되지 않고 Stage Popup이 먼저 열린다.
- Stage Popup은 목표, 이동 수, 난이도/테마, 보상, 시작 부스터 3종, `PLAY` 버튼을 보여 준다.
- Rescue Buddy가 있는 스테이지는 Stage Popup에 Buddy 동물명, 스킬명, 충전 조건, 짧은 효과 설명을 보여 주고, Buddy가 없는 스테이지는 빈 Buddy 영역을 보여 주지 않는다.
- 시작 부스터 3종은 아이콘과 선택 상태를 가지며, 선택 결과가 `GameSession.selected_pre_boosters`에 저장된다.
- Stage Popup 닫기와 PLAY 선택값 저장은 scene smoke에서 gameplay 전환 전 상태로 검증된다.
- Stage 4 Stage Popup의 장문 목표/보상/Buddy/PLAY 문구는 자동 scene smoke에서 panel 밖으로 넘치거나 PLAY CTA와 겹치지 않는다.
- Stage 4 Stage Popup은 mobile viewport matrix에서 PLAY, close, booster 3종, Buddy preview가 viewport와 panel 안에 남아야 한다.
- Gameplay 시작 시 선택 부스터는 한 번만 소비되고 보드에는 `rainbow`, `row/col`, `bomb` 특수 블록이 각각 배치된다.
- `stage_start`는 `selected_boosters`와 `start_boosters_applied`를 기록하고, 각 시작 부스터는 `booster_used`의 `source = pre_stage`로 기록된다.
- Stage Popup 열기/닫기 애니메이션과 모바일 터치감은 실제 기기 또는 시뮬레이터에서 최종 확인한다.

## Gate 8. Rescue Book/메타 루프

- Rescue Book에 MVP 12종 동물이 모두 표시되고 잠김/해금 상태가 구분된다.
- 글로벌 런칭 컬렉션 확장 시 18종까지 스크롤/탭/그리드가 깨지지 않는다.
- 토큰, 우정 레벨, 장착 상태가 앱 재시작 후 유지된다.
- 스테이지 보상과 컬렉션 토큰 지급이 중복 지급되지 않는다.
- 자동 scene smoke가 Rescue Book 카드의 잠김/해금, `NEW`, 토큰 수, 우정 레벨 라벨 회귀를 잡는다.
- 자동 scene smoke가 `rabbit`/`frog`/`koala` Lv.1-5 cosmetic reward data, token 기반 `earned_rewards`, 카드 보상 획득 수, 상세 `획득`/`대기` reward track, `animal_token_gain`, `animal_friendship_level_up` analytics를 검증한다.
- 자동 scene smoke가 획득한 `rabbit_sprout_frame` cosmetic 장착, `equipped_cosmetic` 저장, `animal_cosmetic_equip` payload, 중복/미획득 장착 차단, 상세 `장착중` 버튼 상태, Rescue Book 카드 `장착 프레임` 배지와 equipped metadata를 검증한다.
- 자동 scene smoke가 Stage 1 실제 clear 경로의 첫 목표 동물 `+3 tokens`, `source=stage_clear`, 결과 overlay 도감 토큰 문구, 같은 stage clear 중복 지급 방지를 검증한다.
- 자동 scene smoke가 Rescue Book 카드 입력 후 상세 갱신, `NEW` 제거, 토큰/우정 레벨 보존을 검증한다.
- 자동 scene smoke가 Rescue Book 미리보기 Tween을 최대 4개로 제한하고, 비활성/숨김 상태에서 정지하는지 검증한다.
- 홈, 결과 화면, 이벤트에서 컬렉션 진입과 복귀가 가능하다.

## Gate 8A. Rescue Buddy 분석

- Buddy 충전, 준비, 발동, 차단은 `buddy_skill_charge`, `buddy_skill_ready`, `buddy_skill_trigger`, `buddy_skill_blocked`로 실제 런타임에서 기록된다.
- Stage 4 `quick_refill`은 목표 동물 매치 이벤트 단위로 충전되고, 3칸 매치 하나만으로 ready가 되지 않는다.
- Stage 4 `quick_refill`은 목표 동물 매치 충전 후 1회 발동하고, max use 이후 차단 이벤트를 남긴다.
- Stage 4 Rescue Buddy HUD는 Buddy 없는 스테이지에서 숨고, 0/3, 2/3, 출동, 완료 상태를 자동 scene smoke에서 검증한다.
- Stage 5 `soft_bomb_plus`, Stage 8 `combo_peep`, Stage 16 `smart_hint`, Stage 18 `leap_clear`, Stage 24 `calm_fever`, Stage 25 `coin_sniff`, Stage 31 `cascade_slide`, Stage 41 `sly_route`, Stage 51 `brave_start`, Stage 81 `mighty_push`는 scene smoke에서 실제 상태 변화와 `buddy_skill_trigger`를 검증한다.
- Stage 18 `leap_clear`와 Stage 81 `mighty_push`는 마지막 덤불 목표를 Buddy 단독으로 완료하려 할 때 발동하지 않고 `effect_unavailable` 차단 이벤트를 남긴다.
- Stage 20 `loyal_fetch`는 실패 직전 구조 이동을 줄 때 `buddy_skill_trigger`를 남기며, `_check_stage_state()` 실패 판정 경로에서 실패 overlay와 `stage_fail`/`fail_offer_show`를 먼저 띄우지 않는다.
- Stage 4/5/8/16/18/20/24/25/31/41/51/81 첫 등장 Buddy 스테이지는 `recommended_smoke`로 수동 QA 진입점을 유지한다.
- 실제 기기 최종 QA는 Stage 4, Stage 8, Stage 18 또는 81에서 Buddy preview/HUD/ready/blocked/complete 판독성과 표정/VFX 겹침 여부를 기록한다.

## Gate 9. 실패/광고/IAP 공정성

- 강제 실패 케이스에서 Near Miss와 Strategic Miss가 다르게 분기된다.
- Near Miss 기준은 `near_miss_goal_threshold`와 `near_miss_progress_threshold` remote config 기본값으로 튜닝 가능하고 scene smoke에서 분기 검증을 통과한다.
- Stage 1 FTUE 실패 overlay는 무료 재도전 CTA와 수익화 문구 차단을 runtime smoke에서 검증한다.
- 실패 팝업에서 재도전, 지도, 닫기 같은 비구매 선택지가 항상 보인다.
- Near Miss 실패 팝업의 `+3 이동 받고 계속` CTA는 실제로 overlay를 닫고 이동 3회를 지급해 플레이 상태로 복귀한다.
- 실패 overlay는 수집 동물 미달, 점수 미달, 덤불 미달의 `놓친 핵심` 목표와 `다음 한 수` 재도전 힌트를 분리해 보여 준다.
- Near Miss secondary 재도전은 같은 스테이지를 새 이동 수와 초기 점수/장애물 상태로 복구한다.
- 결과/실패 overlay runtime smoke는 Stage 1 클리어 보상/CTA, Stage 1 FTUE 실패 CTA, Stage 25 near-miss 실패 offer 노출, 선택/닫기, 광고/IAP 성공·취소·실패·복구 결과, 코인 continue, 추가 이동 지급 analytics를 검증한다.
- 광고 완료 후 추가 이동은 1회만 지급되고 `ad_reward_complete`와 `extra_moves_grant`는 같은 transaction을 공유한다.
- IAP 성공 후 추가 이동은 `iap_purchase_complete`와 `extra_moves_grant`가 같은 transaction을 공유한다.
- 같은 `transaction_id`의 보상형 광고/IAP continue 콜백은 스테이지 재시작 이후에도 추가 이동과 완료 analytics를 중복 지급하지 않는다.
- 광고 로드 실패/중단 시 wallet, 이동 수, 점수, 목표 진행이 잘못 소모되지 않는다.
- 코인 continue는 충분한 gold가 있을 때만 차감하고, gold 부족 시 상태를 보존한다.
- 구매 취소/실패/복구가 게임 상태를 꼬이게 하지 않는다. SDK 실연동 전 no-device smoke는 `iap_purchase_cancel`/`iap_purchase_fail`/`iap_purchase_restore` 상태 보존을 검증한다.
- SDK 실연동 전 `MonetizationGateway`는 rewarded/IAP/coin continue 요청을 request log로 남기고, 지원하지 않는 source를 adapter 호출 전 `rejected_invalid_source`로 거절한다.
- SDK adapter hook은 queued validation 결과를 우선하고, supported source의 unqueued 요청만 provider Callable에 deep-copy payload로 전달한다.
- SDK adapter result는 `completed`, `failed`, `pending` 셋으로만 gameplay에 전달되며, `success`, `cancelled`, `in_progress`, 알 수 없는 provider result alias는 scene smoke에서 canonical result로 검증한다. IAP cancel/restore처럼 분석 분기에 필요한 원문은 `details.provider_result`로 보존되어야 한다.
- SDK 실연동 전 `pending` continue 결과는 실패/완료/추가 이동 analytics를 내지 않고 overlay를 유지하며, pending 중 primary CTA 재탭은 두 번째 provider 요청을 만들지 않는다.
- 같은 레벨 3회 실패 시 같은 IAP 팝업을 반복 강제하지 않는다.

## Gate 10. 라이브 운영/분석

- 원격 설정 누락 시 기본값으로 안전하게 동작한다.
- `zsh scripts/validate_liveops_config.sh`가 `remote_config.json`과 `live_events.json`의 unlock key, range, placement, offline fallback, disabled `season_pass`, exposure payload 계약을 독립 검증한다.
- 이벤트 미시작/진행 중/종료/오프라인 상태가 홈/스테이지 선택 칩, 홈 상세, 결과 오버레이, 컬렉션 상세에서 사용자-facing 문구로 표시된다.
- 원격 설정 적용은 세션별 `remote_config_exposure`로 기록되고, `variant_id`, `config_key`, `config_value_hash`가 비어 있지 않다.
- 이벤트 보상 수령은 idempotent하게 처리되어 중복 수령되지 않는다.
- 홈 이벤트 상세 overlay에서 이벤트 참여와 보상 수령 상태가 저장되고, 미션형 이벤트 보상은 wallet 지급값으로 집계된다.
- 혼합 이벤트 보상은 `reward_type=mixed`와 `reward_breakdown`으로 골드/토큰/부스터 구성 요소가 누락 없이 기록된다.
- 필수 분석 이벤트와 파라미터가 디버그 로그에 누락 없이 기록된다.
- 자동 scene smoke가 런타임에서 실제 기록된 분석 이벤트의 필수 파라미터 누락, `remote_config_exposure` 전체 key 노출, 이벤트 기간/오프라인 상태, 사용자-facing 상태 문구, `event_join`, `event_progress`, `event_reward_claim` idempotency 회귀를 잡는다.
- SDK 공급자 결정 전 `AnalyticsGateway`는 `configure_flush_adapter(provider_id, Callable)`로 실제 provider 경계를 고정하고, adapter partial failure 시 성공 prefix만 제거하며 callback payload 변조가 pending queue를 오염시키지 않는지 scene smoke가 검증한다.
- `data/provider_readiness.json`은 analytics/monetization provider-neutral 상태를 기록하고, `zsh scripts/validate_provider_readiness.sh`가 코드 상수, adapter hook, source/result canonicalization, queue/request log 상한과 일치하는지 검증한다. `OPEN-007` 확정 전에는 Firebase/GameAnalytics/AdMob/Google Play Billing/Unity Ads/AppLovin/ironSource/RevenueCat 같은 실제 SDK명이 provider field에 섞이면 실패해야 한다.
- 라이브 이벤트 노출은 `home`, `stage_select`, `result_overlay`, `collection` placement별 `live_event_impression` 기록 경로를 가진다.
- `season_pass` 해금 레벨은 `season_pass_unlock_level`로 제어하지만, store product/SDK evidence 전까지 alpha fixture는 disabled 상태이며 active/display 이벤트로 노출되면 안 된다.
- A/B 테스트 노출은 현재 로드된 remote config key마다 `remote_config_exposure` 이벤트로 1회 이상 기록된다.
- 원격 설정 변경 후 이전 기본값으로 롤백 가능하다.

## Gate 11. 동물 로스터/애니메이션 에셋

- MVP 보드 12종은 64px 미리보기에서 이름 없이 구분된다.
- 13-18번 컬렉션 전용 동물은 `board_enabled` 전까지 stage JSON의 `spawn_profile.pool`에 들어가지 않는다.
- 모든 MVP 보드 동물은 `idle`, `blink`, `smile`, `match`, `fever`, `worried` 상태를 표시하거나 fallback으로 대체된다.
- `match` 표현은 제거 직전 우선순위가 가장 높고, `blink`나 `worried`가 이를 덮지 않는다.
- `fever` 표현 중에도 목표 UI, 특수 배지, 이동 수 HUD가 읽힌다.
- atlas/overlay 에셋 누락 시 게임이 멈추지 않고 기본 블록 텍스처로 fallback한다.
- 컬렉션 표정 미리보기는 화면 밖 카드 또는 비활성/숨김 상태에서 재생되지 않는다.

## Gate 12. Android Export Identity

- `export_presets.cfg`의 Android preset은 `Zoo-Zoo Pop` 앱명과 `com.shinehandmac.zoozoopop` package id를 사용한다.
- debug export path는 `build/android/zoo-zoo-pop-debug.apk`, release export evidence path는 `build/android/zoo-zoo-pop-release.apk`를 기준으로 한다.
- `version/code`는 양의 정수, `version/name`은 SemVer 형태여야 한다.
- Android preset은 signed package, vibrate permission, arm64 ABI를 유지해야 한다.
- `zsh scripts/validate_android_export_config.sh`와 `zsh scripts/validate_gameplay.sh`가 starter placeholder 회귀를 차단한다.
- 이 gate는 release keystore, APK export, 설치, 실행을 증명하지 않으며 해당 항목은 Android evidence script와 alpha QA report validator로 승인한다.

## Gate 13. Android QA Helper Contract

- `zsh scripts/validate_android_qa_helpers_contract.sh`는 debug export, release export, device capture, manual device checks helper의 dry-run PASS 계약을 검증한다.
- unknown option, 빈 output/package/preset 경로, `--video-seconds` 범위 위반, manual tester/result 누락, release signing env 누락은 실패해야 한다.
- release password sentinel 값은 stdout/stderr에 노출되면 안 되며, dry-run은 APK/evidence/capture 파일을 만들면 안 된다.
- 이 gate는 helper CLI 안전성만 보는 no-device smoke이며 release keystore, APK export, install/launch, screenshot/video/logcat, human PASS note를 대체하지 않는다.

## 승인 보고 형식

```text
QA 결과: 승인 또는 반려
대상 작업 카드:
확인 환경:
검증 명령:
주요 확인:
No-device readiness:
Device-blocked items:
Evidence logs:
Manual QA matrix:
반려 이슈:
재확인 필요:
```
