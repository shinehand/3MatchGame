#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_PATH="$ROOT_DIR/docs/qa/templates/alpha-lock-pass-manual-qa-template.md"
TODAY="$(date +%Y-%m-%d)"
OUTPUT_ROOT="$ROOT_DIR/output/alpha-lock-pass/$TODAY"
CAPTURE_DIR="$OUTPUT_ROOT/captures"
REPORT_PATH="$OUTPUT_ROOT/alpha-lock-pass-manual-qa-$TODAY.md"
DRY_RUN=false

fail_template_contract() {
	local missing_kind="$1"
	local missing_value="$2"
	echo "Alpha QA template contract failed: missing ${missing_kind}: ${missing_value}"
	exit 1
}

require_template_text() {
	local missing_kind="$1"
	local required_text="$2"
	if ! grep -Fq -- "$required_text" "$TEMPLATE_PATH"; then
		fail_template_contract "$missing_kind" "$required_text"
	fi
}

require_template_regex() {
	local missing_kind="$1"
	local required_pattern="$2"
	if ! grep -Eq -- "$required_pattern" "$TEMPLATE_PATH"; then
		fail_template_contract "$missing_kind" "$required_pattern"
	fi
}

validate_template_contract() {
	for section in \
		"Run Metadata" \
		"Required Preflight" \
		"Device Evidence Pack" \
		"Representative Course Results" \
		"Stage Data Smoke Coverage" \
		"Focused Device Gate Matrix" \
		"Stage 31 Special Combo Evidence" \
		"Rescue Buddy Stage Matrix" \
		"Monetization And Analytics Evidence" \
		"Failure Continue Gateway" \
		"Analytics Gateway Local Buffer" \
		"Alpha Blocker Log" \
		"Device-Blocked Items" \
		"Decision"; do
		require_template_regex "section" "^#{2,3}[[:space:]]+${section}[[:space:]]*$"
	done

	require_template_text "device evidence header" "| Evidence | Result | Evidence path | Notes |"
	require_template_text "mobile viewport preflight" "| Mobile viewport matrix |"
	require_template_text "mobile viewport compact portrait" "390x844"
	require_template_text "mobile viewport compact landscape" "844x390"
	require_template_text "android debug export preflight" "| Android debug APK export |"
	require_template_text "android debug export command" "zsh scripts/export_android_debug.sh"
	require_template_text "android debug export evidence" "android-debug-export.txt"
	require_template_text "android device evidence preflight" "| Android device evidence capture |"
	require_template_text "android device evidence command" "zsh scripts/capture_android_device_evidence.sh"
	require_template_text "android device evidence orientation option" "--allow-orientation-change"
	require_template_text "android device evidence manifest" "android-device-evidence.txt"
	require_template_text "manual device checks preflight" "| Manual device checks |"
	require_template_text "manual device checks command" "zsh scripts/record_manual_device_checks.sh"
	require_template_text "manual device checks manifest" "manual-device-checks.txt"
	require_template_text "manual sound evidence" "sound-toggle-notes.md"
	require_template_text "manual haptics evidence" "haptics-toggle-notes.md"
	require_template_text "manual touch latency evidence" "touch-latency-notes.md"
	require_template_text "alpha qa report validation preflight" "| Alpha QA report validation |"
	require_template_text "alpha qa report validation command" "zsh scripts/validate_alpha_qa_report.sh"
	require_template_text "representative course header" "| Course | Result | Capture path | 10s understanding | HUD/board readability | Overlay/action clarity | Save/unlock/star persistence | Sound | Haptics | Orientation | Notes |"
	require_template_text "stage data smoke header" "| Scenario ID | Stage | Stage data trigger | Result | Evidence path | Notes |"
	require_template_text "focused gate header" "| Scenario ID | Gate | Required scenario | Result | Evidence path | Notes |"
	require_template_text "special combo header" "| Combo | combo_type | Result | Portrait evidence | Landscape evidence | cleared_count | obstacles_cleared | special_combo_trigger | VFX label distinct | SFX/haptic distinct | input recovers <2s | Notes |"
	require_template_text "buddy header" "| Scenario ID | Stage | Buddy focus | Result | Portrait evidence | Landscape evidence | HUD readable | VFX overlap acceptable | Analytics events | Notes |"
	require_template_text "failure gateway request log" "request log source/stage_id/fail_reason/provider_id/status/result"

	for course in \
		"Home" \
		"Stage 1" \
		"Stage 11" \
		"Stage 25" \
		"Stage 50" \
		"Stage 75" \
		"Stage 100"; do
		require_template_regex "representative course row" "^\\|[[:space:]]*${course}[[:space:]]*\\|"
	done

	for smoke_id in \
		"STAGE_SMOKE_001" \
		"STAGE_SMOKE_004" \
		"STAGE_SMOKE_005" \
		"STAGE_SMOKE_008" \
		"STAGE_SMOKE_010" \
		"STAGE_SMOKE_016" \
		"STAGE_SMOKE_018" \
		"STAGE_SMOKE_020" \
		"STAGE_SMOKE_024" \
		"STAGE_SMOKE_025" \
		"STAGE_SMOKE_031" \
		"STAGE_SMOKE_041" \
		"STAGE_SMOKE_051" \
		"STAGE_SMOKE_081" \
		"STAGE_SMOKE_100"; do
		require_template_regex "stage data smoke row" "^\\|[[:space:]]*${smoke_id}[[:space:]]*\\|"
	done

	for scenario_id in \
		"PAM_QA_040_EXPRESSIONS" \
		"PAM_QA_041_STAGE_POPUP" \
		"STAGE_POPUP_BUDDY" \
		"RESCUE_BOOK_UNLOCK" \
		"SPECIAL_COMBO_6" \
		"RESCUE_BUDDY_SMOKE" \
		"NEAR_MISS_CONTINUE" \
		"MONETIZATION_GATEWAY_PENDING" \
		"ANALYTICS_GATEWAY_LOCAL_BUFFER"; do
		require_template_regex "focused scenario row" "^\\|[[:space:]]*${scenario_id}[[:space:]]*\\|"
	done

	for gate_id in \
		"PAM-QA-040" \
		"PAM-QA-041" \
		"PAM-DEV-051" \
		"PAM-DEV-054" \
		"PAM-ANA-090"; do
		require_template_text "gate id" "$gate_id"
	done

	for combo in \
		"row[+]column" \
		"row[+]row" \
		"column[+]column" \
		"row[+]bomb" \
		"column[+]bomb" \
		"bomb[+]bomb"; do
		require_template_regex "Stage 31 combo row" "^\\|[[:space:]]*${combo}[[:space:]]*\\|"
	done

	for buddy_id in \
		"BUDDY_STAGE_004" \
		"BUDDY_STAGE_005" \
		"BUDDY_STAGE_008" \
		"BUDDY_STAGE_016" \
		"BUDDY_STAGE_018" \
		"BUDDY_STAGE_020" \
		"BUDDY_STAGE_024" \
		"BUDDY_STAGE_025" \
		"BUDDY_STAGE_031" \
		"BUDDY_STAGE_041" \
		"BUDDY_STAGE_051" \
		"BUDDY_STAGE_081"; do
		require_template_regex "Rescue Buddy row" "^\\|[[:space:]]*${buddy_id}[[:space:]]*\\|"
	done

	for buddy_skill in \
		"quick_refill" \
		"soft_bomb_plus" \
		"combo_peep" \
		"smart_hint" \
		"leap_clear" \
		"loyal_fetch" \
		"calm_fever" \
		"coin_sniff" \
		"cascade_slide" \
		"sly_route" \
		"brave_start" \
		"mighty_push"; do
		require_template_text "Rescue Buddy skill" "$buddy_skill"
	done

	for required_text in \
		"rewarded_ad pending keeps overlay" \
		"pending duplicate tap does not create second request" \
		"invalid source rejected_invalid_source" \
		"completed grants once" \
		"failed/canceled preserves moves/wallet/objectives" \
		"duplicate transaction_id grants once" \
		"GameSession saved event" \
		"AnalyticsGateway local_buffer queued" \
		"disk reload preserves queue" \
		"flush drains in order exactly once" \
		"pending queue removed after flush" \
		"contract violation rejected_contract not queued" \
		"provider-neutral/no SDK selected"; do
		require_template_text "evidence scenario" "$required_text"
	done

	for device_evidence in \
		"Build source commit" \
		"APK/AAB path" \
		"Install result" \
		"Device model and OS version" \
		"Portrait screenshot" \
		"Landscape screenshot" \
		"10s video path" \
		"sound ON/OFF" \
		"haptics ON/OFF" \
		"touch latency notes" \
		"logcat or app log path"; do
		require_template_text "device evidence" "$device_evidence"
	done
}

