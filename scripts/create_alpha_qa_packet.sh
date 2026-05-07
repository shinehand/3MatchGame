#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_PATH="$ROOT_DIR/docs/qa/templates/alpha-lock-pass-manual-qa-template.md"
TODAY="$(date +%Y-%m-%d)"
OUTPUT_ROOT="$ROOT_DIR/output/alpha-lock-pass/$TODAY"
CAPTURE_DIR="$OUTPUT_ROOT/captures"
REPORT_PATH="$OUTPUT_ROOT/alpha-lock-pass-manual-qa-$TODAY.md"
DRY_RUN=false

for arg in "$@"; do
	case "$arg" in
		--dry-run)
			DRY_RUN=true
			;;
		-h|--help)
			echo "Usage: $0 [--dry-run]"
			echo "Creates output/alpha-lock-pass/YYYY-MM-DD with a QA report template and captures directory."
			exit 0
			;;
		*)
			echo "Unknown option: $arg"
			echo "Usage: $0 [--dry-run]"
			exit 2
			;;
	esac
done

if [ ! -f "$TEMPLATE_PATH" ]; then
	echo "Missing template: $TEMPLATE_PATH"
	exit 1
fi

if [ "$DRY_RUN" = true ]; then
	echo "Would create: $OUTPUT_ROOT"
	echo "Would create: $CAPTURE_DIR"
	echo "Would write:  $REPORT_PATH"
	exit 0
fi

mkdir -p "$CAPTURE_DIR"
if [ -e "$REPORT_PATH" ]; then
	echo "QA packet already exists: $REPORT_PATH"
	exit 1
fi

sed "s/YYYY-MM-DD/$TODAY/g" "$TEMPLATE_PATH" > "$REPORT_PATH"
echo "Alpha QA packet created:"
echo "  report:   $REPORT_PATH"
echo "  captures: $CAPTURE_DIR"
