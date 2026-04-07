#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export PYTHONPATH="$ROOT_DIR:$ROOT_DIR/..${PYTHONPATH:+:$PYTHONPATH}"

export SFT_MODEL_PATH="${SFT_MODEL_PATH:-Qwen/Qwen3.5-4B-Base}"
export SFT_FORCE_CAUSAL_LM="${SFT_FORCE_CAUSAL_LM:-true}"
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
export SFT_OUTPUT_ROOT="${SFT_OUTPUT_ROOT:-$ROOT_DIR/checkpoints/dart/$SFT_EXPERIMENT_NAME}"

exec "$(dirname "$0")/_shared/train_minerva_sft.sh" \
  model.strategy=fsdp \
  model.fsdp_config.model_dtype=bfloat16 \
  model.enable_gradient_checkpointing=true \
  trainer.max_ckpt_to_keep=1 \
  trainer.checkpoint.save_contents='["hf_model"]' \
  trainer.checkpoint.load_contents='[]' \
  trainer.logger='["console", "wandb"]' \
  "$@"
