# Project Animal Match Analytics & Remote Config Spec

작성일: 2026-05-02
목적: FTUE, 레벨, 컬렉션, 실패 제안, 광고/IAP, 이벤트 운영을 분석 가능한 형태로 구현하기 위한 이벤트/원격 설정 계약을 정의한다.

## 1. 공통 이벤트 파라미터

모든 이벤트는 아래 공통 파라미터를 가진다.

| 파라미터 | 설명 |
| --- | --- |
| `app_version` | 앱 버전 |
| `build_number` | 빌드 번호 |
| `platform` | `android` 또는 `ios` |
| `device_os` | OS 버전 |
| `locale` | 언어/지역 |
| `country` | 국가 |
| `session_id` | 세션 id |
| `install_id` | 유저 식별자 또는 설치 id |
| `remote_config_version` | 적용된 원격 설정 버전 |
| `client_time_ms` | 클라이언트 이벤트 발생 시각 |

## 2. 이벤트 계약

### 2.1 FTUE

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `ftue_step_view` | 안내 노출 | `step_id`, `stage_id`, `trigger`, `variant_id`, `attempt_count` |
| `ftue_step_complete` | 안내 목표 완료 | `step_id`, `stage_id`, `elapsed_ms`, `input_count`, `hint_count` |
| `ftue_step_skip` | 안내 생략/닫기 | `step_id`, `reason`, `stage_id`, `elapsed_ms` |
| `first_match_complete` | 첫 유효 매치 | `stage_id`, `moves_used`, `animal_id`, `match_size` |
| `first_special_create` | 첫 특수 블록 생성 | `stage_id`, `special_type`, `moves_used` |
| `first_fever_start` | 첫 피버 시작 | `stage_id`, `moves_used`, `gauge_source` |

### 2.2 Level

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `level_start` | 스테이지 시작 | `stage_id`, `attempt_count`, `heart_count`, `booster_selected`, `roster_group` |
| `level_complete` | 클리어 | `stage_id`, `moves_left`, `score`, `stars`, `cascades`, `specials_used`, `fever_count` |
| `level_fail` | 실패 | `stage_id`, `moves_used`, `goals_remaining`, `fail_type`, `progress_ratio` |
| `level_quit` | 중도 이탈 | `stage_id`, `moves_left`, `goals_remaining`, `attempt_count` |
| `retry_start` | 재도전 | `stage_id`, `attempt_count`, `source`, `heart_spent` |
| `special_combo_trigger` | 특수+특수 조합 발동 | `stage_id`, `combo_type`, `from_special`, `to_special`, `cleared_count`, `obstacles_cleared` |

현재 Godot 런타임 계약은 `level_start`의 구현 이벤트명으로 `stage_start`를 사용한다. `stage_start`는 `session_id`, `stage_id`, `band`, `roster_group`, `moves`를 필수로 기록하고, `selected_boosters`, `start_boosters_applied`, `difficulty`를 선택 파라미터로 기록한다. 시작 부스터 사용은 `booster_used`에 `source = pre_stage`로 별도 기록한다.
특수+특수 조합은 `special_combo_trigger`로 Stage 31 smoke의 6종 타입(`row_col`, `row_row`, `col_col`, `row_bomb`, `col_bomb`, `bomb_bomb`)과 제거/장애물 수치를 기록한다.

### 2.3 Collection

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `collection_view` | Rescue Book 진입 | `entry_point`, `unlocked_count`, `new_badge_count` |
| `animal_unlock` | 동물 카드 해금 | `animal_id`, `source`, `stage_id`, `token_balance` |
| `animal_token_gain` | 토큰 지급 | `animal_id`, `amount`, `source`, `stage_id`, `event_id` |
| `animal_friendship_level_up` | 우정 레벨 상승 | `animal_id`, `level_before`, `level_after`, `reward_id` |
| `animal_cosmetic_equip` | 장착 변경 | `animal_id`, `cosmetic_id`, `cosmetic_type`, `entry_point` |

현재 Godot 런타임은 stage clear로 Rescue Book 카드가 신규 해금될 때 `animal_unlock`을 기록한다. `source=stage_clear`, 방금 클리어한 `stage_id`, 해금 직후 `token_balance`를 필수로 남기고, 선택 파라미터 `unlock_stage`에 동물 데이터의 해금 스테이지를 함께 남긴다. 토큰 지급은 `animal_token_gain`으로 기록하고, 토큰 누적으로 friendship level이 올라가 cosmetic reward가 자동 획득되면 `animal_friendship_level_up`을 기록한다. MVP 보상은 `rabbit`, `frog`, `koala` 3종의 Lv.1-5 cosmetic track으로 시작하며, 장착 UI와 `animal_cosmetic_equip` 실사용은 후속 작업으로 둔다.

### 2.4 Fail Offer / Ads / IAP

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `fail_offer_show` | 실패 제안 노출 | `stage_id`, `fail_type`, `attempt_count`, `goals_remaining`, `progress_ratio`, `offer_type` |
| `fail_offer_select` | 제안 선택 | `stage_id`, `fail_type`, `offer_type`, `cost_type`, `cost_amount` |
| `fail_offer_dismiss` | 제안 닫기 | `stage_id`, `fail_type`, `dismiss_action`, `elapsed_ms` |
| `ad_offer_show` | 광고 제안 | `placement`, `stage_id`, `offer_type` |
| `ad_reward_complete` | 광고 보상 완료 | `placement`, `stage_id`, `reward_type`, `reward_amount`, `transaction_id` |
| `ad_reward_fail` | 광고 실패 | `placement`, `stage_id`, `reward_type`, `ad_network`, `error_code` |
| `iap_purchase_start` | 구매 시작 | `product_id`, `price`, `currency`, `placement` |
| `iap_purchase_complete` | 구매 완료 | `product_id`, `price`, `currency`, `transaction_id` |
| `iap_purchase_restore` | 구매 복구 결과 | `product_id`, `placement`, `restore_result`, `restored_transaction_id` |
| `iap_purchase_fail` | 구매 실패 | `product_id`, `placement`, `error_code`, `price`, `currency` |
| `iap_purchase_cancel` | 구매 취소 | `product_id`, `placement`, `price`, `currency` |

### 2.5 Live Ops

| 이벤트 | 트리거 | 필수 파라미터 |
| --- | --- | --- |
| `remote_config_exposure` | 설정 적용 | `session_id`, `config_key`, `variant_id`, `config_value_hash` |
| `live_event_impression` | 이벤트 노출 | `session_id`, `event_id`, `event_type`, `placement` |
| `event_join` | 이벤트 참여 | `session_id`, `event_id`, `event_type`, `placement` |
| `event_progress` | 이벤트 진행 | `session_id`, `event_id`, `event_type`, `placement`, `progress_key`, `progress_value` |
| `event_reward_claim` | 보상 수령 | `session_id`, `event_id`, `event_type`, `placement`, `reward_id`, `reward_type`, `reward_amount` |
| `starter_mission_complete` | 스타터 미션 완료 | `mission_id`, `day_index`, `reward_id`, `elapsed_since_install_hours` |

혼합 보상은 `reward_type=mixed`로 기록하고, 선택 파라미터 `reward_breakdown`에 `gold`, `tokens`, `boosters` 구성 요소를 함께 남긴다.
원격 설정 노출은 세션별 `variant_id + config_key` 기준으로 중복 기록을 막고, 선택 파라미터 `remote_config_version`, `source`를 함께 남길 수 있다.
SDK 공급자 결정 전 분석 이벤트는 `AnalyticsGateway`의 `local_buffer` provider로 queued dispatch 상태를 남긴다. 이 local buffer는 `user://` JSON 큐로 보존되어 다음 세션 reload 후에도 순서를 유지하며, adapter가 `flush_queued_events`로 성공 전송한 항목은 pending queue에서 제거한다. 실제 Firebase/GameAnalytics/custom SDK는 `configure_flush_adapter(provider_id, Callable)` 뒤에 연결하며, adapter callback이 받은 event payload를 변조해도 pending queue 원본은 오염되지 않아야 한다. 큐는 최대 320개로 제한하고 깨진 JSON 파일은 stale replay 없이 무시한다. 필수 파라미터가 빠졌거나 계약에 없는 이벤트는 로컬 디버그 저장에는 남기되 provider queue에는 싣지 않고 `rejected_contract`로 격리한다.
`data/provider_readiness.json`은 실제 SDK 공급자 선택 전 상태를 machine-readable manifest로 고정한다. `scripts/validate_provider_readiness.sh`는 analytics `local_buffer`, monetization `local_simulator`, adapter hook, source/result canonicalization, provider result 원문 보존, queue/request log 상한이 코드와 일치하는지 검증하고, `OPEN-007` 확정 전 Firebase/GameAnalytics/AdMob/Google Play Billing/Unity Ads/AppLovin/ironSource/RevenueCat 같은 production SDK명이 manifest에 섞이지 않도록 차단한다.

## 3. 원격 설정 키

| 키 | 기본값 | 범위 | 사용처 |
| --- | --- | --- | --- |
| `remote_config_version` | `2026.05.liveops.v1` | string | 원격 설정 버전 |
| `variant_id` | `baseline` | string | 노출 variant |
| `heart_spend_start_level` | `11` | 1-999 | 하트 소모 시작 |
| `rewarded_ad_start_level` | `11` | 1-999 | 보상형 광고 제안 시작 |
| `iap_offer_start_level` | `16` | 1-999 | 직접 IAP 제안 시작 |
| `rewarded_continue_moves` | `3` | 1-10 | 광고 계속하기 이동 수 |
| `coin_continue_moves` | `5` | 1-10 | 코인 계속하기 이동 수 |
| `near_miss_goal_threshold` | `2` | 1-5 | Near Miss 남은 목표 |
| `near_miss_progress_threshold` | `0.8` | 0.5-0.98 | Near Miss 진행률 |
| `daily_reward_unlock_level` | `2` | 1-30 | 일일 보급 해금 |
| `starter_missions_unlock_level` | `3` | 1-30 | 스타터 미션 해금 |
| `collection_event_unlock_level` | `9` | 1-50 | 수집 이벤트 해금 |
| `season_pass_unlock_level` | `21` | 1-80 | 시즌 패스 해금 |
| `interstitial_min_level` | `16` | 1-999 | 전면 광고 최소 레벨 |

