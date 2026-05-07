#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_APK="build/android/puzzle-mobile-starter-release.apk"
INSTALL=false
DRY_RUN=false
EXPORT_PRESET_NAME="Android"

for arg in "$@"; do
	case "$arg" in
		--install)
			INSTALL=true
			;;
		--output=*)
			OUTPUT_APK="${arg#--output=}"
			;;
		--preset=*)
			EXPORT_PRESET_NAME="${arg#--preset=}"
			;;
		--dry-run)
			DRY_RUN=true
			;;
		-h|--help)
			echo "Usage: $0 [--install] [--output=build/android/puzzle-mobile-starter-release.apk] [--preset=Android] [--dry-run]"
			echo "Requires GODOT_ANDROID_KEYSTORE_RELEASE_PATH, GODOT_ANDROID_KEYSTORE_RELEASE_USER, and GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD."
			echo "Legacy aliases GODOT_RELEASE_KEYSTORE_PATH/USER/PASSWORD are also accepted."
			exit 0
			;;
		*)
			echo "Unknown option: $arg"
			echo "Usage: $0 [--install] [--output=path/to/app.apk] [--preset=Android] [--dry-run]"
			exit 2
			;;
	esac
done

TODAY="$(date +%Y-%m-%d)"
CAPTURE_DIR="output/alpha-lock-pass/$TODAY/captures"
EVIDENCE_PATH="$CAPTURE_DIR/android-release-export.txt"
EXPORT_LOG="build/android/export-release.log"
VERIFY_LOG="build/android/apksigner-verify-release.log"
ADB_LOG="build/android/adb-devices-release.log"
INSTALL_LOG="$CAPTURE_DIR/release-install-log.txt"
RUN_LOG="$CAPTURE_DIR/release-run-log.txt"

SDK_PATH="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
BUILD_TOOLS_VERSION="${ANDROID_BUILD_TOOLS_VERSION:-35.0.1}"
APKSIGNER="$SDK_PATH/build-tools/$BUILD_TOOLS_VERSION/apksigner"
ADB="$SDK_PATH/platform-tools/adb"
GODOT_VERSION="$(godot --version)"
PACKAGE_ID="$(awk -F= '/^package\/unique_name=/{ gsub(/"/, "", $2); print $2; exit }' export_presets.cfg)"
VERSION_CODE="$(awk -F= '/^version\/code=/{ gsub(/"/, "", $2); print $2; exit }' export_presets.cfg)"
VERSION_NAME="$(awk -F= '/^version\/name=/{ gsub(/"/, "", $2); print $2; exit }' export_presets.cfg)"
MIN_SDK="$(awk -F= '/^gradle_build\/min_sdk=/{ gsub(/"/, "", $2); print $2; exit }' export_presets.cfg)"
TARGET_SDK="$(awk -F= '/^gradle_build\/target_sdk=/{ gsub(/"/, "", $2); print $2; exit }' export_presets.cfg)"

RELEASE_KEYSTORE_PATH="${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-${GODOT_RELEASE_KEYSTORE_PATH:-}}"
RELEASE_KEYSTORE_USER="${GODOT_ANDROID_KEYSTORE_RELEASE_USER:-${GODOT_RELEASE_KEYSTORE_USER:-}}"
RELEASE_KEYSTORE_PASSWORD="${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:-${GODOT_RELEASE_KEYSTORE_PASSWORD:-}}"

failures=()
add_failure() {
	failures+=("$1")
}

if [ -z "$RELEASE_KEYSTORE_PATH" ]; then
	add_failure "missing GODOT_ANDROID_KEYSTORE_RELEASE_PATH or GODOT_RELEASE_KEYSTORE_PATH"
elif [ ! -f "$RELEASE_KEYSTORE_PATH" ]; then
	add_failure "release keystore file missing: $RELEASE_KEYSTORE_PATH"
fi

if [ -z "$RELEASE_KEYSTORE_USER" ]; then
	add_failure "missing GODOT_ANDROID_KEYSTORE_RELEASE_USER or GODOT_RELEASE_KEYSTORE_USER"
fi

if [ -z "$RELEASE_KEYSTORE_PASSWORD" ]; then
	add_failure "missing GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD or GODOT_RELEASE_KEYSTORE_PASSWORD"
fi

if [ -z "$PACKAGE_ID" ]; then
	add_failure "missing package/unique_name in export_presets.cfg"
fi

