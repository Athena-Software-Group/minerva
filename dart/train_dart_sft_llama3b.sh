#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PYTHONPATH="$REPO_ROOT/rlvr:$REPO_ROOT${PYTHONPATH:+:$PYTHONPATH}"

export SFT_MODEL_PATH="${SFT_MODEL_PATH:-meta-llama/Llama-3.2-3B-Instruct}"
export SFT_N_GPUS_PER_NODE="${SFT_N_GPUS_PER_NODE:-4}"
export SFT_TOTAL_EPOCHS="${SFT_TOTAL_EPOCHS:-1}"
export SFT_TRAIN_BATCH_SIZE="${SFT_TRAIN_BATCH_SIZE:-128}"
export SFT_MICRO_BATCH_SIZE_PER_GPU="${SFT_MICRO_BATCH_SIZE_PER_GPU:-8}"
export SFT_MAX_LENGTH="${SFT_MAX_LENGTH:-4096}"
export SFT_SAVE_FREQ="${SFT_SAVE_FREQ:-10}"
export SFT_TEST_FREQ="${SFT_TEST_FREQ:-10}"

MODEL_NAME="$(basename "$SFT_MODEL_PATH")"
MODEL_SLUG="$(printf "%s" "$MODEL_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '_' | sed 's/^_//;s/_$//')"
if [ -z "$MODEL_SLUG" ]; then
  MODEL_SLUG="model"
fi
export SFT_EXPERIMENT_NAME="${SFT_EXPERIMENT_NAME:-dart_sft_${MODEL_SLUG}}"
export SFT_OUTPUT_ROOT="${SFT_OUTPUT_ROOT:-$REPO_ROOT/rlvr/checkpoints/dart/$SFT_EXPERIMENT_NAME}"

exec "$REPO_ROOT/rlvr/cti-scripts/_shared/train_minerva_sft.sh" \
  model.strategy=fsdp \
  model.fsdp_config.model_dtype=bfloat16 \
  model.enable_gradient_checkpointing=true \
  trainer.max_ckpt_to_keep=1 \
  trainer.checkpoint.save_contents='["hf_model"]' \
  trainer.checkpoint.load_contents='[]' \
  trainer.logger='["console", "wandb"]' \
  "$@"
