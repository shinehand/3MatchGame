# Alpha Lock Pass Manual QA Template

## Run Metadata

- QA date:
- Build source commit:
- Build artifact path:
- Device:
- OS version:
- Orientation checked: portrait / landscape / both
- Tester:
- Overall result: Pass / Fail / Blocked

## Required Preflight

| Gate | Command or Evidence | Result | Notes |
| --- | --- | --- | --- |
| Gameplay validation | `zsh scripts/validate_gameplay.sh` | Pending |  |
| Android debug environment | `zsh scripts/check_android_setup.sh` | Pending |  |
| Release preflight | `GODOT_RELEASE_KEYSTORE_PATH=/path/to/release.keystore zsh scripts/check_android_setup.sh --release` | Pending | Required for release candidates |
| Install/run evidence | APK path + install result | Pending | Device required |

## Device Evidence Pack

| Evidence | Result | Evidence path | Notes |
| --- | --- | --- | --- |
| Build source commit | Pending |  | Must match Run Metadata |
| APK/AAB path | Pending |  | Include debug/release label |
| Install result | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/install-log.txt` | Device required |
| Device model and OS version | Pending |  | Include screen size if known |
| Portrait screenshot | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/device-portrait.png` | Safe area/notch/home indicator visible |
| Landscape screenshot | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/device-landscape.png` | Safe area/notch/home indicator visible |
| 10s video path | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/device-10s.mp4` | First-look readability |
| sound ON/OFF | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/sound-toggle.*` | Android real-device playback |
| haptics ON/OFF | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/haptics-toggle.*` | Android real-device feedback |
| touch latency notes | Pending |  | Drag, tap, popup close/start |
| logcat or app log path | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/device-log.txt` | Attach any crash/runtime warnings |

## Representative Course Results

| Course | Result | Capture path | 10s understanding | HUD/board readability | Overlay/action clarity | Save/unlock/star persistence | Sound | Haptics | Orientation | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Home | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/home.png` | N/A | Pending | Pending | N/A | Pending | Pending | Pending |  |
| Stage 1 | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/stage-001.png` | Pending | Pending | Pending | Pending | Pending | Pending | Pending |  |
| Stage 11 | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/stage-011.png` | Pending | Pending | Pending | Pending | Pending | Pending | Pending |  |
| Stage 25 | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/stage-025.png` | Pending | Pending | Pending | Pending | Pending | Pending | Pending |  |
| Stage 50 | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/stage-050.png` | Pending | Pending | Pending | Pending | Pending | Pending | Pending |  |
| Stage 75 | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/stage-075.png` | Pending | Pending | Pending | Pending | Pending | Pending | Pending |  |
| Stage 100 | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/stage-100.png` | Pending | Pending | Pending | Pending | Pending | Pending | Pending |  |

## Focused Device Gate Matrix

| Scenario ID | Gate | Required scenario | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- | --- |
| PAM_QA_040_EXPRESSIONS | PAM-QA-040 expressions | Stage 1 select smile, match expression, low-move worried, portrait/landscape face crop check | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/pam-qa-040-expressions.*` |  |
| PAM_QA_041_STAGE_POPUP | PAM-QA-041 popup/pre-booster | Stage Popup open/close, START, pre-booster board placement, touch feel | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/pam-qa-041-popup.*` |  |
| STAGE_POPUP_BUDDY | PAM-QA-041 Buddy preview | Stage Popup Buddy target == HUD Buddy target on Buddy stages | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/stage-popup-buddy.*` |  |
| RESCUE_BOOK_UNLOCK | Rescue Book unlock | Stage 1-5 clear keeps frog/koala/hamster unlock, NEW, token state | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/rescue-book-unlock.*` |  |
| SPECIAL_COMBO_6 | PAM-DEV-051 Stage 31 special combos | Six special+special combo VFX/SFX/haptics/readability evidence | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/stage-031-special-combos.*` |  |
| RESCUE_BUDDY_SMOKE | Rescue Buddy readability | Stage 4, Stage 8, Stage 18 or 81 Buddy HUD/ready/blocked/complete readability | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-readability.*` |  |
| NEAR_MISS_CONTINUE | Near Miss continue | Stage 25 near miss fail overlay, retry, +3 moves continue state | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/near-miss-continue.*` |  |
| MONETIZATION_GATEWAY_PENDING | PAM-DEV-054 monetization gateway | Rewarded/IAP pending, duplicate tap block, invalid source rejection, request log metadata | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/monetization-gateway.*` |  |
| ANALYTICS_GATEWAY_LOCAL_BUFFER | PAM-ANA-090 analytics local queue | Runtime analytics saved, local_buffer reload/flush behavior, rejected_contract isolation | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/analytics-local-buffer.*` |  |

## Stage 31 Special Combo Evidence

| Combo | combo_type | Result | Portrait evidence | Landscape evidence | cleared_count | obstacles_cleared | special_combo_trigger | VFX label distinct | SFX/haptic distinct | input recovers <2s | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| row+column | row_column | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-row-column-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-row-column-landscape.*` | Pending | Pending | Pending | Pending | Pending | Pending |  |
| row+row | row_row | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-row-row-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-row-row-landscape.*` | Pending | Pending | Pending | Pending | Pending | Pending |  |
| column+column | column_column | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-column-column-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-column-column-landscape.*` | Pending | Pending | Pending | Pending | Pending | Pending |  |
| row+bomb | row_bomb | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-row-bomb-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-row-bomb-landscape.*` | Pending | Pending | Pending | Pending | Pending | Pending |  |
| column+bomb | column_bomb | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-column-bomb-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-column-bomb-landscape.*` | Pending | Pending | Pending | Pending | Pending | Pending |  |
| bomb+bomb | bomb_bomb | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-bomb-bomb-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/combo-bomb-bomb-landscape.*` | Pending | Pending | Pending | Pending | Pending | Pending |  |

## Rescue Buddy Stage Matrix

| Stage | Buddy focus | Result | Portrait evidence | Landscape evidence | HUD readable | VFX overlap acceptable | Analytics events | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Stage 4 | quick_refill 0/3 -> 2/3 -> ready -> complete | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-stage-004-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-stage-004-landscape.*` | Pending | Pending | buddy_skill_charge, buddy_skill_ready, buddy_skill_trigger |  |
| Stage 8 | combo_peep normal and Fever blocked/effect_unavailable state | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-stage-008-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-stage-008-landscape.*` | Pending | Pending | buddy_skill_charge, buddy_skill_blocked |  |
| Stage 18 | leap_clear blocker assist and last-goal solo clear blocked | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-stage-018-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-stage-018-landscape.*` | Pending | Pending | buddy_skill_trigger, buddy_skill_blocked |  |
| Stage 81 | mighty_push repeated use and last-goal solo clear blocked | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-stage-081-portrait.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-stage-081-landscape.*` | Pending | Pending | buddy_skill_trigger, buddy_skill_blocked |  |
| Stages 4/5/8/16/18/20/24/25/31/41/51/81 | first-appearance Buddy smoke coverage | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-first-appearance.*` | `output/alpha-lock-pass/YYYY-MM-DD/captures/buddy-first-appearance-landscape.*` | Pending | Pending | buddy_skill_charge, buddy_skill_ready, buddy_skill_trigger, buddy_skill_blocked |  |

