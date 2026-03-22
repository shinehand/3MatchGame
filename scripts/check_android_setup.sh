#!/bin/zsh

set -euo pipefail

JAVA_PATH="${JAVA_HOME:-/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
SDK_PATH="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
GODOT_TEMPLATES_PATH="$HOME/Library/Application Support/Godot/export_templates/4.6.1.stable"
KEYSTORE_PATH="$HOME/Library/Application Support/Godot/keystores/debug.keystore"

print_status() {
	local label="$1"
	local value="$2"
	printf "%-18s %s\n" "${label}:" "${value}"
}

check_path() {
	local label="$1"
	local path="$2"
	if [ -e "$path" ]; then
		print_status "$label" "$path"
	else
		print_status "$label" "MISSING -> $path"
		return 1
	fi
}

exit_code=0

print_status "Godot" "$(godot --version)"
check_path "JAVA_HOME" "$JAVA_PATH" || exit_code=1
check_path "ANDROID_HOME" "$SDK_PATH" || exit_code=1
check_path "ADB" "$SDK_PATH/platform-tools/adb" || exit_code=1
check_path "Build Tools" "$SDK_PATH/build-tools/35.0.1" || exit_code=1
check_path "Platform 35" "$SDK_PATH/platforms/android-35" || exit_code=1
check_path "Templates" "$GODOT_TEMPLATES_PATH/version.txt" || exit_code=1
check_path "Keystore" "$KEYSTORE_PATH" || exit_code=1

exit "$exit_code"
