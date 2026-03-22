#!/bin/zsh

set -euo pipefail

WEBUI_DIR="${SD_WEBUI_DIR:-$HOME/Applications/stable-diffusion-webui}"
PYTHON_BIN="${SD_WEBUI_PYTHON:-/usr/bin/python3}"
HOST_ADDR="${SD_WEBUI_HOST:-127.0.0.1}"
PORT_NUM="${SD_WEBUI_PORT:-7860}"
LOG_FILE="${SD_WEBUI_LOG:-$HOME/Applications/stable-diffusion-webui/webui.log}"
STUB_DIR="${SD_WEBUI_STUB_DIR:-/Users/shinehandmac/Documents/puzzle/.tools/sd-webui-stubs}"

if [[ ! -d "$WEBUI_DIR" ]]; then
  echo "Stable Diffusion WebUI directory not found: $WEBUI_DIR" >&2
  exit 1
fi

if [[ ! -x "$PYTHON_BIN" ]]; then
  echo "Python binary not found: $PYTHON_BIN" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"

export PYTHON="$PYTHON_BIN"
export COMMANDLINE_ARGS="--api --skip-torch-cuda-test --server-name $HOST_ADDR --port $PORT_NUM"
export TORCH_COMMAND="${SD_TORCH_COMMAND:-pip install torch==2.2.2 torchvision==0.17.2}"
export PYTHONPATH="$STUB_DIR${PYTHONPATH:+:$PYTHONPATH}"

cd "$WEBUI_DIR"
exec ./webui.sh
