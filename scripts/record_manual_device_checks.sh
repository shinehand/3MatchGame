#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SCRIPT_NAME="${0##*/}"
TODAY="$(date +%Y-%m-%d)"
TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%S%z)"
CAPTURE_DIR="output/alpha-lock-pass/$TODAY/captures"
MANIFEST_PATH="$CAPTURE_DIR/manual-device-checks.txt"
SOUND_PATH="$CAPTURE_DIR/sound-toggle-notes.md"
HAPTICS_PATH="$CAPTURE_DIR/haptics-toggle-notes.md"
TOUCH_PATH="$CAPTURE_DIR/touch-latency-notes.md"
BUILD_ARTIFACT_PATH="build/android/puzzle-mobile-starter-debug.apk"

TESTER=""
DEVICE_NAME=""
OS_VERSION=""
SOUND_RESULT=""
HAPTICS_RESULT=""
TOUCH_RESULT=""
SOUND_NOTE=""
HAPTICS_NOTE=""
TOUCH_NOTE=""
DRY_RUN=false

usage() {
	echo "Usage: $SCRIPT_NAME --tester=name --device='model' --os='version' --sound=PASS --haptics=PASS --touch=PASS --sound-note='...' --haptics-note='...' --touch-note='...' [--artifact=build/android/puzzle-mobile-starter-debug.apk] [--output-dir=output/alpha-lock-pass/YYYY-MM-DD/captures] [--dry-run]"
	echo "Records human-judged Android sound, haptics, and touch evidence for the alpha QA packet."
}

normalize_result() {
	local value="$1"
	value="$(print -r -- "$value" | tr '[:lower:]' '[:upper:]')"
	case "$value" in
		PASS|FAIL|BLOCKED)
			print -r -- "$value"
			;;
		*)
			print -r -- ""
			;;
	esac
}

for arg in "$@"; do
	case "$arg" in
		--tester=*)
			TESTER="${arg#--tester=}"
			;;
		--device=*)
			DEVICE_NAME="${arg#--device=}"
			;;
		--os=*)
			OS_VERSION="${arg#--os=}"
			;;
		--sound=*)
			SOUND_RESULT="$(normalize_result "${arg#--sound=}")"
			;;
		--haptics=*)
			HAPTICS_RESULT="$(normalize_result "${arg#--haptics=}")"
			;;
		--touch=*)
			TOUCH_RESULT="$(normalize_result "${arg#--touch=}")"
			;;
		--sound-note=*)
			SOUND_NOTE="${arg#--sound-note=}"
			;;
		--haptics-note=*)
			HAPTICS_NOTE="${arg#--haptics-note=}"
			;;
		--touch-note=*)
			TOUCH_NOTE="${arg#--touch-note=}"
			;;
		--artifact=*)
			BUILD_ARTIFACT_PATH="${arg#--artifact=}"
			;;
		--output-dir=*)
			CAPTURE_DIR="${arg#--output-dir=}"
			MANIFEST_PATH="$CAPTURE_DIR/manual-device-checks.txt"
			SOUND_PATH="$CAPTURE_DIR/sound-toggle-notes.md"
			HAPTICS_PATH="$CAPTURE_DIR/haptics-toggle-notes.md"
			TOUCH_PATH="$CAPTURE_DIR/touch-latency-notes.md"
			;;
		--dry-run)
			DRY_RUN=true
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown option: $arg"
			usage
			exit 2
			;;
	esac
done

failures=()
add_failure() {
	failures+=("$1")
}

require_value() {
	local label="$1"
	local value="$2"
	if [ -z "$value" ]; then
		add_failure "missing ${label}"
	fi
}

