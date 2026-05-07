#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

EXPORT_PRESETS_PATH="export_presets.cfg"
PROJECT_CONFIG_PATH="project.godot"
EXPECTED_APP_NAME="${EXPECTED_ANDROID_APP_NAME:-Zoo-Zoo Pop}"
EXPECTED_PACKAGE_ID="${EXPECTED_ANDROID_PACKAGE_ID:-com.shinehandmac.zoozoopop}"
EXPECTED_EXPORT_PATH="${EXPECTED_ANDROID_EXPORT_PATH:-build/android/zoo-zoo-pop-debug.apk}"

failures=()

add_failure() {
	failures+=("$1")
}

read_cfg_value() {
	local target_path="$1"
	local key="$2"
	awk -v key="$key" -F= '$1 == key {
		value = $0
		sub("^[^=]+=", "", value)
		gsub(/^"/, "", value)
		gsub(/"$/, "", value)
		print value
		exit
	}' "$target_path"
}

require_file() {
	local target_path="$1"
	if [ ! -f "$target_path" ]; then
		add_failure "missing $target_path"
		return 1
	fi
	return 0
}

require_equals() {
	local label="$1"
	local actual="$2"
	local expected="$3"
	if [ "$actual" != "$expected" ]; then
		add_failure "$label must be '$expected', got '${actual:-MISSING}'"
	fi
}

require_true() {
	local label="$1"
	local actual="$2"
	if [ "$actual" != "true" ]; then
		add_failure "$label must be true, got '${actual:-MISSING}'"
	fi
}

if require_file "$EXPORT_PRESETS_PATH"; then
	if ! grep -q '^platform="Android"$' "$EXPORT_PRESETS_PATH"; then
		add_failure "Android export preset is missing"
	fi
	if ! grep -q '^name="Android"$' "$EXPORT_PRESETS_PATH"; then
		add_failure "Android export preset name must be 'Android'"
	fi
fi

if ! require_file "$PROJECT_CONFIG_PATH"; then
	:
fi

if [ "${#failures[@]}" -gt 0 ]; then
	echo "Android export config validation failed."
	for failure in "${failures[@]}"; do
		echo "- $failure"
	done
	exit 1
fi

project_name="$(read_cfg_value "$PROJECT_CONFIG_PATH" "config/name")"
export_path="$(read_cfg_value "$EXPORT_PRESETS_PATH" "export_path")"
version_code="$(read_cfg_value "$EXPORT_PRESETS_PATH" "version/code")"
version_name="$(read_cfg_value "$EXPORT_PRESETS_PATH" "version/name")"
package_id="$(read_cfg_value "$EXPORT_PRESETS_PATH" "package/unique_name")"
package_name="$(read_cfg_value "$EXPORT_PRESETS_PATH" "package/name")"
package_signed="$(read_cfg_value "$EXPORT_PRESETS_PATH" "package/signed")"
permission_vibrate="$(read_cfg_value "$EXPORT_PRESETS_PATH" "permissions/vibrate")"
arm64_enabled="$(read_cfg_value "$EXPORT_PRESETS_PATH" "architectures/arm64-v8a")"

require_equals "project.godot config/name" "$project_name" "$EXPECTED_APP_NAME"
require_equals "Android export_path" "$export_path" "$EXPECTED_EXPORT_PATH"
require_equals "Android package/unique_name" "$package_id" "$EXPECTED_PACKAGE_ID"
require_equals "Android package/name" "$package_name" "$EXPECTED_APP_NAME"
require_true "Android package/signed" "$package_signed"
require_true "Android permissions/vibrate" "$permission_vibrate"
require_true "Android architectures/arm64-v8a" "$arm64_enabled"

if [[ ! "$version_code" =~ '^[0-9]+$' ]] || [ "${version_code:-0}" -lt 1 ]; then
	add_failure "Android version/code must be a positive integer, got '${version_code:-MISSING}'"
fi

if [[ ! "$version_name" =~ '^[0-9]+\.[0-9]+\.[0-9]+([-.+][0-9A-Za-z.-]+)?$' ]]; then
	add_failure "Android version/name must be SemVer-like, got '${version_name:-MISSING}'"
fi

if [[ "$export_path" == *"starter"* ]] || [[ "$export_path" == *"puzzle-mobile-starter"* ]]; then
	add_failure "Android export_path still looks like a starter placeholder: $export_path"
fi

if [[ "$package_name" == *"Starter"* ]] || [[ "$package_id" == *".puzzle" ]]; then
	add_failure "Android package identity still looks like a starter placeholder"
fi

if [ "${#failures[@]}" -gt 0 ]; then
	echo "Android export config validation failed."
	for failure in "${failures[@]}"; do
		echo "- $failure"
	done
	exit 1
fi

echo "Android export config validation passed."
echo "App name: $package_name"
echo "Package id: $package_id"
echo "Version: $version_name ($version_code)"
echo "Debug export path: $export_path"