if [ "$DRY_RUN" = true ]; then
	echo "Android release export dry-run"
	echo "Output APK: $OUTPUT_APK"
	echo "Preset: $EXPORT_PRESET_NAME"
	echo "Install requested: $INSTALL"
	echo "Evidence: $EVIDENCE_PATH"
	echo "Release keystore path: ${RELEASE_KEYSTORE_PATH:-MISSING}"
	echo "Release keystore user: ${RELEASE_KEYSTORE_USER:-MISSING}"
	if [ -n "$RELEASE_KEYSTORE_PASSWORD" ]; then
		echo "Release keystore password: SET"
	else
		echo "Release keystore password: MISSING"
	fi
	if [ "${#failures[@]}" -gt 0 ]; then
		echo "Dry-run release input failures:"
		for failure in "${failures[@]}"; do
			echo "- $failure"
		done
		exit 1
	fi
	exit 0
fi

mkdir -p "$(dirname "$OUTPUT_APK")" "$CAPTURE_DIR"
rm -f "$OUTPUT_APK" "$EXPORT_LOG" "$VERIFY_LOG" "$ADB_LOG" "$EVIDENCE_PATH"

{
	echo "# Android Release Export Evidence"
	echo
	echo "Date: $TODAY"
	echo "Commit: $(git rev-parse --short HEAD)"
	echo "Godot version: $GODOT_VERSION"
	echo "Export preset: $EXPORT_PRESET_NAME"
	echo "Signing mode: release"
	echo "Package: ${PACKAGE_ID:-MISSING}"
	echo "Version code: ${VERSION_CODE:-MISSING}"
	echo "Version name: ${VERSION_NAME:-MISSING}"
	echo "minSdk: ${MIN_SDK:-project default}"
	echo "targetSdk: ${TARGET_SDK:-project default}"
	echo "Release keystore path: ${RELEASE_KEYSTORE_PATH:-MISSING}"
	echo "Release keystore user: ${RELEASE_KEYSTORE_USER:-MISSING}"
	echo "Release keystore password: SET=${RELEASE_KEYSTORE_PASSWORD:+true}"
	echo "APK: $OUTPUT_APK"
	echo "Install requested: $INSTALL"
	echo "Tester: Pending"
	echo "Export log path: $EXPORT_LOG"
	echo "Signature verify log path: $VERIFY_LOG"
	echo "Run log path: $RUN_LOG"
	echo
	echo "## Release Input"
} >"$EVIDENCE_PATH"

if [ "${#failures[@]}" -gt 0 ]; then
	for failure in "${failures[@]}"; do
		echo "- $failure" >>"$EVIDENCE_PATH"
	done
	echo "Release export result: BLOCKED" >>"$EVIDENCE_PATH"
	echo "Android release export blocked. See $EVIDENCE_PATH"
	exit 1
fi

export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$RELEASE_KEYSTORE_PATH"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$RELEASE_KEYSTORE_USER"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$RELEASE_KEYSTORE_PASSWORD"

{
	echo "Release input result: PASS"
	echo
	echo "## Android Release Setup"
} >>"$EVIDENCE_PATH"
zsh scripts/check_android_setup.sh --release >>"$EVIDENCE_PATH"

if [ ! -x "$APKSIGNER" ]; then
	echo "apksigner missing or not executable: $APKSIGNER" >>"$EVIDENCE_PATH"
	echo "Release export result: FAIL" >>"$EVIDENCE_PATH"
	echo "Android release export failed: missing apksigner."
	exit 1
fi

if [ ! -x "$ADB" ]; then
	echo "adb missing or not executable: $ADB" >>"$EVIDENCE_PATH"
	echo "Release export result: FAIL" >>"$EVIDENCE_PATH"
	echo "Android release export failed: missing adb."
	exit 1
fi

{
	echo
	echo "## Export"
	echo "Command: godot --headless --path . --export-release $EXPORT_PRESET_NAME $OUTPUT_APK"
} >>"$EVIDENCE_PATH"

if ! godot --headless --path . --export-release "$EXPORT_PRESET_NAME" "$OUTPUT_APK" >"$EXPORT_LOG" 2>&1; then
	cat "$EXPORT_LOG" >>"$EVIDENCE_PATH"
	echo "Release export result: FAIL" >>"$EVIDENCE_PATH"
	echo "Android release export failed. See $EVIDENCE_PATH"
	exit 1
fi

if [ ! -s "$OUTPUT_APK" ]; then
	echo "Release export result: FAIL - APK missing or empty" >>"$EVIDENCE_PATH"
	echo "Android release export did not create a non-empty APK."
	exit 1
fi

{
	echo "Release export result: PASS"
	echo "APK size: $(du -h "$OUTPUT_APK" | awk '{print $1}')"
	echo "Artifact SHA-256: $(shasum -a 256 "$OUTPUT_APK" | awk '{print $1}')"
	echo
	echo "## Signature Verify"
	echo "Command: $APKSIGNER verify --verbose --print-certs $OUTPUT_APK"
} >>"$EVIDENCE_PATH"