require_value "--tester" "$TESTER"
require_value "--device" "$DEVICE_NAME"
require_value "--os" "$OS_VERSION"
require_value "--artifact" "$BUILD_ARTIFACT_PATH"
require_value "--sound PASS|FAIL|BLOCKED" "$SOUND_RESULT"
require_value "--haptics PASS|FAIL|BLOCKED" "$HAPTICS_RESULT"
require_value "--touch PASS|FAIL|BLOCKED" "$TOUCH_RESULT"
require_value "--sound-note" "$SOUND_NOTE"
require_value "--haptics-note" "$HAPTICS_NOTE"
require_value "--touch-note" "$TOUCH_NOTE"

if [ "${#failures[@]}" -gt 0 ]; then
	echo "Manual device checks input failed:"
	for failure in "${failures[@]}"; do
		echo "- $failure"
	done
	usage
	exit 2
fi

if [ "$DRY_RUN" = true ]; then
	echo "Manual device checks dry-run"
	echo "Capture dir: $CAPTURE_DIR"
	echo "Manifest: $MANIFEST_PATH"
	echo "Sound: $SOUND_RESULT -> $SOUND_PATH"
	echo "Haptics: $HAPTICS_RESULT -> $HAPTICS_PATH"
	echo "Touch: $TOUCH_RESULT -> $TOUCH_PATH"
	echo "Build artifact: $BUILD_ARTIFACT_PATH"
	exit 0
fi

mkdir -p "$CAPTURE_DIR"

write_check_file() {
	local target_path="$1"
	local title="$2"
	local result="$3"
	local note="$4"
	{
		echo "# ${title}"
		echo
		echo "Test timestamp: $TIMESTAMP"
		echo "Build source commit: $(git rev-parse --short HEAD)"
		echo "Build artifact: $BUILD_ARTIFACT_PATH"
		echo "Tester: $TESTER"
		echo "Device: $DEVICE_NAME"
		echo "OS version: $OS_VERSION"
		echo "Scenario checked: $title"
		echo "Manual result: $result"
		echo "Note: $note"
		echo "Evidence source: human real-device observation"
	} >"$target_path"
}

write_check_file "$SOUND_PATH" "Sound Toggle Manual Check" "$SOUND_RESULT" "$SOUND_NOTE"
write_check_file "$HAPTICS_PATH" "Haptics Toggle Manual Check" "$HAPTICS_RESULT" "$HAPTICS_NOTE"
write_check_file "$TOUCH_PATH" "Touch Latency Manual Check" "$TOUCH_RESULT" "$TOUCH_NOTE"

overall_result="PASS"
if [ "$SOUND_RESULT" = "FAIL" ] || [ "$HAPTICS_RESULT" = "FAIL" ] || [ "$TOUCH_RESULT" = "FAIL" ]; then
	overall_result="FAIL"
elif [ "$SOUND_RESULT" = "BLOCKED" ] || [ "$HAPTICS_RESULT" = "BLOCKED" ] || [ "$TOUCH_RESULT" = "BLOCKED" ]; then
	overall_result="BLOCKED"
fi

{
	echo "# Manual Device Checks"
	echo
	echo "Test timestamp: $TIMESTAMP"
	echo "Build source commit: $(git rev-parse --short HEAD)"
	echo "Build artifact: $BUILD_ARTIFACT_PATH"
	echo "Tester: $TESTER"
	echo "Device: $DEVICE_NAME"
	echo "OS version: $OS_VERSION"
	echo "Sound result: $SOUND_RESULT"
	echo "Haptics result: $HAPTICS_RESULT"
	echo "Touch result: $TOUCH_RESULT"
	echo "Sound evidence: $SOUND_PATH"
	echo "Haptics evidence: $HAPTICS_PATH"
	echo "Touch evidence: $TOUCH_PATH"
	echo "Manual checks result: $overall_result"
} >"$MANIFEST_PATH"

echo "Manual device checks evidence: $MANIFEST_PATH"
echo "Sound evidence: $SOUND_PATH"
echo "Haptics evidence: $HAPTICS_PATH"
echo "Touch evidence: $TOUCH_PATH"

if [ "$overall_result" != "PASS" ]; then
	echo "Manual device checks did not pass: $overall_result"
	exit 1
fi
