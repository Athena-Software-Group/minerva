#!/usr/bin/env bash
set -euo pipefail

export MINERVA_BASE_MODEL_PATH="${MINERVA_BASE_MODEL_PATH:-Qwen/Qwen3.5-9B-Base}"
export MINERVA_BASE_ROLLOUT_GPU_UTIL="${MINERVA_BASE_ROLLOUT_GPU_UTIL:-0.7}"
export MINERVA_BASE_EXPERIMENT_NAME="${MINERVA_BASE_EXPERIMENT_NAME:-minerva_base_grpo_qwen35_9b}"

exec "$(dirname "$0")/train_minerva_base_qwen35_4b.sh" "$@"
