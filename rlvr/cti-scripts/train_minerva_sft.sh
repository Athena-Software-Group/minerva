#!/usr/bin/env bash
set -euo pipefail

# Pure SFT training script for the fixed DART-style Minerva SFT dataset.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$ROOT_DIR/mydata"
REPO_ROOT="$(cd "$ROOT_DIR/.." && pwd)"
export PYTHONPATH="$ROOT_DIR:$REPO_ROOT${PYTHONPATH:+:$PYTHONPATH}"

export WANDB_START_METHOD=thread
export WANDB_DISABLE_SERVICE=true
export PYTHONUNBUFFERED=1

MODEL_PATH="${SFT_MODEL_PATH:-meta-llama/Llama-3.2-3B-Instruct}"
MODEL_NAME="$(basename "$MODEL_PATH")"
MODEL_SLUG="$(printf "%s" "$MODEL_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '_' | sed 's/^_//;s/_$//')"
if [ -z "$MODEL_SLUG" ]; then
  MODEL_SLUG="model"
fi
EXPERIMENT_NAME="${SFT_EXPERIMENT_NAME:-minerva_sft_${MODEL_SLUG}}"

TRAIN_PATH="${SFT_TRAIN_PATH:-$DATA_DIR/sft/train_v2_from_llama8b_direct_from_v3_cap200_seed.parquet}"
VAL_PATHS=(
  "${SFT_VAL_PATH_1:-$DATA_DIR/sft/minerva_dev_v2_from_minerva_dev_v3_from_v2.parquet}"
  "${SFT_VAL_PATH_2:-$DATA_DIR/sft/athena_bench_v2_from_athena_bench_v3_from_v2.parquet}"
)

for path in "$TRAIN_PATH" "${VAL_PATHS[@]}"; do
  if [ ! -f "$path" ]; then
    echo "Required file not found: $path" >&2
    exit 1
  fi
done

TRAIN_FILES="['$TRAIN_PATH']"
VAL_FILES="["
for i in "${!VAL_PATHS[@]}"; do
  if [ "$i" -gt 0 ]; then
    VAL_FILES+=","
  fi
  VAL_FILES+="'${VAL_PATHS[$i]}'"
done
VAL_FILES+="]"

OUTPUT_ROOT="${SFT_OUTPUT_ROOT:-$ROOT_DIR/checkpoints/dart/$EXPERIMENT_NAME}"

TRAIN_BATCH_SIZE="${SFT_TRAIN_BATCH_SIZE:-128}"
MICRO_BATCH_SIZE_PER_GPU="${SFT_MICRO_BATCH_SIZE_PER_GPU:-8}"
MAX_LENGTH="${SFT_MAX_LENGTH:-4096}"
TOTAL_EPOCHS="${SFT_TOTAL_EPOCHS:-1}"
SAVE_FREQ="${SFT_SAVE_FREQ:-10}"
TEST_FREQ="${SFT_TEST_FREQ:-10}"
N_GPUS="${SFT_N_GPUS_PER_NODE:-4}"
RESUME_MODE="${SFT_RESUME_MODE:-auto}"
FORCE_CAUSAL_LM="${SFT_FORCE_CAUSAL_LM:-false}"

EXTRA_TRAINER_ARGS=()
EXTRA_TRAINER_ARGS+=(trainer.total_epochs="$TOTAL_EPOCHS")
EXTRA_TRAINER_ARGS+=(trainer.resume_mode="$RESUME_MODE")
if [ -n "${SFT_TOTAL_STEPS:-}" ]; then
  EXTRA_TRAINER_ARGS+=(trainer.total_training_steps="$SFT_TOTAL_STEPS")
fi

torchrun --standalone --nnodes=1 --nproc_per_node="$N_GPUS" \
  -m verl.trainer.fsdp_sft_trainer \
  data.train_files="$TRAIN_FILES" \
  data.val_files="$VAL_FILES" \
  data.train_batch_size="$TRAIN_BATCH_SIZE" \
  data.micro_batch_size_per_gpu="$MICRO_BATCH_SIZE_PER_GPU" \
  data.max_length="$MAX_LENGTH" \
  data.truncation=left \
  data.multiturn.enable=true \
  data.multiturn.messages_key=messages \
  model.partial_pretrain="$MODEL_PATH" \
  +model.force_causal_lm="$FORCE_CAUSAL_LM" \
  trainer.default_local_dir="$OUTPUT_ROOT" \
  trainer.project_name='dart' \
  trainer.experiment_name="$EXPERIMENT_NAME" \
  trainer.save_freq="$SAVE_FREQ" \
  trainer.test_freq="$TEST_FREQ" \
  trainer.n_gpus_per_node="$N_GPUS" \
  trainer.nnodes=1 \
  "${EXTRA_TRAINER_ARGS[@]}" \
  "$@"
