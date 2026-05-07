#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TODAY="$(date +%Y-%m-%d)"
CAPTURE_DIR="output/alpha-lock-pass/$TODAY/captures"
MANIFEST_PATH="$CAPTURE_DIR/android-device-evidence.txt"
DEVICE_INFO_PATH="$CAPTURE_DIR/device-info.txt"
PORTRAIT_PATH="$CAPTURE_DIR/device-portrait.png"
LANDSCAPE_PATH="$CAPTURE_DIR/device-landscape.png"
VIDEO_PATH="$CAPTURE_DIR/device-10s.mp4"
LOGCAT_PATH="$CAPTURE_DIR/device-log.txt"
VIDEO_SECONDS=10
LAUNCH_APP=true
ROTATE_DEVICE=false
DRY_RUN=false

SDK_PATH="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$SDK_PATH/platform-tools/adb"
PACKAGE_ID="$(awk -F= '/^package\/unique_name=/{ gsub(/"/, "", $2); print $2; exit }' export_presets.cfg)"

usage() {
	echo "Usage: $0 [--package=com.example.app] [--output-dir=output/alpha-lock-pass/YYYY-MM-DD/captures] [--video-seconds=10] [--skip-launch] [--allow-orientation-change] [--no-rotate] [--dry-run]"
	echo "Captures Android real-device QA evidence for the alpha manual QA packet."
}

for arg in "$@"; do
	case "$arg" in
		--package=*)
			PACKAGE_ID="${arg#--package=}"
			;;
		--output-dir=*)
			CAPTURE_DIR="${arg#--output-dir=}"
			MANIFEST_PATH="$CAPTURE_DIR/android-device-evidence.txt"
			DEVICE_INFO_PATH="$CAPTURE_DIR/device-info.txt"
			PORTRAIT_PATH="$CAPTURE_DIR/device-portrait.png"
			LANDSCAPE_PATH="$CAPTURE_DIR/device-landscape.png"
			VIDEO_PATH="$CAPTURE_DIR/device-10s.mp4"
			LOGCAT_PATH="$CAPTURE_DIR/device-log.txt"
			;;
		--video-seconds=*)
			VIDEO_SECONDS="${arg#--video-seconds=}"
			;;
		--skip-launch)
			LAUNCH_APP=false
			;;
		--allow-orientation-change)
			ROTATE_DEVICE=true
			;;
		--no-rotate)
			ROTATE_DEVICE=false
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

if [ -z "$PACKAGE_ID" ]; then
	echo "Android package id is empty. Set --package or export_presets.cfg package/unique_name."
	exit 1
fi

if ! [[ "$VIDEO_SECONDS" =~ '^[0-9]+$' ]] || [ "$VIDEO_SECONDS" -lt 1 ] || [ "$VIDEO_SECONDS" -gt 180 ]; then
	echo "Invalid --video-seconds value: $VIDEO_SECONDS"
	exit 2
fi

if [ "$DRY_RUN" = true ]; then
	echo "Android device evidence dry-run"
	echo "ADB: $ADB"
	echo "Package: $PACKAGE_ID"
	echo "Launch requested: $LAUNCH_APP"
	echo "Rotate requested: $ROTATE_DEVICE"
	echo "Capture dir: $CAPTURE_DIR"
	echo "Manifest: $MANIFEST_PATH"
	echo "Device info: $DEVICE_INFO_PATH"
	echo "Portrait screenshot: $PORTRAIT_PATH"
	echo "Landscape screenshot: $LANDSCAPE_PATH"
	echo "10s video: $VIDEO_PATH"
	echo "Logcat: $LOGCAT_PATH"
	exit 0
fi

write_capture_step_results() {
	local result="$1"
	{
		echo "Launch result: $result"
		echo "Portrait screenshot result: $result"
		echo "Landscape screenshot result: $result"
		echo "Screenrecord result: $result"
		echo "Logcat result: $result"
	} >>"$MANIFEST_PATH"
}

mkdir -p "$CAPTURE_DIR"
rm -f "$MANIFEST_PATH" "$DEVICE_INFO_PATH" "$PORTRAIT_PATH" "$LANDSCAPE_PATH" "$VIDEO_PATH" "$LOGCAT_PATH"

{
	echo "# Android Device Evidence"
	echo
	echo "Date: $TODAY"
	echo "Commit: $(git rev-parse --short HEAD)"
	echo "Package: $PACKAGE_ID"
	echo "Capture dir: $CAPTURE_DIR"
	echo "Launch requested: $LAUNCH_APP"
	echo "Rotate requested: $ROTATE_DEVICE"
	echo "Video seconds: $VIDEO_SECONDS"
	echo "Tester: Pending"
	echo
	echo "## Output Paths"
	echo "Device info: $DEVICE_INFO_PATH"
	echo "Portrait screenshot: $PORTRAIT_PATH"
	echo "Landscape screenshot: $LANDSCAPE_PATH"
	echo "10s video: $VIDEO_PATH"
	echo "Logcat: $LOGCAT_PATH"
	echo
	echo "## ADB"
	echo "ADB path: $ADB"
} >"$MANIFEST_PATH"

