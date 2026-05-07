#!/bin/zsh
set -euo pipefail
setopt null_glob

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TODAY="$(date +%Y-%m-%d)"
REPORT_PATH="output/alpha-lock-pass/$TODAY/alpha-lock-pass-manual-qa-$TODAY.md"

while [ "$#" -gt 0 ]; do
	arg="$1"
	case "$arg" in
		--report=*)
			REPORT_PATH="${arg#--report=}"
			;;
		--report)
			shift
			if [ "$#" -eq 0 ]; then
				echo "Missing value for --report"
				exit 2
			fi
			REPORT_PATH="$1"
			;;
		-h|--help)
			echo "Usage: $0 [--report output/alpha-lock-pass/YYYY-MM-DD/alpha-lock-pass-manual-qa-YYYY-MM-DD.md]"
			echo "Fails if an alpha QA report still contains unresolved results, placeholder metadata, or missing evidence files."
			exit 0
			;;
		*)
			echo "Unknown option: $arg"
			echo "Usage: $0 [--report path/to/report.md]"
			exit 2
			;;
	esac
	shift
done

failures=()

add_failure() {
	failures+=("$1")
}

require_text() {
	local label="$1"
	local text="$2"
	if ! grep -Fq -- "$text" "$REPORT_PATH"; then
		add_failure "missing ${label}: ${text}"
	fi
}

require_regex() {
	local label="$1"
	local pattern="$2"
	if ! grep -Eq -- "$pattern" "$REPORT_PATH"; then
		add_failure "missing ${label}: ${pattern}"
	fi
}

