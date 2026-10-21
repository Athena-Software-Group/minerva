# MinervaRL: method and implementation

MinervaRL is the training method in [the Minerva paper](https://openreview.net/forum?id=w1IMu9exKC). Noctua / Minerva-Noctua are historical names for the same method. The `train_minerva_noctua_*.sh` filenames and `ACRD_*` environment variables remain stable so existing commands continue to work. This guide describes the supported MinervaRL launchers on `main`.

## Training loop

1. **GRPO on original prompts.** Sample eight completions per prompt and score them with the task verifier.
2. **Buffer hard prompts.** A prompt is hard when its best rollout reward is below 1.0. CVSS prompts are excluded from this auxiliary step.
3. **Deferred answer-conditioned rationale (ACR) generation.** Every 10 steps, build prompts with the ground-truth label and canonical label details. The EMA teacher generates four traces per prompt, at temperature 0.7 and top-p 0.9.
4. **Verify and filter.** Require verifier success, apply leakage/degeneracy heuristics, and use the response-only TextCNN quality filter with threshold 0.5. Keep at most one accepted trace per original prompt.
5. **Distill onto original prompts.** Apply an SFT update using up to 256 accepted traces and a learning-rate scale of 0.05, then flush the buffers. The SFT inputs use `acr_orig_prompt` / `orig_prompt`, without the gold-label context used for generation.

The supported launcher sets `data.acr.update_actor=false`: the auxiliary ACR phase produces traces for SFT; it does not perform a second GRPO update on answer-conditioned prompts. Gold labels and canonical references are training-time inputs for the teacher. Inference uses the original prompt.

## Paper-to-code map

| Paper component | Implementation |
| --- | --- |
| GRPO and auxiliary-phase orchestration | [`RayPPOTrainer`](../rlvr/verl/trainer/ppo/ray_trainer.py), including `_compute_acr_hard_uids`, `_build_acr_batch`, `_run_acr_phase`, `_collect_distill_candidates`, and `_maybe_run_distill_sft` |
| ACR prompt construction | [`acr_prompt.py`](../minerva/acr_prompt.py) |
| Task metadata and label normalization | [`cti_task_specs.py`](../minerva/cti_task_specs.py) and [`label_specs.py`](../minerva/label_specs.py) |
| Canonical label details | [`label_details_store.py`](../minerva/label_details_store.py) and [`build_label_details.py`](../scripts/build_label_details.py) |
| Task verifiers | [`reward_minerva.py`](../rlvr/verl/utils/reward_score/reward_minerva.py), using the task helpers in [`minerva/reward.py`](../minerva/reward.py) |
| ACR correctness and leakage checks | [`reward_acr.py`](../rlvr/verl/utils/reward_score/reward_acr.py) |
| TextCNN loading and scoring | `_maybe_init_acr_filter_model` and `_acr_filter_score_textcnn` in [`ray_trainer.py`](../rlvr/verl/trainer/ppo/ray_trainer.py) |
| Shared training configuration | [`train_minerva_noctua.sh`](../rlvr/cti-scripts/_shared/train_minerva_noctua.sh) |

Canonical label references are looked up by the known training label. MinervaRL does not require a retrieval server or a retrieval tool call. The old standalone TARBA service, dataset/reward wrappers, tool configuration, and launchers have been removed. Shared corpus builders in `minerva/analysis/retrieval_candidates.py` remain because label-detail construction and legacy LHC dataset generation use them.

## Supported launchers and settings

Run setup from the [root README](../README.md#first-setup), then select a model:

| Backbone | Launcher |
| --- | --- |
| Llama-3.2-3B-Instruct | [`train_minerva_noctua_llama3b.sh`](../rlvr/cti-scripts/train_minerva_noctua_llama3b.sh) |
| Llama-3.1-8B-Instruct | [`train_minerva_noctua_llama8b.sh`](../rlvr/cti-scripts/train_minerva_noctua_llama8b.sh) |
| Qwen3-4B-Base | [`train_minerva_noctua_qwen4b.sh`](../rlvr/cti-scripts/train_minerva_noctua_qwen4b.sh) |
| Qwen3-8B-Base | [`train_minerva_noctua_qwen8b.sh`](../rlvr/cti-scripts/train_minerva_noctua_qwen8b.sh) |

The model launchers set the MinervaRL configuration below before calling the shared script. The corresponding paper settings are in Appendix K.1-K.2.

| Setting | MinervaRL launcher value |
| --- | --- |
| Training steps / prompts per step | 500 / 128 |
| GRPO rollouts per prompt / actor learning rate | 8 / `1e-6` |
| Original prompt / ACR prompt / response limits | 2048 / 4096 / 1024 tokens |
| Hard-prompt rule | Maximum rollout reward `< 1.0`; skip CVSS |
| ACR interval / rollouts / temperature / top-p | 10 steps / 4 / 0.7 / 0.9 |
| EMA teacher decay | 0.995 |
| Trace filter | `ml+heuristic`, TextCNN threshold 0.5 |
| Distillation | SFT, at most 256 traces, learning-rate scale 0.05, flush buffer |
| GPUs | 4 by default; override with `ACRD_N_GPUS_PER_NODE` |

The shared script also exposes options used by older experiments. Use a model launcher to obtain the settings above, rather than invoking the shared script directly.

```bash
source .venv/bin/activate
WANDB_MODE=offline \
ACRD_EXPERIMENT_NAME=smoke_minervarl_llama3b_10steps \
bash rlvr/cti-scripts/train_minerva_noctua_llama3b.sh \
  trainer.total_training_steps=10 \
  trainer.save_freq=10 \
  trainer.test_freq=10
```

## Baselines and evaluation

The 12 supported launchers cover MinervaRL, plain GRPO, and fixed-dataset DART SFT (DART-CTI), each on four backbones. See the [training commands](../README.md#training). The paper also reports STaR-CTI and LUFFY-CTI; this curated checkout does not provide top-level launchers for those baselines.

MinervaRL validates on Minerva-Dev plus the six checked-in AthenaBench-Mini task parquets: ATE, CKT, RCM, RMS, TAA, and VSP. The shared launcher's default best-checkpoint metric is `val-core/global-val/reward/mean`. TAA is excluded from the paper's final 12-task evaluation; of the 950 AthenaBench-Mini examples, 900 are from the five overlapping tasks and 50 are TAA examples.

The plain GRPO wrappers currently validate on Minerva-Dev plus ATE, CKT, RCM, and RMS. They also retain older batch-size and response-length defaults. To use the paper's batch/length settings, pass `data.train_batch_size=128 actor_rollout_ref.actor.ppo_mini_batch_size=128 data.max_prompt_length=2048 data.max_response_length=1024 trainer.total_training_steps=500`; configure `data.val_files` explicitly when a matching validation pool is required. These differences are documented here rather than changing existing experiment settings.

DART-CTI uses the fixed synthetic training and validation parquets in `rlvr/mydata/sft/`. Its checkpoints are selected by synthetic-validation loss, as described in Appendix K.3.

Paper ablation launchers and older ACRD/LHC experiments remain under `rlvr/old-cti-scripts/`. The older `configs/acr_rl.yaml`, `configs/acrd_pipeline.yaml`, and offline ACR scripts describe separate experimental workflows; they are not the supported MinervaRL launch configuration above.
