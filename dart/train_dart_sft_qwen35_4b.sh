#!/usr/bin/env bash
set -euo pipefail

export SFT_MODEL_PATH="${SFT_MODEL_PATH:-Qwen/Qwen3.5-4B}"
export SFT_FORCE_CAUSAL_LM="${SFT_FORCE_CAUSAL_LM:-true}"
exec "$(dirname "$0")/train_dart_sft_llama3b.sh" "$@"
