#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

VENV_DIR="${VENV_DIR:-$ROOT_DIR/.venv-qwen35}" \
INSTALL_VLLM_UPGRADE="${INSTALL_VLLM_UPGRADE:-1}" \
INSTALL_QWEN35_TRANSFORMERS="${INSTALL_QWEN35_TRANSFORMERS:-1}" \
INSTALL_FLASH_ATTN="${INSTALL_FLASH_ATTN:-1}" \
  "$ROOT_DIR/scripts/setup_repo.sh" "$@"
