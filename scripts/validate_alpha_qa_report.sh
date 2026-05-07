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
	if ! grep -Fq "$text" "$REPORT_PATH"; then
		add_failure "missing ${label}: ${text}"
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
			evidence_paths+=("$evidence_path")
			;;
	esac
}

if [ ! -f "$REPORT_PATH" ]; then
	echo "Alpha QA report missing: $REPORT_PATH"
	exit 1
fi

if [ ! -s "$REPORT_PATH" ]; then
	echo "Alpha QA report is empty: $REPORT_PATH"
	exit 1
fi

for section in \
	"Run Metadata" \
	"Required Preflight" \
	"Device Evidence Pack" \
	"Representative Course Results" \
	"Stage Data Smoke Coverage" \
	"Focused Device Gate Matrix" \
	"Stage 31 Special Combo Evidence" \
	"Rescue Buddy Stage Matrix" \
	"Failure Continue Gateway" \
	"Analytics Gateway Local Buffer" \
	"Alpha Blocker Log" \
	"Decision"; do
	require_text "section" "## ${section}"
done

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
				fi
			done
		fi
	else
		if [ ! -e "$evidence_path" ]; then
			add_failure "evidence path missing: ${evidence_path}"
		elif [ ! -s "$evidence_path" ]; then
			add_failure "evidence path is empty: ${evidence_path}"
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
