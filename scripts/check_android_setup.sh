#!/bin/zsh

set -euo pipefail

CHECK_RELEASE=false
for arg in "$@"; do
	case "$arg" in
		--release)
			CHECK_RELEASE=true
			;;
		-h|--help)
			echo "Usage: $0 [--release]"
			echo "  --release  Also require release keystore and Android signing tools."
			exit 0
			;;
		*)
			echo "Unknown option: $arg"
			echo "Usage: $0 [--release]"
			exit 2
			;;
	esac
done

JAVA_PATH="${JAVA_HOME:-/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
SDK_PATH="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
BUILD_TOOLS_VERSION="${ANDROID_BUILD_TOOLS_VERSION:-35.0.1}"
BUILD_TOOLS_PATH="$SDK_PATH/build-tools/$BUILD_TOOLS_VERSION"
GODOT_TEMPLATES_PATH="$HOME/Library/Application Support/Godot/export_templates/4.6.1.stable"
DEBUG_KEYSTORE_PATH="$HOME/Library/Application Support/Godot/keystores/debug.keystore"
RELEASE_KEYSTORE_PATH="${GODOT_RELEASE_KEYSTORE_PATH:-}"
EXPORT_PRESETS_PATH="export_presets.cfg"

print_status() {
	local label="$1"
	local value="$2"
	printf "%-18s %s\n" "${label}:" "${value}"
}

check_path() {
	local label="$1"
	local target_path="$2"
	if [ -e "$target_path" ]; then
		print_status "$label" "$target_path"
	else
		print_status "$label" "MISSING -> $target_path"
		return 1
	fi
}

check_file_contains() {
	local label="$1"
	local target_path="$2"
	local pattern="$3"
	if grep -q "$pattern" "$target_path"; then
		print_status "$label" "OK"
	else
		print_status "$label" "MISSING -> $pattern"
		return 1
	fi
}

exit_code=0

print_status "Godot" "$(godot --version)"
check_path "JAVA_HOME" "$JAVA_PATH" || exit_code=1
check_path "ANDROID_HOME" "$SDK_PATH" || exit_code=1
check_path "ADB" "$SDK_PATH/platform-tools/adb" || exit_code=1
check_path "Build Tools" "$BUILD_TOOLS_PATH" || exit_code=1
check_path "Platform 35" "$SDK_PATH/platforms/android-35" || exit_code=1
check_path "Templates" "$GODOT_TEMPLATES_PATH/version.txt" || exit_code=1
check_path "Debug Keystore" "$DEBUG_KEYSTORE_PATH" || exit_code=1
check_path "Export Presets" "$EXPORT_PRESETS_PATH" || exit_code=1
if [ -f "$EXPORT_PRESETS_PATH" ]; then
	check_file_contains "Android Preset" "$EXPORT_PRESETS_PATH" '^platform="Android"$' || exit_code=1
	check_file_contains "ARM64 ABI" "$EXPORT_PRESETS_PATH" '^architectures/arm64-v8a=true$' || exit_code=1
	check_file_contains "VIBRATE Permission" "$EXPORT_PRESETS_PATH" '^permissions/vibrate=true$' || exit_code=1
	check_file_contains "Signed Package" "$EXPORT_PRESETS_PATH" '^package/signed=true$' || exit_code=1
fi

if [ "$CHECK_RELEASE" = true ]; then
	check_path "zipalign" "$BUILD_TOOLS_PATH/zipalign" || exit_code=1
	check_path "apksigner" "$BUILD_TOOLS_PATH/apksigner" || exit_code=1
	if [ -z "$RELEASE_KEYSTORE_PATH" ]; then
		print_status "Release Keystore" "MISSING -> set GODOT_RELEASE_KEYSTORE_PATH"
		exit_code=1
	else
		check_path "Release Keystore" "$RELEASE_KEYSTORE_PATH" || exit_code=1
	fi
fi

exit "$exit_code"
