#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_APK="build/android/puzzle-mobile-starter-debug.apk"
INSTALL=false
DRY_RUN=false

for arg in "$@"; do
	case "$arg" in
		--install)
			INSTALL=true
			;;
		--output=*)
			OUTPUT_APK="${arg#--output=}"
			;;
		--dry-run)
			DRY_RUN=true
			;;
		-h|--help)
			echo "Usage: $0 [--install] [--output=path/to/app.apk] [--dry-run]"
			echo "Exports the Android debug APK, verifies its signature, and writes alpha QA evidence."
			exit 0
			;;
		*)
			echo "Unknown option: $arg"
			echo "Usage: $0 [--install] [--output=path/to/app.apk] [--dry-run]"
			exit 2
			;;
	esac
done

TODAY="$(date +%Y-%m-%d)"
CAPTURE_DIR="output/alpha-lock-pass/$TODAY/captures"
EVIDENCE_PATH="$CAPTURE_DIR/android-debug-export.txt"
EXPORT_LOG="build/android/export-debug.log"
VERIFY_LOG="build/android/apksigner-verify-debug.log"
ADB_LOG="build/android/adb-devices.log"
INSTALL_LOG="$CAPTURE_DIR/install-log.txt"

SDK_PATH="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
BUILD_TOOLS_VERSION="${ANDROID_BUILD_TOOLS_VERSION:-35.0.1}"
APKSIGNER="$SDK_PATH/build-tools/$BUILD_TOOLS_VERSION/apksigner"
ADB="$SDK_PATH/platform-tools/adb"
DEBUG_KEYSTORE_PATH="$HOME/Library/Application Support/Godot/keystores/debug.keystore"
EXPORT_PRESET_NAME="Android"

if [ "$DRY_RUN" = true ]; then
	echo "Android debug export dry-run"
	echo "Output APK: $OUTPUT_APK"
	echo "Preset: $EXPORT_PRESET_NAME"
	echo "Install requested: $INSTALL"
	echo "Evidence: $EVIDENCE_PATH"
	echo "SDK path: $SDK_PATH"
	echo "Build tools version: $BUILD_TOOLS_VERSION"
	echo "apksigner: $APKSIGNER"
	echo "adb: $ADB"
	echo "Debug keystore path: $DEBUG_KEYSTORE_PATH"
	echo "Dry-run scope: CLI contract only; no APK export, signature verification, install, or device evidence."
	exit 0
fi

GODOT_VERSION="$(godot --version)"

mkdir -p "$(dirname "$OUTPUT_APK")" "$CAPTURE_DIR"
rm -f "$OUTPUT_APK" "$EXPORT_LOG" "$VERIFY_LOG" "$ADB_LOG" "$EVIDENCE_PATH"

{
	echo "# Android Debug Export Evidence"
	echo
	echo "Date: $TODAY"
	echo "Commit: $(git rev-parse --short HEAD)"
	echo "Godot version: $GODOT_VERSION"
	echo "Export preset: $EXPORT_PRESET_NAME"
	echo "Signing mode: debug"
	echo "Keystore path: $DEBUG_KEYSTORE_PATH"
	echo "APK: $OUTPUT_APK"
	echo "Install requested: $INSTALL"
	echo "Tester: Pending"
	echo "Export log path: $EXPORT_LOG"
	echo "Signature verify log path: $VERIFY_LOG"
	echo
	echo "## Android Setup"
} >"$EVIDENCE_PATH"

zsh scripts/check_android_setup.sh >>"$EVIDENCE_PATH"

if [ ! -x "$APKSIGNER" ]; then
	echo "apksigner missing or not executable: $APKSIGNER" >>"$EVIDENCE_PATH"
	echo "Android debug export failed: missing apksigner."
	exit 1
fi

if [ ! -x "$ADB" ]; then
	echo "adb missing or not executable: $ADB" >>"$EVIDENCE_PATH"
	echo "Android debug export failed: missing adb."
	exit 1
fi

{
	echo
	echo "## Export"
	echo "Command: godot --headless --path . --export-debug $EXPORT_PRESET_NAME $OUTPUT_APK"
} >>"$EVIDENCE_PATH"

if ! godot --headless --path . --export-debug "$EXPORT_PRESET_NAME" "$OUTPUT_APK" >"$EXPORT_LOG" 2>&1; then
	cat "$EXPORT_LOG" >>"$EVIDENCE_PATH"
	echo "Export result: FAIL" >>"$EVIDENCE_PATH"
	echo "Android debug export failed. See $EVIDENCE_PATH"
	exit 1
fi

if [ ! -s "$OUTPUT_APK" ]; then
	echo "Export result: FAIL - APK missing or empty" >>"$EVIDENCE_PATH"
	echo "Android debug export did not create a non-empty APK."
	exit 1
fi

{
	echo "Export result: PASS"
	echo "APK size: $(du -h "$OUTPUT_APK" | awk '{print $1}')"
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
		echo "ADB install failed. See $EVIDENCE_PATH"
		exit 1
	fi
	cat "$INSTALL_LOG" >>"$EVIDENCE_PATH"
	echo "Install result: PASS" >>"$EVIDENCE_PATH"
else
	echo "Install result: NOT_REQUESTED - connected devices: $device_count" >>"$EVIDENCE_PATH"
fi

echo "Android debug export evidence: $EVIDENCE_PATH"
echo "APK: $OUTPUT_APK"
