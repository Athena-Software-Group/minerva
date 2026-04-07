#!/usr/bin/env bash
set -euo pipefail

export ACRD_MODEL_PATH="${ACRD_MODEL_PATH:-Qwen/Qwen3.5-9B-Base}"
export ACRD_ROLLOUT_GPU_UTIL="${ACRD_ROLLOUT_GPU_UTIL:-0.7}"

exec "$(dirname "$0")/train_minerva_noctua_qwen35_4b.sh" "$@"
