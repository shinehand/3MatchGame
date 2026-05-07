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