`scripts/validate_liveops_config.sh`는 `data/events/remote_config.json`의 필수 key, unlock key와 `LiveEventService.REMOTE_CONFIG_EXPOSURE_KEYS` 일치, range, disabled `season_pass` alpha fixture를 자동 검증한다.

## 4. 데이터 품질 규칙

- `transaction_id`가 있는 보상은 idempotent하게 처리한다.
- 오프라인 이벤트는 로컬 큐에 저장하고 다음 세션에서 순서대로 전송한다.
- `level_start`, `level_complete`, `level_fail`, `retry_start`의 `attempt_count`는 같은 stage 안에서 일관되어야 한다.
- `ad_reward_complete`와 `extra_moves_grant`가 분리될 경우 같은 `transaction_id`를 공유한다.
- IAP 성공형 continue는 `iap_purchase_complete`와 `extra_moves_grant`가 같은 `transaction_id`를 공유한다.
- IAP restore 결과는 현재 실패 이어하기 보상을 지급하지 않고 `iap_purchase_restore`만 기록한다.
- 같은 `transaction_id`가 반복 수신되면 보상형 광고/IAP continue의 추가 이동과 완료 analytics를 다시 지급하지 않는다.
- SDK 공급자 결정 전에는 `MonetizationGateway`가 rewarded/IAP/coin continue 결과를 provider-neutral callback 형태로 gameplay에 전달하고 request log에 source, stage, provider, result, request status를 남긴다. 실제 SDK는 `configure_continue_adapter(provider_id, Callable)` 뒤에 연결하며, adapter request payload는 source/stage/fail offer/details를 deep copy로 전달한다. adapter result는 `completed`, `failed`, `pending`으로만 정규화하고, `success/succeeded`는 `completed`, `cancelled/canceled/timeout/error`와 알 수 없는 문자열은 `failed`, `started/in_progress`는 `pending`으로 처리한다. canonical 결과와 다른 provider 원문은 `details.provider_result`로 보존해 IAP cancel/restore 분석 분기를 유지한다. `pending`은 SDK 요청 시작 상태로 취급해 실패/완료/추가 이동 analytics를 발생시키지 않고, 결과 콜백 전 중복 CTA 요청을 막는다. gameplay는 허용된 source와 `transaction_id` idempotency만 신뢰하며, gateway는 지원하지 않는 source를 adapter 호출 전 `rejected_invalid_source`로 거절한다.
- stage clear로 같은 Rescue Book 카드가 이미 해금된 상태라면 `animal_unlock`을 중복 기록하지 않는다.
- A/B 테스트 이벤트는 반드시 `variant_id`와 `remote_config_version`을 포함한다.

## 5. 롤백 기준

| 지표 | 롤백 기준 |
| --- | --- |
| D1 retention | 기존 대비 3%p 이상 하락 |
| Level 1-10 quit rate | 기존 대비 5%p 이상 상승 |
| stage fail rate | 해당 밴드 목표치보다 10%p 이상 상승 |
| rewarded ad opt-in | 노출 증가에도 수락률 5%p 이상 하락 |
| crash-free sessions | 99% 미만 |

## 6. 구현 완료 기준

- 필수 이벤트명과 파라미터를 `data/analytics_events.json` 또는 동등한 계약 파일에서 검증할 수 있다.
- `GameSession`에 저장된 계약 통과 런타임 이벤트는 provider-neutral `AnalyticsGateway`로도 전달되며, SDK 선택 전에는 `local_buffer` queued dispatch, disk reload 보존, 순차 flush 후 pending queue 제거, registered flush adapter partial failure, adapter payload mutation guard, corrupt queue tolerance, bounded queue eviction으로 검증된다.
- 계약 위반 이벤트는 SDK provider queue로 전달되지 않고 `rejected_contract` 상태와 거절 사유를 남긴다.
- 원격 설정 누락 시 기본값으로 안전하게 동작한다.
- 디버그 빌드에서 이벤트 로그를 사람이 읽을 수 있다.
- 보상형 광고와 IAP 실패/취소 케이스가 재화나 하트를 잘못 소모하지 않는다.
- SDK 공급자 선택 전 provider readiness manifest가 코드 상수와 일치하고, 실제 provider 연결은 manifest에 적힌 adapter hook 뒤에서만 이루어진다.
