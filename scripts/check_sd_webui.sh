#!/bin/zsh

set -euo pipefail

URL="${SD_WEBUI_URL:-http://127.0.0.1:7860}"

echo "Checking Stable Diffusion WebUI at $URL"
curl -fsS "$URL/sdapi/v1/sd-models" >/dev/null
echo "Stable Diffusion WebUI API is reachable."
