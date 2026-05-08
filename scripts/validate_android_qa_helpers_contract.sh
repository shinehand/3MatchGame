#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
source scripts/godot_validation_env.sh
validation_require_godot

FIXTURE_ROOT="${TMPDIR:-/tmp}/puzzle-android-qa-helper-contract.$$"

cleanup() {
	if [ "${KEEP_ANDROID_QA_HELPER_CONTRACT_FIXTURE:-false}" = "true" ]; then
		return
	fi
	rm -rf "$FIXTURE_ROOT"
}
trap cleanup EXIT

fail() {
	echo "Android QA helper contract validation failed: $1"
	exit 1
}

output_for() {
	print -r -- "$FIXTURE_ROOT/$1.out"
}

expect_success() {
	local label="$1"
	shift
	local output_path
	output_path="$(output_for "$label")"
	if ! "$@" >"$output_path" 2>&1; then
		cat "$output_path"
		fail "expected success: $label"
	fi
}

expect_failure() {
	local label="$1"
	shift
	local output_path
	output_path="$(output_for "$label")"
	if "$@" >"$output_path" 2>&1; then
		cat "$output_path"
		fail "expected failure: $label"
	fi
}

assert_contains() {
	local label="$1"
	local expected="$2"
	local output_path
	output_path="$(output_for "$label")"
	if ! grep -Fq -- "$expected" "$output_path"; then
		cat "$output_path"
		fail "$label output missing: $expected"
	fi
}

assert_not_contains() {
	local label="$1"
	local forbidden="$2"
	local output_path
	output_path="$(output_for "$label")"
	if grep -Fq -- "$forbidden" "$output_path"; then
		cat "$output_path"
		fail "$label output leaked forbidden text"
	fi
}

assert_not_exists() {
	local target_path="$1"
	if [ -e "$target_path" ]; then
		fail "dry-run unexpectedly created: $target_path"
	fi
}

mkdir -p "$FIXTURE_ROOT"

debug_apk="$FIXTURE_ROOT/zoo-zoo-pop-debug.apk"
release_apk="$FIXTURE_ROOT/zoo-zoo-pop-release.apk"
capture_dir="$FIXTURE_ROOT/captures"
manual_dir="$FIXTURE_ROOT/manual"
release_keystore="$FIXTURE_ROOT/release.keystore"
legacy_keystore="$FIXTURE_ROOT/legacy-release.keystore"
release_secret="contract-release-secret-${RANDOM}-$$"
legacy_secret="contract-legacy-secret-${RANDOM}-$$"

printf "contract release keystore placeholder\n" >"$release_keystore"
printf "contract legacy release keystore placeholder\n" >"$legacy_keystore"

expect_success "debug-dry-run" \
	zsh scripts/export_android_debug.sh --output="$debug_apk" --dry-run
assert_contains "debug-dry-run" "Android debug export dry-run"
assert_contains "debug-dry-run" "Output APK: $debug_apk"
assert_contains "debug-dry-run" "Dry-run scope: CLI contract only; no APK export, signature verification, install, or device evidence."
assert_not_exists "$debug_apk"

expect_success "device-dry-run" \
	zsh scripts/capture_android_device_evidence.sh --output-dir="$capture_dir" --video-seconds=10 --skip-launch --no-rotate --dry-run
assert_contains "device-dry-run" "Android device evidence dry-run"
assert_contains "device-dry-run" "Capture dir: $capture_dir"
assert_contains "device-dry-run" "10s video: $capture_dir/device-10s.mp4"
assert_not_exists "$capture_dir/android-device-evidence.txt"

expect_success "manual-dry-run" \
	zsh scripts/record_manual_device_checks.sh \
		--tester=Validation \
		--device=NoDevice \
		--os=0 \
		--sound=PASS \
		--haptics=PASS \
		--touch=PASS \
		--sound-note="dry run" \
		--haptics-note="dry run" \
		--touch-note="dry run" \
		--artifact="$debug_apk" \
		--output-dir="$manual_dir" \
		--dry-run
assert_contains "manual-dry-run" "Manual device checks dry-run"
assert_contains "manual-dry-run" "Manifest: $manual_dir/manual-device-checks.txt"
assert_not_exists "$manual_dir/manual-device-checks.txt"

expect_success "release-dry-run" \
	env \
		GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$release_keystore" \
		GODOT_ANDROID_KEYSTORE_RELEASE_USER=validation \
		GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$release_secret" \
		zsh scripts/export_android_release.sh --output="$release_apk" --dry-run
assert_contains "release-dry-run" "Android release export dry-run"
assert_contains "release-dry-run" "Output APK: $release_apk"
assert_contains "release-dry-run" "Release keystore path: $release_keystore"
assert_contains "release-dry-run" "Release keystore user: validation"
assert_contains "release-dry-run" "Release keystore password: SET"
assert_not_contains "release-dry-run" "$release_secret"
assert_not_exists "$release_apk"

expect_success "release-legacy-dry-run" \
	env \
		GODOT_RELEASE_KEYSTORE_PATH="$legacy_keystore" \
		GODOT_RELEASE_KEYSTORE_USER=legacy \
		GODOT_RELEASE_KEYSTORE_PASSWORD="$legacy_secret" \
		zsh scripts/export_android_release.sh --dry-run
