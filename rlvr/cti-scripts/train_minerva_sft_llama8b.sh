#!/usr/bin/env bash
set -euo pipefail

export SFT_MODEL_PATH="${SFT_MODEL_PATH:-meta-llama/Llama-3.1-8B-Instruct}"
exec "$(dirname "$0")/train_minerva_sft_llama3b.sh" "$@"
