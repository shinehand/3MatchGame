#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

mkdir -p assets/animals assets/backgrounds assets/effects

render_svg() {
	local svg_path="$1"
	local out_path="$2"
	local width="$3"
	local height="$4"

	"$CHROME" \
		--headless \
		--disable-gpu \
		--default-background-color=00000000 \
		--window-size="${width},${height}" \
		--screenshot="/Users/shinehandmac/Documents/puzzle/${out_path}" \
		"file:///Users/shinehandmac/Documents/puzzle/${svg_path}" >/dev/null 2>&1
}

render_svg "assets/animals/rabbit_block_v2.svg" "assets/animals/rabbit_block_v2.png" 256 256
render_svg "assets/animals/bear_block_v2.svg" "assets/animals/bear_block_v2.png" 256 256
render_svg "assets/animals/cat_block_v2.svg" "assets/animals/cat_block_v2.png" 256 256
render_svg "assets/animals/chick_block_v2.svg" "assets/animals/chick_block_v2.png" 256 256
render_svg "assets/animals/frog_block_v2.svg" "assets/animals/frog_block_v2.png" 256 256
render_svg "assets/backgrounds/stage_meadow_bg_v2.svg" "assets/backgrounds/stage_meadow_bg_v2.png" 1920 1080
render_svg "assets/effects/bush_obstacle_v2.svg" "assets/effects/bush_obstacle_v2.png" 256 256
render_svg "assets/effects/match_burst_v2.svg" "assets/effects/match_burst_v2.png" 256 256

echo "Rasterized SVG assets to PNG."
