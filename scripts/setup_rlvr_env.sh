#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="${VENV_DIR:-$ROOT_DIR/.venv}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
RECREATE_VENV="${RECREATE_VENV:-1}"
REQ_FILE="${REQ_FILE:-$ROOT_DIR/requirements-rlvr-minerva.txt}"
VLLM_SPEC="${VLLM_SPEC:-vllm>=0.19.0}"
TRANSFORMERS_SPEC="${TRANSFORMERS_SPEC:-transformers[serving] @ git+https://github.com/huggingface/transformers.git@main}"
HUGGINGFACE_HUB_SPEC="${HUGGINGFACE_HUB_SPEC:-huggingface-hub>=1.5.0}"
INSTALL_VLLM_UPGRADE="${INSTALL_VLLM_UPGRADE:-1}"
INSTALL_QWEN35_TRANSFORMERS="${INSTALL_QWEN35_TRANSFORMERS:-1}"
INSTALL_FLASH_ATTN="${INSTALL_FLASH_ATTN:-0}"

if [ ! -f "$REQ_FILE" ]; then
  echo "Missing requirements file: $REQ_FILE" >&2
  exit 1
fi

if [ "$RECREATE_VENV" = "1" ] && [ -d "$VENV_DIR" ]; then
  rm -rf "$VENV_DIR"
fi

if [ ! -d "$VENV_DIR" ]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

PYTHON="$VENV_DIR/bin/python"
PIP="$VENV_DIR/bin/pip"

"$PYTHON" -m pip install --upgrade pip setuptools wheel
"$PIP" install -r "$REQ_FILE"
if [ "$INSTALL_VLLM_UPGRADE" = "1" ]; then
  "$PIP" install --upgrade "$VLLM_SPEC"
fi
if [ "$INSTALL_QWEN35_TRANSFORMERS" = "1" ]; then
  "$PIP" install --upgrade "$HUGGINGFACE_HUB_SPEC"
  "$PIP" install --upgrade "$TRANSFORMERS_SPEC"
fi
if [ "$INSTALL_FLASH_ATTN" = "1" ]; then
  "$PIP" install flash-attn --no-build-isolation
fi

echo "RLVR environment ready at $VENV_DIR"
echo "Activate with: source \"$VENV_DIR/bin/activate\""