if [ ! -x "$ADB" ]; then
	{
		echo
		echo "## Capture Step Results"
	} >>"$MANIFEST_PATH"
	write_capture_step_results "FAIL - adb missing or not executable"
	echo "Capture result: FAIL - adb missing or not executable" >>"$MANIFEST_PATH"
	echo "adb missing or not executable: $ADB"
	exit 1
fi

ADB_DEVICES_PATH="$CAPTURE_DIR/adb-devices.txt"
"$ADB" devices >"$ADB_DEVICES_PATH" 2>&1 || true
cat "$ADB_DEVICES_PATH" >>"$MANIFEST_PATH"

device_count="$(awk 'NR > 1 && $2 == "device" { count++ } END { print count + 0 }' "$ADB_DEVICES_PATH")"
device_serial="$(awk 'NR > 1 && $2 == "device" { print $1; exit }' "$ADB_DEVICES_PATH")"
if [ "$device_count" -ne 1 ]; then
	{
		echo
		echo "## Capture Step Results"
	} >>"$MANIFEST_PATH"
	write_capture_step_results "BLOCKED - expected exactly one connected device, got $device_count"
	{
		echo "Capture result: BLOCKED - expected exactly one connected device, got $device_count"
		echo "Connect one authorized Android device, then rerun this script."
	} >>"$MANIFEST_PATH"
	echo "Android device evidence blocked. See $MANIFEST_PATH"
	exit 1
fi

adb_shell() {
	"$ADB" -s "$device_serial" shell "$@" 2>/dev/null | tr -d '\r'
}

old_accelerometer_rotation="$(adb_shell settings get system accelerometer_rotation || echo "")"
old_user_rotation="$(adb_shell settings get system user_rotation || echo "")"
orientation_changed=false

restore_orientation() {
	if [ "$orientation_changed" = true ]; then
		if [ -z "$old_accelerometer_rotation" ] || [ "$old_accelerometer_rotation" = "null" ]; then
			"$ADB" -s "$device_serial" shell settings delete system accelerometer_rotation >/dev/null 2>&1 || true
		else
			"$ADB" -s "$device_serial" shell settings put system accelerometer_rotation "$old_accelerometer_rotation" >/dev/null 2>&1 || true
		fi
		if [ -z "$old_user_rotation" ] || [ "$old_user_rotation" = "null" ]; then
			"$ADB" -s "$device_serial" shell settings delete system user_rotation >/dev/null 2>&1 || true
		else
			"$ADB" -s "$device_serial" shell settings put system user_rotation "$old_user_rotation" >/dev/null 2>&1 || true
		fi
	fi
}
trap restore_orientation EXIT

{
	echo "# Device Info"
	echo
	echo "ADB device id: $device_serial"
	echo "Manufacturer: $(adb_shell getprop ro.product.manufacturer || echo "unknown")"
	echo "Model: $(adb_shell getprop ro.product.model || echo "unknown")"
	echo "Device: $(adb_shell getprop ro.product.device || echo "unknown")"
	echo "Android version: $(adb_shell getprop ro.build.version.release || echo "unknown")"
	echo "Android SDK: $(adb_shell getprop ro.build.version.sdk || echo "unknown")"
	echo "Build fingerprint: $(adb_shell getprop ro.build.fingerprint || echo "unknown")"
	echo "Window size: $(adb_shell wm size || echo "unknown")"
	echo "Window density: $(adb_shell wm density || echo "unknown")"
	echo "Initial accelerometer_rotation: ${old_accelerometer_rotation:-unknown}"
	echo "Initial user_rotation: ${old_user_rotation:-unknown}"
} >"$DEVICE_INFO_PATH"

cat "$DEVICE_INFO_PATH" >>"$MANIFEST_PATH"

if [ "$LAUNCH_APP" = true ]; then
	{
		echo
		echo "## Launch"
		echo "Command: $ADB -s $device_serial shell monkey -p $PACKAGE_ID -c android.intent.category.LAUNCHER 1"
	} >>"$MANIFEST_PATH"
	if ! "$ADB" -s "$device_serial" shell monkey -p "$PACKAGE_ID" -c android.intent.category.LAUNCHER 1 >>"$MANIFEST_PATH" 2>&1; then
		echo "Launch result: FAIL" >>"$MANIFEST_PATH"
		echo "Android app launch failed. See $MANIFEST_PATH"
		exit 1
	fi
	echo "Launch result: PASS" >>"$MANIFEST_PATH"
	sleep 2
else
	echo "Launch result: SKIPPED" >>"$MANIFEST_PATH"
fi

{
	echo
	echo "## Runtime Focus"
	echo "App pid: $(adb_shell pidof "$PACKAGE_ID" || echo "unknown")"
	echo "Window focus:"
	"$ADB" -s "$device_serial" shell dumpsys window 2>/dev/null | tr -d '\r' | grep -E 'mCurrentFocus|mFocusedApp' | head -5 || true
} >>"$MANIFEST_PATH"