if ! "$APKSIGNER" verify --verbose --print-certs "$OUTPUT_APK" >"$VERIFY_LOG" 2>&1; then
	cat "$VERIFY_LOG" >>"$EVIDENCE_PATH"
	echo "Signature verify result: FAIL" >>"$EVIDENCE_PATH"
	echo "APK signature verification failed. See $EVIDENCE_PATH"
	exit 1
fi

cat "$VERIFY_LOG" >>"$EVIDENCE_PATH"
echo "Signature verify result: PASS" >>"$EVIDENCE_PATH"

{
	echo
	echo "## ADB Devices"
} >>"$EVIDENCE_PATH"
"$ADB" devices >"$ADB_LOG" 2>&1 || true
cat "$ADB_LOG" >>"$EVIDENCE_PATH"

device_count="$(awk 'NR > 1 && $2 == "device" { count++ } END { print count + 0 }' "$ADB_LOG")"
device_serial="$(awk 'NR > 1 && $2 == "device" { print $1; exit }' "$ADB_LOG")"
if [ -n "$device_serial" ]; then
	{
		echo
		echo "ADB device id: $device_serial"
		echo "Device model: $("$ADB" -s "$device_serial" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "unknown")"
		echo "Android version: $("$ADB" -s "$device_serial" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || echo "unknown")"
	} >>"$EVIDENCE_PATH"
else
	echo "ADB device id: BLOCKED - no connected device" >>"$EVIDENCE_PATH"
fi

if [ "$INSTALL" = true ]; then
	{
		echo
		echo "## Install"
		echo "Command: $ADB install -r $OUTPUT_APK"
	} >>"$EVIDENCE_PATH"
	if [ "$device_count" -ne 1 ]; then
		echo "Install result: BLOCKED - expected exactly one connected device, got $device_count" | tee "$INSTALL_LOG" >>"$EVIDENCE_PATH"
		exit 1
	fi
	if ! "$ADB" install -r "$OUTPUT_APK" >"$INSTALL_LOG" 2>&1; then
		cat "$INSTALL_LOG" >>"$EVIDENCE_PATH"
		echo "Install result: FAIL" >>"$EVIDENCE_PATH"
		echo "ADB release install failed. See $EVIDENCE_PATH"
		exit 1
	fi
	cat "$INSTALL_LOG" >>"$EVIDENCE_PATH"
	echo "Install result: PASS" >>"$EVIDENCE_PATH"
	{
		echo
		echo "## Launch"
		echo "Command: $ADB -s $device_serial shell monkey -p $PACKAGE_ID -c android.intent.category.LAUNCHER 1"
	} >>"$EVIDENCE_PATH"
	{
		echo "# Release Run Log"
		echo "Package: $PACKAGE_ID"
		echo "Command: $ADB -s $device_serial shell monkey -p $PACKAGE_ID -c android.intent.category.LAUNCHER 1"
	} >"$RUN_LOG"
	if ! "$ADB" -s "$device_serial" shell monkey -p "$PACKAGE_ID" -c android.intent.category.LAUNCHER 1 >>"$RUN_LOG" 2>&1; then
		cat "$RUN_LOG" >>"$EVIDENCE_PATH"
		echo "Launch result: FAIL" >>"$EVIDENCE_PATH"
		echo "ADB release launch failed. See $EVIDENCE_PATH"
		exit 1
	fi
	sleep 5
	{
		echo
		echo "App pid: $("$ADB" -s "$device_serial" shell pidof "$PACKAGE_ID" 2>/dev/null | tr -d '\r' || true)"
		echo "Window focus:"
		"$ADB" -s "$device_serial" shell dumpsys window 2>/dev/null | tr -d '\r' | grep -E 'mCurrentFocus|mFocusedApp' | head -5 || true
		echo
		echo "Recent fatal logcat lines:"
		"$ADB" -s "$device_serial" logcat -d -t 300 2>/dev/null | tr -d '\r' | grep -Ei 'FATAL EXCEPTION|AndroidRuntime|crash' | tail -20 || true
	} >>"$RUN_LOG"
	if grep -Eiq 'FATAL EXCEPTION|AndroidRuntime|crash' "$RUN_LOG"; then
		cat "$RUN_LOG" >>"$EVIDENCE_PATH"
		echo "Launch result: FAIL - fatal/crash log detected" >>"$EVIDENCE_PATH"
		echo "ADB release launch produced fatal/crash log lines. See $EVIDENCE_PATH"
		exit 1
	fi
	cat "$RUN_LOG" >>"$EVIDENCE_PATH"
	echo "Launch result: PASS" | tee -a "$RUN_LOG" >>"$EVIDENCE_PATH"
else
	echo "Install result: NOT_REQUESTED - connected devices: $device_count" >>"$EVIDENCE_PATH"
	echo "Launch result: NOT_REQUESTED - install not requested" >>"$EVIDENCE_PATH"
fi

echo "Android release export evidence: $EVIDENCE_PATH"
echo "APK: $OUTPUT_APK"