## Monetization And Analytics Evidence

### Failure Continue Gateway

| Scenario | Expected | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| rewarded_ad pending keeps overlay | Overlay remains, no grant/fail/complete analytics, duplicate tap blocked | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/rewarded-pending.*` |  |
| IAP pending | `iap_purchase_start` once, no final purchase/grant until completed callback | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/iap-pending.*` |  |
| pending duplicate tap does not create second request | Same pending source keeps one provider request and one select intent | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/pending-duplicate-tap.*` |  |
| invalid source rejected_invalid_source | Request rejected as `rejected_invalid_source`, no state or wallet mutation | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/invalid-source.*` |  |
| request log source/stage_id/fail_reason/provider_id/status/result | MonetizationGateway request log has source, stage_id, fail_reason, provider_id, status, result | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/request-log.*` |  |
| completed grants once | Rewarded/IAP completed callback grants extra moves exactly once | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/completed-grants-once.*` |  |
| failed/canceled preserves moves/wallet/objectives | Failed, canceled, and restore failure do not mutate moves, wallet, or objective progress | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/failed-canceled-preserve-state.*` |  |
| duplicate transaction_id grants once | Repeated rewarded/IAP transaction callback does not grant or log completion twice | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/duplicate-transaction.*` |  |

### Analytics Gateway Local Buffer

| Scenario | Expected | Result | Evidence path | Notes |
| --- | --- | --- | --- | --- |
| GameSession saved event | Runtime event is kept in GameSession history | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/analytics-gamesession.*` |  |
| AnalyticsGateway local_buffer queued | Contract-valid event enters local_buffer pending queue | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/analytics-buffer-queued.*` |  |
| disk reload preserves queue | App/session reload restores queued events from disk | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/analytics-buffer-reload.*` |  |
| flush drains in order exactly once | Successful flush removes sent events in order and does not duplicate dispatch | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/analytics-flush-order.*` |  |
| pending queue removed after flush | Queue is empty after all accepted events flush | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/analytics-flush-empty.*` |  |
| contract violation rejected_contract not queued | Invalid analytics is isolated in rejected_contract and not sent to provider queue | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/analytics-rejected-contract.*` |  |
| provider-neutral/no SDK selected | Evidence notes that no production analytics SDK is selected yet | Pending | `output/alpha-lock-pass/YYYY-MM-DD/captures/analytics-provider-neutral.*` |  |

## Alpha Blocker Log

| ID | Severity | Area | Repro steps | Expected | Actual | Evidence | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ALPHA-001 | Blocker/Major/Minor |  |  |  |  |  |  | Open |

## Device-Blocked Items

- Android real-device sound playback:
- Android real-device haptics and ON/OFF setting:
- Touch latency and gesture feel:
- Physical portrait viewport HUD/board/CTA readability:
- Release signed build install/run:

## Decision

- QA result: Approve / Reject / Blocked
- Approval notes:
- Re-test required:
