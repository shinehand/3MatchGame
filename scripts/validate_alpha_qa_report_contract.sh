#!/bin/zsh
set -euo pipefail
setopt null_glob

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TEMPLATE_PATH="docs/qa/templates/alpha-lock-pass-manual-qa-template.md"
VALIDATOR="scripts/validate_alpha_qa_report.sh"
HEAD_COMMIT="$(git rev-parse HEAD)"
TODAY="$(date +%Y-%m-%d)"
FIXTURE_ROOT="output/alpha-lock-pass/contract-smoke"
DEBUG_APK="build/android/zoo-zoo-pop-debug.apk"
RELEASE_APK="build/android/zoo-zoo-pop-release.apk"

created_build_files=()

cleanup() {
	if [ "${KEEP_ALPHA_QA_CONTRACT_FIXTURE:-false}" = "true" ]; then
		return
	fi
	rm -rf "$FIXTURE_ROOT"
	for created_file in "${created_build_files[@]}"; do
		rm -f "$created_file"
	done
	for artifact in "$DEBUG_APK" "$RELEASE_APK"; do
		if [ -f "$artifact" ] && grep -Fq "contract fixture artifact" "$artifact" 2>/dev/null; then
			rm -f "$artifact"
		fi
	done
}
trap cleanup EXIT

fail() {
	echo "Alpha QA report contract validation failed: $1"
	exit 1
}

ensure_build_artifact() {
	local target_path="$1"
	if [ -s "$target_path" ]; then
		return
	fi
	mkdir -p "$(dirname "$target_path")"
	printf "contract fixture artifact: %s\n" "$target_path" >"$target_path"
	created_build_files+=("$target_path")
}

write_generic_evidence() {
	local target_path="$1"
	if [ -s "$target_path" ]; then
		return
	fi
	mkdir -p "$(dirname "$target_path")"
	printf "Contract fixture evidence: %s\nResult: PASS\n" "$target_path" >"$target_path"
}

write_known_evidence() {
	local captures_dir="$1"
	cat >"$captures_dir/android-debug-export.txt" <<EOF
# Android Debug Export Evidence
Export result: PASS
Signature verify result: PASS
Install result: PASS
EOF

	cat >"$captures_dir/android-release-export.txt" <<EOF
# Android Release Export Evidence
Signing mode: release
Release export result: PASS
Artifact SHA-256: contract-fixture-sha256
Signature verify result: PASS
Install result: PASS
Launch result: PASS
EOF

	cat >"$captures_dir/android-device-evidence.txt" <<EOF
# Android Device Evidence
Capture result: PASS
Launch result: PASS
Portrait screenshot result: PASS
Landscape screenshot result: PASS
Screenrecord result: PASS
Logcat result: PASS
EOF

	cat >"$captures_dir/device-info.txt" <<EOF
ADB device id: contract-device-001
Model: Contract Fixture Phone
Android version: 15
Window size: 1080x1920
EOF

	cat >"$captures_dir/install-log.txt" <<EOF
Success
EOF
	cat >"$captures_dir/release-install-log.txt" <<EOF
Success
EOF
	cat >"$captures_dir/release-run-log.txt" <<EOF
Launch result: PASS
EOF

	cat >"$captures_dir/manual-device-checks.txt" <<EOF
Manual checks result: PASS
Test timestamp: ${TODAY}T00:00:00+0000
Build source commit: $HEAD_COMMIT
Build artifact: $DEBUG_APK
Tester: Contract Fixture
Device: Contract Fixture Phone
OS version: Android 15
Sound result: PASS
Haptics result: PASS
Touch result: PASS
EOF

	for note_file in sound-toggle-notes.md haptics-toggle-notes.md touch-latency-notes.md; do
		cat >"$captures_dir/$note_file" <<EOF
# ${note_file}
Manual result: PASS
Test timestamp: ${TODAY}T00:00:00+0000
Build source commit: $HEAD_COMMIT
Build artifact: $DEBUG_APK
Tester: Contract Fixture
Device: Contract Fixture Phone
OS version: Android 15
Scenario checked: ${note_file}
Note: Contract fixture PASS note.
EOF
	done
}

materialize_report_paths() {
	local report_path="$1"
	while IFS= read -r path_token; do
		path_token="${path_token#\`}"
		path_token="${path_token%\`}"
		case "$path_token" in
			output/alpha-lock-pass/*|build/android/*)
				if [[ "$path_token" == *"*"* ]]; then
					write_generic_evidence "${path_token/\*/txt}"
				else
					write_generic_evidence "$path_token"
				fi
				;;
		esac
	done < <(grep -Eo '`(output/alpha-lock-pass/[^`]+|build/android/[^`]+)`' "$report_path" || true)
}

