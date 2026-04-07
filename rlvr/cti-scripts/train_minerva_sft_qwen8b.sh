#!/usr/bin/env bash
set -euo pipefail

export SFT_MODEL_PATH="${SFT_MODEL_PATH:-Qwen/Qwen3-8B-Base}"
exec "$(dirname "$0")/train_minerva_sft_llama3b.sh" "$@"
