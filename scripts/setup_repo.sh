#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="${VENV_DIR:-$ROOT_DIR/.venv}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
RECREATE_VENV="${RECREATE_VENV:-1}"
REQ_FILE="${REQ_FILE:-$ROOT_DIR/requirements-rlvr-minerva.txt}"
PULL_LFS="${PULL_LFS:-1}"
LFS_INCLUDE="${LFS_INCLUDE:-dataset/**,rlvr/mydata/**}"
INSTALL_VLLM_UPGRADE="${INSTALL_VLLM_UPGRADE:-1}"
INSTALL_QWEN35_TRANSFORMERS="${INSTALL_QWEN35_TRANSFORMERS:-1}"
INSTALL_FLASH_ATTN="${INSTALL_FLASH_ATTN:-1}"

VENV_DIR="$VENV_DIR" \
PYTHON_BIN="$PYTHON_BIN" \
RECREATE_VENV="$RECREATE_VENV" \
REQ_FILE="$REQ_FILE" \
INSTALL_VLLM_UPGRADE="$INSTALL_VLLM_UPGRADE" \
INSTALL_QWEN35_TRANSFORMERS="$INSTALL_QWEN35_TRANSFORMERS" \
INSTALL_FLASH_ATTN="$INSTALL_FLASH_ATTN" \
  "$ROOT_DIR/scripts/setup_rlvr_env.sh"

if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$ROOT_DIR" lfs version >/dev/null 2>&1; then
    git -C "$ROOT_DIR" lfs install --local >/dev/null
    if [ "$PULL_LFS" = "1" ]; then
      git -C "$ROOT_DIR" lfs pull --include="$LFS_INCLUDE"
    fi
  else
    cat <<EOF
git-lfs was not found.
Install git-lfs and then run:
  git -C "$ROOT_DIR" lfs install --local
  git -C "$ROOT_DIR" lfs pull --include="$LFS_INCLUDE"
EOF
  fi
fi

echo "Repo setup complete."
echo "Activate with: source \"$VENV_DIR/bin/activate\""