set_rotation() {
	local rotation="$1"
	if [ "$ROTATE_DEVICE" != true ]; then
		return
	fi
	if "$ADB" -s "$device_serial" shell settings put system accelerometer_rotation 0 >/dev/null 2>&1 && \
		"$ADB" -s "$device_serial" shell settings put system user_rotation "$rotation" >/dev/null 2>&1; then
		orientation_changed=true
		sleep 1
	else
		echo "Rotation request failed for user_rotation=$rotation; capturing current orientation." >>"$MANIFEST_PATH"
	fi
}

capture_screenshot() {
	local label="$1"
	local target_path="$2"
	{
		echo
		echo "## ${label} Screenshot"
		echo "Path: $target_path"
	} >>"$MANIFEST_PATH"
	if ! "$ADB" -s "$device_serial" exec-out screencap -p >"$target_path"; then
		echo "${label} screenshot result: FAIL" >>"$MANIFEST_PATH"
		echo "Failed to capture ${label} screenshot. See $MANIFEST_PATH"
		exit 1
	fi
	if [ ! -s "$target_path" ]; then
		echo "${label} screenshot result: FAIL - empty file" >>"$MANIFEST_PATH"
		echo "Empty ${label} screenshot: $target_path"
		exit 1
	fi
	echo "${label} screenshot result: PASS" >>"$MANIFEST_PATH"
}

set_rotation 0
capture_screenshot "Portrait" "$PORTRAIT_PATH"

set_rotation 1
capture_screenshot "Landscape" "$LANDSCAPE_PATH"

{
	echo
	echo "## Screenrecord"
	echo "Path: $VIDEO_PATH"
	echo "Command: $ADB -s $device_serial shell screenrecord --time-limit $VIDEO_SECONDS /sdcard/pam-device-10s.mp4"
} >>"$MANIFEST_PATH"
REMOTE_VIDEO="/sdcard/pam-device-10s.mp4"
"$ADB" -s "$device_serial" shell rm -f "$REMOTE_VIDEO" >/dev/null 2>&1 || true
if ! "$ADB" -s "$device_serial" shell screenrecord --time-limit "$VIDEO_SECONDS" "$REMOTE_VIDEO" >>"$MANIFEST_PATH" 2>&1; then
	echo "Screenrecord result: FAIL" >>"$MANIFEST_PATH"
	echo "Android screenrecord failed. See $MANIFEST_PATH"
	exit 1
fi
if ! "$ADB" -s "$device_serial" pull "$REMOTE_VIDEO" "$VIDEO_PATH" >>"$MANIFEST_PATH" 2>&1; then
	echo "Screenrecord pull result: FAIL" >>"$MANIFEST_PATH"
	echo "Failed to pull screenrecord. See $MANIFEST_PATH"
	exit 1
fi
"$ADB" -s "$device_serial" shell rm -f "$REMOTE_VIDEO" >/dev/null 2>&1 || true
if [ ! -s "$VIDEO_PATH" ]; then
	echo "Screenrecord result: FAIL - empty file" >>"$MANIFEST_PATH"
	echo "Empty screenrecord: $VIDEO_PATH"
	exit 1
fi
echo "Screenrecord result: PASS" >>"$MANIFEST_PATH"

{
	echo
	echo "## Logcat"
	echo "Path: $LOGCAT_PATH"
	echo "Command: $ADB -s $device_serial logcat -d -t 1000"
} >>"$MANIFEST_PATH"
if ! "$ADB" -s "$device_serial" logcat -d -t 1000 >"$LOGCAT_PATH" 2>&1; then
	echo "Logcat result: FAIL" >>"$MANIFEST_PATH"
	echo "Failed to capture logcat. See $MANIFEST_PATH"
	exit 1
fi
if [ ! -s "$LOGCAT_PATH" ]; then
	echo "Logcat result: FAIL - empty file" >>"$MANIFEST_PATH"
	echo "Empty logcat: $LOGCAT_PATH"
	exit 1
fi
echo "Logcat result: PASS" >>"$MANIFEST_PATH"

{
	echo
	echo "## Manual Follow-Up Required"
	echo "- sound ON/OFF playback must still be judged by a human on device."
	echo "- haptics ON/OFF feedback must still be judged by a human on device."
	echo "- touch latency and gesture feel must still be judged by a human on device."
	echo "- Run with --allow-orientation-change when portrait/landscape physical capture is required."
	echo "- If the app is portrait-locked, the landscape screenshot is still useful as proof of physical orientation behavior."
	echo
	echo "Capture result: PASS"
} >>"$MANIFEST_PATH"

echo "Android device evidence: $MANIFEST_PATH"
echo "Device info: $DEVICE_INFO_PATH"
echo "Portrait screenshot: $PORTRAIT_PATH"
echo "Landscape screenshot: $LANDSCAPE_PATH"
echo "10s video: $VIDEO_PATH"
echo "Logcat: $LOGCAT_PATH"
