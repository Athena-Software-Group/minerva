#!/usr/bin/env bash
set -euo pipefail

export ACRD_MODEL_PATH="${ACRD_MODEL_PATH:-Qwen/Qwen3.5-4B}"
export ACRD_ACR_ROLLOUT_N="${ACRD_ACR_ROLLOUT_N:-4}"
export ACRD_ACR_DISTILL_LR_SCALE="${ACRD_ACR_DISTILL_LR_SCALE:-0.05}"
export ACRD_ACR_DISTILL_BUFFER_MODE="${ACRD_ACR_DISTILL_BUFFER_MODE:-flush}"
export ACRD_ACR_DISTILL_BATCH_SIZE="${ACRD_ACR_DISTILL_BATCH_SIZE:-256}"
export ACRD_ACR_DISTILL_DISABLE_FILTERS="${ACRD_ACR_DISTILL_DISABLE_FILTERS:-false}"

export ACRD_ACR_DISTILL_FILTER_MODE="${ACRD_ACR_DISTILL_FILTER_MODE:-ml+heuristic}"
export ACRD_ACR_DISTILL_FILTER_MODEL="${ACRD_ACR_DISTILL_FILTER_MODEL:-textcnn-response-only-lr6e-4-k345-f384-e300-t1024-d0p25}"
export ACRD_ACR_DISTILL_FILTER_MODEL_TYPE="${ACRD_ACR_DISTILL_FILTER_MODEL_TYPE:-textcnn}"
export ACRD_ACR_DISTILL_FILTER_THRESHOLD="${ACRD_ACR_DISTILL_FILTER_THRESHOLD:-0.5}"
export ACRD_ACR_ROLLOUT_TEMPERATURE="${ACRD_ACR_ROLLOUT_TEMPERATURE:-0.7}"
export ACRD_ACR_ROLLOUT_TOP_P="${ACRD_ACR_ROLLOUT_TOP_P:-0.9}"
export ACRD_ACR_DEFER_GENERATION="${ACRD_ACR_DEFER_GENERATION:-true}"
# Keep the verified Qwen3.5 path on by default. EMA can be re-enabled once
# the Qwen3.5 teacher init path is fully aligned with the actor builder.
export ACRD_ACR_EMA_TEACHER_ENABLED="${ACRD_ACR_EMA_TEACHER_ENABLED:-false}"
export ACRD_ACR_EMA_TEACHER_ALPHA="${ACRD_ACR_EMA_TEACHER_ALPHA:-0.995}"
export ACRD_ROLLOUT_GPU_UTIL="${ACRD_ROLLOUT_GPU_UTIL:-0.8}"
export ACRD_ROLLOUT_MAX_MODEL_LEN="${ACRD_ROLLOUT_MAX_MODEL_LEN:-4096}"
export ACRD_ROLLOUT_ENFORCE_EAGER="${ACRD_ROLLOUT_ENFORCE_EAGER:-true}"
export ACRD_ROLLOUT_ENABLE_CHUNKED_PREFILL="${ACRD_ROLLOUT_ENABLE_CHUNKED_PREFILL:-true}"
export ACRD_ROLLOUT_ENABLE_PREFIX_CACHING="${ACRD_ROLLOUT_ENABLE_PREFIX_CACHING:-false}"
export ACRD_ROLLOUT_HF_OVERRIDE_ARCHITECTURES="${ACRD_ROLLOUT_HF_OVERRIDE_ARCHITECTURES:-[Qwen3_5ForCausalLM]}"
export ACRD_FORCE_CAUSAL_LM="${ACRD_FORCE_CAUSAL_LM:-true}"

export ACRD_N_GPUS_PER_NODE="${ACRD_N_GPUS_PER_NODE:-4}"

MODEL_NAME="$(basename "$ACRD_MODEL_PATH")"
MODEL_SLUG="$(printf "%s" "$MODEL_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '_' | sed 's/^_//;s/_$//')"
if [ -z "$MODEL_SLUG" ]; then
  MODEL_SLUG="model"
fi
export ACRD_EXPERIMENT_NAME="${ACRD_EXPERIMENT_NAME:-minerva_noctua_${MODEL_SLUG}_lr0.05_flush_bs256_mlh_t0.7_p0.9_defer_ema}"

exec "$(dirname "$0")/train_minerva_noctua.sh" \
  +actor_rollout_ref.model.force_causal_lm="$ACRD_FORCE_CAUSAL_LM" \
  actor_rollout_ref.rollout.name=vllm \
  actor_rollout_ref.rollout.max_model_len="$ACRD_ROLLOUT_MAX_MODEL_LEN" \
  actor_rollout_ref.rollout.enforce_eager="$ACRD_ROLLOUT_ENFORCE_EAGER" \
  actor_rollout_ref.rollout.enable_chunked_prefill="$ACRD_ROLLOUT_ENABLE_CHUNKED_PREFILL" \
  +actor_rollout_ref.rollout.enable_prefix_caching="$ACRD_ROLLOUT_ENABLE_PREFIX_CACHING" \
  '+actor_rollout_ref.rollout.engine_kwargs.vllm.hf_overrides.architectures='"$ACRD_ROLLOUT_HF_OVERRIDE_ARCHITECTURES" \
  +actor_rollout_ref.rollout.engine_kwargs.vllm.language_model_only=true \
  +actor_rollout_ref.rollout.engine_kwargs.vllm.limit_mm_per_prompt.image=0 \
  "$@"
