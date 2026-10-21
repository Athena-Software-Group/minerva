# Minerva

Code for **Minerva: Reinforcement Learning with Verifiable Rewards for Cyber Threat Intelligence LLMs**, accepted at **Transactions on Machine Learning Research (TMLR), 2026**.

[Paper](https://openreview.net/forum?id=w1IMu9exKC) | [Project page](https://maveryn.github.io/minerva-tmlr/) | [Setup](#first-setup) | [Training](#training) | [Citation](#citation)

## Minerva Implementation

**MinervaRL**, the paper's training method, is named **Minerva-Noctua** in the launch scripts. Its implementation lives in `rlvr/`; `minerva/` contains the **Minerva-CTI dataset construction** code.

| Component | Where to start |
| --- | --- |
| MinervaRL training launchers | [Llama-3.2-3B launcher](rlvr/cti-scripts/train_minerva_noctua_llama3b.sh); see [Minerva-Noctua training](#1-minerva-noctua-minervarl) for all four backbones. |
| Shared training configuration | [`train_minerva_noctua.sh`](rlvr/cti-scripts/_shared/train_minerva_noctua.sh) |
| MinervaRL training loop | [`ray_trainer.py`](rlvr/verl/trainer/ppo/ray_trainer.py): hard-prompt selection, answer-conditioned rationale (ACR) generation, filtering, and distillation onto original prompts. |
| Task verifiers and ACR rewards | [`reward_minerva.py`](rlvr/verl/utils/reward_score/reward_minerva.py) and [`reward_acr.py`](rlvr/verl/utils/reward_score/reward_acr.py) |
| Minerva-CTI dataset construction | [`pipeline.py`](minerva/pipeline.py), [`split.py`](minerva/split.py), and the [dataset documentation](minerva/README.md) |
| Training-data conversion | [`cti.py`](rlvr/mydata/data_prepare/cti.py): converts dataset splits to VeRL parquet files. |

The [Training](#training) section also covers the plain GRPO and DART SFT baselines.

## Repo Layout

- `minerva/`
  - dataset builder, task definitions, prompts, reward helpers
  - main entrypoints: `minerva/pipeline.py`, `minerva/split.py`
- `rlvr/`
  - VeRL-based training stack
  - `rlvr/cti-scripts/` contains the 12 supported top-level training launchers
  - `rlvr/cti-scripts/_shared/` contains shared launcher internals
  - `rlvr/old-cti-scripts/` contains archived or experimental launchers
- `dart/`
  - compatibility wrappers for the checked-in 64k DART SFT dataset
- `dataset/`
  - checked-in runtime assets needed by training, including `label_details/` and the TextCNN filter model
- `rlvr/mydata/`
  - checked-in Minerva RL train/dev parquet files
  - checked-in Athena validation parquet files
  - checked-in DART SFT train/validation parquet files

## First Setup

Requirements:

- Python 3
- CUDA-capable PyTorch environment
- `git-lfs`

Run the repo bootstrap script:

```bash
bash scripts/setup_repo.sh
source .venv/bin/activate
```

What this does:

- creates or recreates `.venv`
- installs the RLVR-based Python environment from `requirements-rlvr-minerva.txt`
- installs `flash-attn`
- runs `git lfs install`
- pulls the tracked runtime datasets under `dataset/` and `rlvr/mydata/`

Useful options:

```bash
RECREATE_VENV=0 bash scripts/setup_repo.sh
PULL_LFS=0 bash scripts/setup_repo.sh
```

The lower-level env-only script still exists at `scripts/setup_rlvr_env.sh`, but `scripts/setup_repo.sh` is the default entrypoint for this repo.

## Qwen3.5 Branch

`Qwen/Qwen3.5-4B` support is maintained on the `qwen3.5` branch, not on `main`.

That branch contains:

- the updated `vllm` and `transformers` setup path
- the isolated Qwen3.5 environment bootstrap
- the Qwen3.5 launchers for Minerva-Noctua, plain GRPO, and DART SFT

To use it:

```bash
git switch qwen3.5
bash scripts/setup_qwen35_repo.sh
source .venv-qwen35/bin/activate
```

## Checked-In Runtime Data

The repo already includes the runtime datasets used by the training scripts:

- RL train/dev:
  - `rlvr/mydata/minerva_base/minerva_base_train.parquet`
  - `rlvr/mydata/minerva_base/minerva_base_dev.parquet`
- RL validation:
  - `rlvr/mydata/athena/athena_cti_ate.parquet`
  - `rlvr/mydata/athena/athena_cti_ckt.parquet`
  - `rlvr/mydata/athena/athena_cti_rcm.parquet`
  - `rlvr/mydata/athena/athena_cti_rms.parquet`
  - `rlvr/mydata/athena/athena_cti_taa.parquet`
  - `rlvr/mydata/athena/athena_cti_vsp.parquet`
- Noctua extras:
  - `dataset/label_details/`
  - `dataset/models/textcnn-response-only-lr6e-4-k345-f384-e300-t1024-d0p25/`
- DART SFT:
  - `rlvr/mydata/sft/train_v2_from_llama8b_direct_from_v3_cap200_seed.parquet`
  - `rlvr/mydata/sft/minerva_dev_v2_from_minerva_dev_v3_from_v2.parquet`
  - `rlvr/mydata/sft/athena_bench_v2_from_athena_bench_v3_from_v2.parquet`

## Training

`rlvr/cti-scripts/` now contains exactly 12 supported top-level launchers:

- 4 Minerva-Noctua launchers
- 4 plain GRPO launchers
- 4 DART SFT launchers

### 1. Minerva-Noctua (MinervaRL)

Main launchers:

- `rlvr/cti-scripts/train_minerva_noctua_llama3b.sh`
- `rlvr/cti-scripts/train_minerva_noctua_llama8b.sh`
- `rlvr/cti-scripts/train_minerva_noctua_qwen4b.sh`
- `rlvr/cti-scripts/train_minerva_noctua_qwen8b.sh`

Commands:

```bash
source .venv/bin/activate
bash rlvr/cti-scripts/train_minerva_noctua_llama3b.sh
bash rlvr/cti-scripts/train_minerva_noctua_llama8b.sh
bash rlvr/cti-scripts/train_minerva_noctua_qwen4b.sh
bash rlvr/cti-scripts/train_minerva_noctua_qwen8b.sh
```

Notes:

- Noctua uses the checked-in Minerva RL train parquet, Athena validation parquets, `dataset/label_details/`, and the checked-in TextCNN filter model.
- The Noctua path defaults to `4` GPUs in this repo.
- The shared training configuration is in [`train_minerva_noctua.sh`](rlvr/cti-scripts/_shared/train_minerva_noctua.sh); the training loop is in [`ray_trainer.py`](rlvr/verl/trainer/ppo/ray_trainer.py).

10-step smoke-test example:

```bash
source .venv/bin/activate
WANDB_MODE=offline \
ACRD_EXPERIMENT_NAME=smoke_noctua_llama3b_10steps \
bash rlvr/cti-scripts/train_minerva_noctua_llama3b.sh \
  trainer.total_training_steps=10 \
  trainer.save_freq=10 \
  trainer.test_freq=10
```

### 2. Plain GRPO

Main launchers:

- `rlvr/cti-scripts/train_minerva_base_llama3b.sh`
- `rlvr/cti-scripts/train_minerva_base_llama8b.sh`
- `rlvr/cti-scripts/train_minerva_base_qwen4b.sh`
- `rlvr/cti-scripts/train_minerva_base_qwen8b.sh`

Commands:

```bash
source .venv/bin/activate
bash rlvr/cti-scripts/train_minerva_base_llama3b.sh trainer.n_gpus_per_node=4
bash rlvr/cti-scripts/train_minerva_base_llama8b.sh trainer.n_gpus_per_node=4
bash rlvr/cti-scripts/train_minerva_base_qwen4b.sh trainer.n_gpus_per_node=4
bash rlvr/cti-scripts/train_minerva_base_qwen8b.sh trainer.n_gpus_per_node=4
```

Notes:

- Plain GRPO uses `rlvr/mydata/minerva_base/minerva_base_train.parquet`.
- The current base wrappers validate on `minerva_base_dev.parquet` plus the script-configured Athena subset: `ate`, `ckt`, `rcm`, and `rms`.
- The reward entrypoint is `rlvr/verl/utils/reward_score/reward_minerva.py`.
- The base scripts are older wrappers, so GPU count is usually passed as an override.

10-step smoke-test example:

```bash
source .venv/bin/activate
WANDB_MODE=offline \
bash rlvr/cti-scripts/train_minerva_base_llama3b.sh \
  trainer.n_gpus_per_node=4 \
  trainer.total_training_steps=10 \
  trainer.save_freq=10 \
  trainer.test_freq=10
```

### 3. DART SFT

Main launchers:

- `rlvr/cti-scripts/train_minerva_sft_llama3b.sh`
- `rlvr/cti-scripts/train_minerva_sft_llama8b.sh`
- `rlvr/cti-scripts/train_minerva_sft_qwen4b.sh`
- `rlvr/cti-scripts/train_minerva_sft_qwen8b.sh`

Commands:

```bash
source .venv/bin/activate
bash rlvr/cti-scripts/train_minerva_sft_llama3b.sh
bash rlvr/cti-scripts/train_minerva_sft_llama8b.sh
bash rlvr/cti-scripts/train_minerva_sft_qwen4b.sh
bash rlvr/cti-scripts/train_minerva_sft_qwen8b.sh
```

Notes:

- SFT uses the checked-in DART 64k train parquet in `rlvr/mydata/sft/`.
- Validation loss is computed on the checked-in DART `minerva_dev` and `athena_bench` validation parquets in the same directory.
- The shared SFT implementation lives under `rlvr/cti-scripts/_shared/`.
- The `dart/` wrappers remain as compatibility aliases, but `rlvr/cti-scripts/` is the canonical entrypoint location.

10-step smoke-test example:

```bash
source .venv/bin/activate
WANDB_MODE=offline \
SFT_TOTAL_STEPS=10 \
SFT_TOTAL_EPOCHS=1 \
SFT_SAVE_FREQ=10 \
SFT_TEST_FREQ=10 \
SFT_N_GPUS_PER_NODE=4 \
SFT_RESUME_MODE=disable \
SFT_TRAIN_BATCH_SIZE=64 \
SFT_MICRO_BATCH_SIZE_PER_GPU=4 \
bash rlvr/cti-scripts/train_minerva_sft_llama3b.sh
```

## Creating Minerva Training Data

This repo now keeps the final runtime datasets in Git LFS, not the full set of raw builder inputs and caches.

To rebuild the Minerva dataset from scratch, first restore or regenerate the builder inputs expected by the dataset pipeline:

- `dataset/nvd/`
- `dataset/mitre/`
- `dataset/capec/`
- `dataset/cwe/`
- `dataset/mappings-explorer/`
- `dataset/sigma/`
- `dataset/detection/`

If you are on the same workstation as the source repo and want the exact source-repo inputs, you can copy them with:

```bash
rsync -a /home/jovyan/work/minerva/dataset/{nvd,mitre,capec,cwe,mappings-explorer,sigma,detection}/ dataset/
```

Then run:

```bash
source .venv/bin/activate

# Optional for faster NVD access
export NVD_API_KEY=...

# Build the base JSONL dataset
python -m minerva.pipeline \
  --config minerva/config.yaml \
  --variant base \
  --output-root dataset/minerva_base

# Build the base train/dev split
python -m minerva.split \
  --input-dir dataset/minerva_base \
  --output-dir dataset/minerva_base_split \
  --file-prefix minerva-base

# Build label details used by Noctua
python scripts/build_label_details.py

# Convert the split to VeRL parquet format
python rlvr/mydata/data_prepare/cti.py \
  --data_dir dataset/minerva_base_split \
  --out_dir rlvr/mydata/minerva_base
```

This produces the main Minerva RL train/dev artifacts:

- `dataset/minerva_base_split/minerva-base-train.jsonl`
- `dataset/minerva_base_split/minerva-base-dev.jsonl`
- `dataset/minerva_base_split/threat_actor_lookup.json`
- `rlvr/mydata/minerva_base/minerva_base_train.parquet`
- `rlvr/mydata/minerva_base/minerva_base_dev.parquet`

The Athena validation parquets used by training are already checked in under `rlvr/mydata/athena/`. If you need to regenerate those too, prepare the AthenaBench JSONLs and rerun the parquet conversion flow for those files.

## Additional References

- [Repository guidance](AGENTS.md)
- [Minerva dataset documentation](minerva/README.md)
- [Task descriptions](docs/task-descriptions.md)

## Citation

If you use Minerva in your research, please cite:

```bibtex
@article{alam2026minerva,
  title = {Minerva: Reinforcement Learning with Verifiable Rewards for Cyber Threat Intelligence LLMs},
  author = {Alam, Md Tanvirul and Piplai, Aritran and Cardei, Ionut and Rastogi, Nidhi and Worth, Jr., Peter J},
  journal = {Transactions on Machine Learning Research},
  year = {2026},
  url = {https://openreview.net/forum?id=w1IMu9exKC}
}
```
