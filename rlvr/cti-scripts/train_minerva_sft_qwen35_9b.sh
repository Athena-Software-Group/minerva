#!/usr/bin/env bash
set -euo pipefail

export SFT_MODEL_PATH="${SFT_MODEL_PATH:-Qwen/Qwen3.5-9B-Base}"
export SFT_EXPERIMENT_NAME="${SFT_EXPERIMENT_NAME:-dart_sft_qwen3_5_9b_base}"

exec "$(dirname "$0")/train_minerva_sft_qwen35_4b.sh" "$@"