assert_contains "release-legacy-dry-run" "Release keystore path: $legacy_keystore"
assert_contains "release-legacy-dry-run" "Release keystore user: legacy"
assert_contains "release-legacy-dry-run" "Release keystore password: SET"
assert_not_contains "release-legacy-dry-run" "$legacy_secret"

expect_failure "release-missing-env" \
	zsh -c 'unset GODOT_ANDROID_KEYSTORE_RELEASE_PATH GODOT_ANDROID_KEYSTORE_RELEASE_USER GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD GODOT_RELEASE_KEYSTORE_PATH GODOT_RELEASE_KEYSTORE_USER GODOT_RELEASE_KEYSTORE_PASSWORD; zsh scripts/export_android_release.sh --dry-run'
assert_contains "release-missing-env" "Dry-run release input failures:"
assert_contains "release-missing-env" "missing GODOT_ANDROID_KEYSTORE_RELEASE_PATH or GODOT_RELEASE_KEYSTORE_PATH"
assert_contains "release-missing-env" "missing GODOT_ANDROID_KEYSTORE_RELEASE_USER or GODOT_RELEASE_KEYSTORE_USER"
assert_contains "release-missing-env" "missing GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD or GODOT_RELEASE_KEYSTORE_PASSWORD"

expect_failure "debug-empty-output" \
	zsh scripts/export_android_debug.sh --output= --dry-run
assert_contains "debug-empty-output" "Output APK path is empty."

expect_failure "release-empty-output" \
	env \
		GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$release_keystore" \
		GODOT_ANDROID_KEYSTORE_RELEASE_USER=validation \
		GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$release_secret" \
		zsh scripts/export_android_release.sh --output= --dry-run
assert_contains "release-empty-output" "Output APK path is empty."

expect_failure "release-empty-preset" \
	env \
		GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$release_keystore" \
		GODOT_ANDROID_KEYSTORE_RELEASE_USER=validation \
		GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$release_secret" \
		zsh scripts/export_android_release.sh --preset= --dry-run
assert_contains "release-empty-preset" "Export preset name is empty."

expect_failure "device-empty-package" \
	zsh scripts/capture_android_device_evidence.sh --package= --dry-run
assert_contains "device-empty-package" "Android package id is empty."

expect_failure "device-empty-output-dir" \
	zsh scripts/capture_android_device_evidence.sh --output-dir= --dry-run
assert_contains "device-empty-output-dir" "Capture output dir is empty."

expect_failure "device-video-zero" \
	zsh scripts/capture_android_device_evidence.sh --video-seconds=0 --dry-run
assert_contains "device-video-zero" "Invalid --video-seconds value: 0"

expect_failure "device-video-too-long" \
	zsh scripts/capture_android_device_evidence.sh --video-seconds=181 --dry-run
assert_contains "device-video-too-long" "Invalid --video-seconds value: 181"

expect_failure "manual-missing-tester" \
	zsh scripts/record_manual_device_checks.sh \
		--device=NoDevice \
		--os=0 \
		--sound=PASS \
		--haptics=PASS \
		--touch=PASS \
		--sound-note="dry run" \
		--haptics-note="dry run" \
		--touch-note="dry run" \
		--dry-run
assert_contains "manual-missing-tester" "missing --tester"

expect_failure "manual-invalid-sound" \
	zsh scripts/record_manual_device_checks.sh \
		--tester=Validation \
		--device=NoDevice \
		--os=0 \
		--sound=MAYBE \
		--haptics=PASS \
		--touch=PASS \
		--sound-note="dry run" \
		--haptics-note="dry run" \
		--touch-note="dry run" \
		--dry-run
assert_contains "manual-invalid-sound" "missing --sound PASS|FAIL|BLOCKED"

expect_failure "manual-empty-output-dir" \
	zsh scripts/record_manual_device_checks.sh \
		--tester=Validation \
		--device=NoDevice \
		--os=0 \
		--sound=PASS \
		--haptics=PASS \
		--touch=PASS \
		--sound-note="dry run" \
		--haptics-note="dry run" \
		--touch-note="dry run" \
		--output-dir= \
		--dry-run
assert_contains "manual-empty-output-dir" "missing --output-dir"

expect_failure "debug-unknown-option" \
	zsh scripts/export_android_debug.sh --unknown-option --dry-run
assert_contains "debug-unknown-option" "Unknown option: --unknown-option"

expect_failure "release-unknown-option" \
	zsh scripts/export_android_release.sh --unknown-option --dry-run
assert_contains "release-unknown-option" "Unknown option: --unknown-option"

expect_failure "device-unknown-option" \
	zsh scripts/capture_android_device_evidence.sh --unknown-option --dry-run
assert_contains "device-unknown-option" "Unknown option: --unknown-option"

expect_failure "manual-unknown-option" \
	zsh scripts/record_manual_device_checks.sh --unknown-option --dry-run
assert_contains "manual-unknown-option" "Unknown option: --unknown-option"

echo "Android QA helper contract validation passed."