make_pass_fixture() {
	local fixture_id="$1"
	local fixture_dir="$FIXTURE_ROOT/$fixture_id"
	local captures_dir="$fixture_dir/captures"
	local report_path="$fixture_dir/alpha-lock-pass-manual-qa-$fixture_id.md"

	rm -rf "$fixture_dir"
	mkdir -p "$captures_dir"
	cp "$TEMPLATE_PATH" "$report_path"

	perl -0pi -e "s/YYYY-MM-DD/contract-smoke\\/\\Q$fixture_id\\E/g" "$report_path"
	perl -0pi -e "s/^- QA date:\\s*$/- QA date: $TODAY/m" "$report_path"
	perl -0pi -e "s/^- Build source commit:\\s*$/- Build source commit: $HEAD_COMMIT/m" "$report_path"
	perl -0pi -e "s|^- Build artifact path:\\s*\$|- Build artifact path: $DEBUG_APK|m" "$report_path"
	perl -0pi -e "s/^- Device:\\s*$/- Device: Contract Fixture Phone/m" "$report_path"
	perl -0pi -e "s/^- OS version:\\s*$/- OS version: Android 15/m" "$report_path"
	perl -0pi -e "s/^- Orientation checked:.*$/- Orientation checked: both/m" "$report_path"
	perl -0pi -e "s/^- Tester:\\s*$/- Tester: Contract Fixture/m" "$report_path"
	perl -0pi -e "s/^- Overall result:.*$/- Overall result: Pass/m" "$report_path"
	perl -0pi -e "s/^- QA result:.*$/- QA result: Approve/m" "$report_path"
	perl -0pi -e "s/^- Approval notes:\\s*$/- Approval notes: Contract smoke approved./m" "$report_path"
	perl -0pi -e "s/^- Re-test required:\\s*$/- Re-test required: No/m" "$report_path"
	perl -0pi -e "s/^- Android real-device sound playback:\\s*$/- Android real-device sound playback: PASS evidence attached/m" "$report_path"
	perl -0pi -e "s/^- Android real-device haptics and ON\\/OFF setting:\\s*$/- Android real-device haptics and ON\\/OFF setting: PASS evidence attached/m" "$report_path"
	perl -0pi -e "s/^- Touch latency and gesture feel:\\s*$/- Touch latency and gesture feel: PASS evidence attached/m" "$report_path"
	perl -0pi -e "s/^- Physical portrait viewport HUD\\/board\\/CTA readability:\\s*$/- Physical portrait viewport HUD\\/board\\/CTA readability: PASS evidence attached/m" "$report_path"
	perl -0pi -e "s/^- Release signed build install\\/run:\\s*$/- Release signed build install\\/run: PASS evidence attached/m" "$report_path"
	perl -0pi -e "s/(?<=\\|) Pending (?=\\|)/ Pass /g; s/(?<=\\|) Open (?=\\|)/ Resolved /g" "$report_path"

	ensure_build_artifact "$DEBUG_APK"
	ensure_build_artifact "$RELEASE_APK"
	materialize_report_paths "$report_path"
	write_known_evidence "$captures_dir"

	print -r -- "$report_path"
}

expect_success() {
	local report_path="$1"
	local output_path="$FIXTURE_ROOT/success.out"
	if ! zsh "$VALIDATOR" --report="$report_path" >"$output_path" 2>&1; then
		cat "$output_path"
		fail "expected PASS fixture to validate"
	fi
}

expect_failure() {
	local label="$1"
	local report_path="$2"
	local output_path="$FIXTURE_ROOT/${label}.out"
	if zsh "$VALIDATOR" --report="$report_path" >"$output_path" 2>&1; then
		cat "$output_path"
		fail "negative fixture unexpectedly passed: $label"
	fi
}

rm -rf "$FIXTURE_ROOT"
mkdir -p "$FIXTURE_ROOT"

pass_report="$(make_pass_fixture pass)"
expect_success "$pass_report"

pending_report="$(make_pass_fixture pending)"
perl -0pi -e 's/\| Gameplay validation \|([^|]+)\| Pass \|/| Gameplay validation |$1| Pending |/' "$pending_report"
expect_failure "pending" "$pending_report"

missing_report="$(make_pass_fixture missing-evidence)"
rm -f "$FIXTURE_ROOT/missing-evidence/captures/install-log.txt"
expect_failure "missing-evidence" "$missing_report"

missing_cosmetic_report="$(make_pass_fixture missing-cosmetic-row)"
perl -0pi -e 's/^\| RESCUE_BOOK_COSMETIC_EQUIP \|.*\n//m' "$missing_cosmetic_report"
expect_failure "missing-cosmetic-row" "$missing_cosmetic_report"

wrong_commit_report="$(make_pass_fixture wrong-commit)"
perl -0pi -e 's/^- Build source commit:.*$/- Build source commit: deadbeef/m' "$wrong_commit_report"
expect_failure "wrong-commit" "$wrong_commit_report"

blocked_device_report="$(make_pass_fixture blocked-device)"
perl -0pi -e 's/Capture result: PASS/Capture result: BLOCKED/' "$FIXTURE_ROOT/blocked-device/captures/android-device-evidence.txt"
expect_failure "blocked-device" "$blocked_device_report"

not_requested_release_report="$(make_pass_fixture not-requested-release)"
perl -0pi -e 's/Install result: PASS/Install result: NOT_REQUESTED/' "$FIXTURE_ROOT/not-requested-release/captures/android-release-export.txt"
expect_failure "not-requested-release" "$not_requested_release_report"

echo "Alpha QA report contract validation passed."