for arg in "$@"; do
	case "$arg" in
		--dry-run)
			DRY_RUN=true
			;;
		-h|--help)
			echo "Usage: $0 [--dry-run]"
			echo "Creates output/alpha-lock-pass/YYYY-MM-DD with a QA report template and captures directory."
			exit 0
			;;
		*)
			echo "Unknown option: $arg"
			echo "Usage: $0 [--dry-run]"
			exit 2
			;;
	esac
done

if [ ! -f "$TEMPLATE_PATH" ]; then
	echo "Missing template: $TEMPLATE_PATH"
	exit 1
fi

validate_template_contract

if [ "$DRY_RUN" = true ]; then
	echo "Would create: $OUTPUT_ROOT"
	echo "Would create: $CAPTURE_DIR"
	echo "Would write:  $REPORT_PATH"
	exit 0
fi

mkdir -p "$CAPTURE_DIR"
if [ -e "$REPORT_PATH" ]; then
	echo "QA packet already exists: $REPORT_PATH"
	exit 1
fi

sed "s/YYYY-MM-DD/$TODAY/g" "$TEMPLATE_PATH" > "$REPORT_PATH"
echo "Alpha QA packet created:"
echo "  report:   $REPORT_PATH"
echo "  captures: $CAPTURE_DIR"
