#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="${VENV_DIR:-$ROOT_DIR/.venv}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
RECREATE_VENV="${RECREATE_VENV:-1}"
REQ_FILE="${REQ_FILE:-$ROOT_DIR/requirements-rlvr-minerva.txt}"

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
"$PIP" install flash-attn --no-build-isolation

echo "RLVR environment ready at $VENV_DIR"
echo "Activate with: source \"$VENV_DIR/bin/activate\""