metadata_value() {
	local label="$1"
	awk -v label="$label" '
		$0 ~ "^- " label ":" {
			sub("^- " label ":[[:space:]]*", "", $0)
			gsub(/[`"]/, "", $0)
			sub(/[[:space:]]+$/, "", $0)
			print
			exit
		}
	' "$REPORT_PATH"
}

metadata_placeholder_reason() {
	local label="$1"
	local value="$2"

	case "$value" in
		*YYYY-MM-DD*)
			print -r -- "date placeholder"
			return
			;;
		Pending|Fail|Blocked|Open|TBD|TODO|"-")
			print -r -- "unresolved status"
			return
			;;
	esac

	case "$label" in
		"Orientation checked")
			case "$value" in
				"portrait / landscape / both"|"portrait/landscape/both"|"portrait, landscape, both")
					print -r -- "orientation choice placeholder"
					return
					;;
			esac
			;;
		"Overall result")
			if [ "$value" = "Pass / Fail / Blocked" ]; then
				print -r -- "result choice placeholder"
				return
			fi
			;;
		"QA result")
			if [ "$value" = "Approve / Reject / Blocked" ]; then
				print -r -- "decision choice placeholder"
				return
			fi
			;;
	esac
}

require_metadata_value() {
	local label="$1"
	local value
	local placeholder_reason
	value="$(metadata_value "$label")"
	if [ -z "$value" ]; then
		add_failure "metadata '${label}' is empty"
		return
	fi
	placeholder_reason="$(metadata_placeholder_reason "$label" "$value")"
	if [ -n "$placeholder_reason" ]; then
		add_failure "metadata '${label}' still has ${placeholder_reason}: ${value}"
	fi
}

require_resolved_device_blocker() {
	local label="$1"
	local line
	line="$(grep -E "^- ${label}:" "$REPORT_PATH" | head -1 || true)"
	if [ -z "$line" ]; then
		add_failure "Device-Blocked Items missing '${label}'"
		return
	fi
	local value="${line#*:}"
	value="$(print -r -- "$value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
	case "$value" in
		""|Pending|Fail|Blocked|Open|TBD|TODO|"-"|"N/A")
			add_failure "Device-Blocked Items '${label}' is unresolved: ${value:-empty}"
			;;
	esac
}

append_evidence_path() {
	local evidence_path="$1"
	case "$evidence_path" in
		output/alpha-lock-pass/*|build/android/*)
			if [ -z "${evidence_seen[$evidence_path]:-}" ]; then
				evidence_paths+=("$evidence_path")
				evidence_seen[$evidence_path]=1
			fi
			;;
	esac
}

require_evidence_text() {
	local evidence_path="$1"
	local label="$2"
	local text="$3"
	if ! grep -Fq -- "$text" "$evidence_path"; then
		add_failure "${label} missing '${text}': ${evidence_path}"
	fi
}

reject_evidence_regex() {
	local evidence_path="$1"
	local label="$2"
	local pattern="$3"
	if grep -Eq -- "$pattern" "$evidence_path"; then
		add_failure "${label} contains failing result matching ${pattern}: ${evidence_path}"
	fi
}

evidence_field_value() {
	local evidence_path="$1"
	local field_label="$2"
	awk -v label="$field_label" '
		$0 ~ "^" label ":" {
			sub("^" label ":[[:space:]]*", "", $0)
			sub(/[[:space:]]+$/, "", $0)
			print
			exit
		}
	' "$evidence_path"
}

require_evidence_field_value() {
	local evidence_path="$1"
	local field_label="$2"
	local value
	value="$(evidence_field_value "$evidence_path" "$field_label")"
	case "$value" in
		""|unknown|null|Pending|PENDING|pending|TBD|tbd|TODO|todo|N/A|n/a|"-")
			add_failure "${evidence_path##*/} field '${field_label}' is unresolved: ${value:-empty}"
			;;
	esac
}

validate_known_evidence_file() {
	local evidence_path="$1"
	local evidence_name="${evidence_path##*/}"
	case "$evidence_name" in
		android-debug-export.txt)
			require_evidence_text "$evidence_path" "$evidence_name" "Export result: PASS"
			require_evidence_text "$evidence_path" "$evidence_name" "Signature verify result: PASS"
			reject_evidence_regex "$evidence_path" "$evidence_name" '(Export|Signature verify|Install) result: (FAIL|BLOCKED)'
			;;
		android-release-export.txt)
			require_evidence_text "$evidence_path" "$evidence_name" "Signing mode: release"
			require_evidence_text "$evidence_path" "$evidence_name" "Release export result: PASS"
			require_evidence_text "$evidence_path" "$evidence_name" "Artifact SHA-256:"
			require_evidence_text "$evidence_path" "$evidence_name" "Signature verify result: PASS"
			require_evidence_text "$evidence_path" "$evidence_name" "Install result: PASS"
			require_evidence_text "$evidence_path" "$evidence_name" "Launch result: PASS"
			reject_evidence_regex "$evidence_path" "$evidence_name" '(Release export|Signature verify|Install|Launch) result: (FAIL|BLOCKED|NOT_REQUESTED)'
			;;
		android-device-evidence.txt)
			require_evidence_text "$evidence_path" "$evidence_name" "Capture result: PASS"
			require_evidence_text "$evidence_path" "$evidence_name" "Launch result: PASS"
			require_evidence_text "$evidence_path" "$evidence_name" "Portrait screenshot result: PASS"
			require_evidence_text "$evidence_path" "$evidence_name" "Landscape screenshot result: PASS"
			require_evidence_text "$evidence_path" "$evidence_name" "Screenrecord result: PASS"
			require_evidence_text "$evidence_path" "$evidence_name" "Logcat result: PASS"
			reject_evidence_regex "$evidence_path" "$evidence_name" '(Capture|Launch|Portrait screenshot|Landscape screenshot|Screenrecord|Screenrecord pull|Logcat) result: (FAIL|BLOCKED|SKIPPED|NOT_REQUESTED)'
			;;
		device-info.txt)
			require_evidence_field_value "$evidence_path" "ADB device id"
			require_evidence_field_value "$evidence_path" "Model"
			require_evidence_field_value "$evidence_path" "Android version"
			require_evidence_field_value "$evidence_path" "Window size"
			if ! grep -Eq -- '^Window size:.*[0-9]+x[0-9]+' "$evidence_path"; then
				add_failure "device-info.txt Window size does not include a pixel size: ${evidence_path}"
			fi
			;;
		install-log.txt|release-install-log.txt)
			require_evidence_text "$evidence_path" "$evidence_name" "Success"
			;;
		release-run-log.txt)
			require_evidence_text "$evidence_path" "$evidence_name" "Launch result: PASS"
			;;
		manual-device-checks.txt)
			require_evidence_text "$evidence_path" "$evidence_name" "Manual checks result: PASS"
			require_evidence_field_value "$evidence_path" "Test timestamp"
			require_evidence_field_value "$evidence_path" "Build source commit"
			require_evidence_field_value "$evidence_path" "Build artifact"
			require_evidence_field_value "$evidence_path" "Tester"
			require_evidence_field_value "$evidence_path" "Device"
			require_evidence_field_value "$evidence_path" "OS version"
			reject_evidence_regex "$evidence_path" "$evidence_name" '(Sound|Haptics|Touch|Manual checks) result: (FAIL|BLOCKED)'
			;;
		sound-toggle-notes.md|haptics-toggle-notes.md|touch-latency-notes.md)
			require_evidence_text "$evidence_path" "$evidence_name" "Manual result: PASS"
			require_evidence_field_value "$evidence_path" "Test timestamp"
			require_evidence_field_value "$evidence_path" "Build source commit"
			require_evidence_field_value "$evidence_path" "Build artifact"
			require_evidence_field_value "$evidence_path" "Tester"
			require_evidence_field_value "$evidence_path" "Device"
			require_evidence_field_value "$evidence_path" "OS version"
			require_evidence_field_value "$evidence_path" "Scenario checked"
			require_evidence_field_value "$evidence_path" "Note"
			;;
	esac
}

validate_report_contract() {
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
		require_regex "section" "^#{2,3}[[:space:]]+${section}[[:space:]]*$"
	done

	for required_text in \
		"| Gate | Command or Evidence | Result | Notes |" \
		"| Evidence | Result | Evidence path | Notes |" \
		"| Course | Result | Capture path | 10s understanding | HUD/board readability | Overlay/action clarity | Save/unlock/star persistence | Sound | Haptics | Orientation | Notes |" \
		"| Scenario ID | Stage | Stage data trigger | Result | Evidence path | Notes |" \
		"| Scenario ID | Gate | Required scenario | Result | Evidence path | Notes |" \
		"| Combo | combo_type | Result | Portrait evidence | Landscape evidence | cleared_count | obstacles_cleared | special_combo_trigger | VFX label distinct | SFX/haptic distinct | input recovers <2s | Notes |" \
		"| Scenario ID | Stage | Buddy focus | Result | Portrait evidence | Landscape evidence | HUD readable | VFX overlap acceptable | Analytics events | Notes |" \
		"Mobile viewport matrix" \
		"390x844" \
		"844x390" \
		"Android debug APK export" \
		"zsh scripts/export_android_debug.sh" \
		"Android device evidence capture" \
		"zsh scripts/capture_android_device_evidence.sh" \
		"--allow-orientation-change" \
		"Manual device checks" \
		"zsh scripts/record_manual_device_checks.sh" \
		"Release preflight" \
		"GODOT_ANDROID_KEYSTORE_RELEASE_PATH" \
		"GODOT_ANDROID_KEYSTORE_RELEASE_USER" \
		"GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" \
		"Android release APK export/install" \
		"zsh scripts/export_android_release.sh --install" \
		"Alpha QA report validation" \
		"zsh scripts/validate_alpha_qa_report.sh"; do
		require_text "required report content" "$required_text"
	done

	for evidence_anchor in \
		"puzzle-mobile-starter-debug.apk" \
		"puzzle-mobile-starter-release.apk" \
		"android-debug-export.txt" \
		"android-device-evidence.txt" \
		"manual-device-checks.txt" \
		"android-release-export.txt" \
		"install-log.txt" \
		"release-install-log.txt" \
		"release-run-log.txt" \
		"device-info.txt" \
		"device-portrait.png" \
		"device-landscape.png" \
		"device-10s.mp4" \
		"device-log.txt" \
		"sound-toggle-notes.md" \
		"haptics-toggle-notes.md" \
		"touch-latency-notes.md"; do
		require_text "evidence anchor" "$evidence_anchor"
	done

	for preflight_gate in \
		"Gameplay validation" \
		"Mobile viewport matrix" \
		"Android debug environment" \
		"Android debug APK export" \
		"Android device evidence capture" \
		"Manual device checks" \
		"Release preflight" \
		"Android release APK export/install" \
		"Install/run evidence" \
		"Alpha QA report validation"; do
		require_regex "preflight Pass row" "^\\|[[:space:]]*${preflight_gate}[[:space:]]*\\|[^|]*\\|[[:space:]]*Pass[[:space:]]*\\|"
	done

	for device_evidence in \
		"Build source commit" \
		"APK/AAB path" \
		"Install result" \
		"Release APK path" \
		"Release install result" \
		"Release launch/run result" \
		"Device model and OS version" \
		"Portrait screenshot" \
		"Landscape screenshot" \
		"10s video path" \
		"sound ON/OFF" \
		"haptics ON/OFF" \
		"touch latency notes" \
		"logcat or app log path"; do
		require_regex "device evidence Pass row" "^\\|[[:space:]]*${device_evidence}[[:space:]]*\\|[[:space:]]*Pass[[:space:]]*\\|"
	done

	for course in \
		"Home" \
		"Stage 1" \
		"Stage 11" \
		"Stage 25" \
		"Stage 50" \
		"Stage 75" \
		"Stage 100"; do
		require_regex "representative course row" "^\\|[[:space:]]*${course}[[:space:]]*\\|"
		require_regex "representative course Pass row" "^\\|[[:space:]]*${course}[[:space:]]*\\|[[:space:]]*Pass[[:space:]]*\\|"
	done

	for course_capture in \
		"home.png" \
		"stage-001.png" \
		"stage-011.png" \
		"stage-025.png" \
		"stage-050.png" \
		"stage-075.png" \
		"stage-100.png"; do
		require_text "representative course capture anchor" "$course_capture"
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
		require_regex "stage data smoke row" "^\\|[[:space:]]*${smoke_id}[[:space:]]*\\|"
		require_regex "stage data smoke Pass row" "^\\|[[:space:]]*${smoke_id}[[:space:]]*\\|[^|]*\\|[^|]*\\|[[:space:]]*Pass[[:space:]]*\\|"
	done

	for stage_smoke_anchor in \
		"stage-smoke-001" \
		"stage-smoke-004" \
		"stage-smoke-005" \
		"stage-smoke-008" \
		"stage-smoke-010" \
		"stage-smoke-016" \
		"stage-smoke-018" \
		"stage-smoke-020" \
		"stage-smoke-024" \
		"stage-smoke-025" \
		"stage-smoke-031" \
		"stage-smoke-041" \
		"stage-smoke-051" \
		"stage-smoke-081" \
		"stage-smoke-100"; do
		require_text "stage smoke evidence anchor" "$stage_smoke_anchor"
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
		require_regex "focused scenario row" "^\\|[[:space:]]*${scenario_id}[[:space:]]*\\|"
		require_regex "focused scenario Pass row" "^\\|[[:space:]]*${scenario_id}[[:space:]]*\\|[^|]*\\|[^|]*\\|[[:space:]]*Pass[[:space:]]*\\|"
	done

	for focused_anchor in \
		"pam-qa-040-expressions" \
		"pam-qa-041-popup" \
		"stage-popup-buddy" \
		"rescue-book-unlock" \
		"stage-031-special-combos" \
		"buddy-readability" \
		"near-miss-continue" \
		"monetization-gateway" \
		"analytics-local-buffer"; do
		require_text "focused evidence anchor" "$focused_anchor"
	done

	for combo in \
		"row[+]column" \
		"row[+]row" \
		"column[+]column" \
		"row[+]bomb" \
		"column[+]bomb" \
		"bomb[+]bomb"; do
		require_regex "Stage 31 combo row" "^\\|[[:space:]]*${combo}[[:space:]]*\\|"
		require_regex "Stage 31 combo Pass row" "^\\|[[:space:]]*${combo}[[:space:]]*\\|[^|]*\\|[[:space:]]*Pass[[:space:]]*\\|"
	done

	for combo_anchor in \
		"combo-row-column-portrait" \
		"combo-row-column-landscape" \
		"combo-row-row-portrait" \
		"combo-row-row-landscape" \
		"combo-column-column-portrait" \
		"combo-column-column-landscape" \
		"combo-row-bomb-portrait" \
		"combo-row-bomb-landscape" \
		"combo-column-bomb-portrait" \
		"combo-column-bomb-landscape" \
		"combo-bomb-bomb-portrait" \
		"combo-bomb-bomb-landscape"; do
		require_text "Stage 31 combo evidence anchor" "$combo_anchor"
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
		require_regex "Rescue Buddy row" "^\\|[[:space:]]*${buddy_id}[[:space:]]*\\|"
		require_regex "Rescue Buddy Pass row" "^\\|[[:space:]]*${buddy_id}[[:space:]]*\\|[^|]*\\|[^|]*\\|[[:space:]]*Pass[[:space:]]*\\|"
	done

	for buddy_anchor in \
		"buddy-stage-004-portrait" \
		"buddy-stage-004-landscape" \
		"buddy-stage-005-portrait" \
		"buddy-stage-005-landscape" \
		"buddy-stage-008-portrait" \
		"buddy-stage-008-landscape" \
		"buddy-stage-016-portrait" \
		"buddy-stage-016-landscape" \
		"buddy-stage-018-portrait" \
		"buddy-stage-018-landscape" \
		"buddy-stage-020-portrait" \
		"buddy-stage-020-landscape" \
		"buddy-stage-024-portrait" \
		"buddy-stage-024-landscape" \
		"buddy-stage-025-portrait" \
		"buddy-stage-025-landscape" \
		"buddy-stage-031-portrait" \
		"buddy-stage-031-landscape" \
		"buddy-stage-041-portrait" \
		"buddy-stage-041-landscape" \
		"buddy-stage-051-portrait" \
		"buddy-stage-051-landscape" \
		"buddy-stage-081-portrait" \
		"buddy-stage-081-landscape"; do
		require_text "Rescue Buddy evidence anchor" "$buddy_anchor"
	done

	for required_text in \
		"rewarded_ad pending keeps overlay" \
		"IAP pending" \
		"pending duplicate tap does not create second request" \
		"invalid source rejected_invalid_source" \
		"request log source/stage_id/fail_reason/provider_id/status/result" \
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
		require_text "monetization or analytics scenario" "$required_text"
		require_regex "monetization or analytics Pass row" "^\\|[[:space:]]*${required_text}[[:space:]]*\\|[^|]*\\|[[:space:]]*Pass[[:space:]]*\\|"
	done

	for gateway_anchor in \
		"rewarded-pending" \
		"iap-pending" \
		"pending-duplicate-tap" \
		"invalid-source" \
		"request-log" \
		"completed-grants-once" \
		"failed-canceled-preserve-state" \
		"duplicate-transaction" \
		"analytics-gamesession" \
		"analytics-buffer-queued" \
		"analytics-buffer-reload" \
		"analytics-flush-order" \
		"analytics-flush-empty" \
		"analytics-rejected-contract" \
		"analytics-provider-neutral"; do
		require_text "monetization or analytics evidence anchor" "$gateway_anchor"
	done
}

if [ ! -f "$REPORT_PATH" ]; then
	echo "Alpha QA report missing: $REPORT_PATH"
	exit 1
fi

if [ ! -s "$REPORT_PATH" ]; then
	echo "Alpha QA report is empty: $REPORT_PATH"
	exit 1
fi

validate_report_contract

for label in \
	"QA date" \
	"Build source commit" \
	"Build artifact path" \
	"Device" \
	"OS version" \
	"Orientation checked" \
	"Tester" \
	"Overall result" \
	"QA result"; do
	require_metadata_value "$label"
done

overall_result="$(metadata_value "Overall result")"
if [ "$overall_result" != "Pass" ]; then
	add_failure "Overall result must be Pass, got '${overall_result}'"
fi

qa_result="$(metadata_value "QA result")"
if [ "$qa_result" != "Approve" ]; then
	add_failure "QA result must be Approve, got '${qa_result}'"
fi

report_commit="$(metadata_value "Build source commit" | awk '{print $1}')"
head_commit="$(git rev-parse HEAD)"
if [ -n "$report_commit" ] && [ "${head_commit:0:${#report_commit}}" != "$report_commit" ]; then
	add_failure "Build source commit '${report_commit}' does not match current HEAD ${head_commit}"
fi

if grep -Eq '\|[[:space:]]*(Pending|Fail|Blocked|Open)[[:space:]]*\|' "$REPORT_PATH"; then
	add_failure "report still contains table result cells with Pending, Fail, Blocked, or Open"
fi

if grep -Fq "YYYY-MM-DD" "$REPORT_PATH"; then
	add_failure "report still contains YYYY-MM-DD placeholders"
fi

for device_blocker in \
	"Android real-device sound playback" \
	"Android real-device haptics and ON/OFF setting" \
	"Touch latency and gesture feel" \
	"Physical portrait viewport HUD/board/CTA readability" \
	"Release signed build install/run"; do
	require_resolved_device_blocker "$device_blocker"
done

evidence_paths=()
typeset -A evidence_seen
while IFS= read -r path_token; do
	path_token="${path_token#\`}"
	path_token="${path_token%\`}"
	append_evidence_path "$path_token"
done < <(grep -Eo '`(output/alpha-lock-pass/[^`]+|build/android/[^`]+)`' "$REPORT_PATH" || true)

build_artifact_path="$(metadata_value "Build artifact path" | awk '{print $1}')"
append_evidence_path "$build_artifact_path"

if [ "${#evidence_paths[@]}" -eq 0 ]; then
	add_failure "report has no machine-checkable output/build evidence paths"
fi

for evidence_path in "${evidence_paths[@]}"; do
	if [[ "$evidence_path" == *"*"* ]]; then
		matches=($~evidence_path)
		if [ "${#matches[@]}" -eq 0 ]; then
			add_failure "evidence glob has no matches: ${evidence_path}"
		else
			for match_path in "${matches[@]}"; do
				if [ ! -s "$match_path" ]; then
					add_failure "evidence glob match is empty: ${match_path}"
				else
					validate_known_evidence_file "$match_path"
				fi
			done
		fi
	else
		if [ ! -e "$evidence_path" ]; then
			add_failure "evidence path missing: ${evidence_path}"
		elif [ ! -s "$evidence_path" ]; then
			add_failure "evidence path is empty: ${evidence_path}"
		else
			validate_known_evidence_file "$evidence_path"
		fi
	fi
done

if [ "${#failures[@]}" -gt 0 ]; then
	echo "Alpha QA report validation failed: $REPORT_PATH"
	for failure in "${failures[@]}"; do
		echo "- $failure"
	done
	exit 1
fi

echo "Alpha QA report validation passed: $REPORT_PATH"
