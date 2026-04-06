# AGENTS.md

## Project summary
- This repo has three active paths:
  - `minerva/`: CTI dataset construction and reward helpers
  - `rlvr/`: VeRL/RLVR training for plain GRPO and Minerva-Noctua
  - `dart/`: fixed-dataset SFT launchers for the checked-in DART data
- The root [README.md](/home/jovyan/work/athena/minerva/README.md) is the central runbook. Prefer it over older scattered docs.

## Current repo layout
- `minerva/`
  - dataset builder, task builders, prompts, reward helpers
  - main entrypoints: `minerva/pipeline.py`, `minerva/split.py`
- `rlvr/cti-scripts/`
  - primary training launchers for plain GRPO, Noctua, ACRD variants, TARBA, and shared SFT
- `rlvr/verl/`
  - trainer, worker, reward, checkpoint, and dataset plumbing used by the launchers
- `dart/`
  - model-specific DART SFT wrappers that call `rlvr/cti-scripts/train_minerva_sft.sh`
- `dataset/`
  - checked-in runtime assets only
  - currently kept: `dataset/minerva_base_split/`, `dataset/label_details/`, `dataset/models/`
- `rlvr/mydata/`
  - checked-in runtime parquet datasets
  - currently kept: `rlvr/mydata/minerva_base/`, `rlvr/mydata/athena/`, `rlvr/mydata/sft/`, `rlvr/mydata/data_prepare/`

## Setup and environment
- Default setup entrypoint: `bash scripts/setup_repo.sh`
- Lower-level env-only setup: `bash scripts/setup_rlvr_env.sh`
- Python dependency anchor: `requirements-rlvr-minerva.txt`
- The repo bootstrap script:
  - creates or recreates `.venv`
  - installs the RLVR-based environment
  - installs `flash-attn`
  - runs `git lfs install`
  - pulls tracked runtime data under `dataset/` and `rlvr/mydata/`
- Activate with `source .venv/bin/activate`

## Key code entry points
- Dataset build orchestration: `minerva/pipeline.py`
- Train/dev split creation: `minerva/split.py`
- CTI reward helpers: `minerva/reward.py`
- VeRL parquet conversion: `rlvr/mydata/data_prepare/cti.py`
- RL trainer controller: `rlvr/verl/trainer/ppo/ray_trainer.py`
- Noctua and CTI reward logic:
  - `rlvr/verl/utils/reward_score/reward_minerva.py`
  - `rlvr/verl/utils/reward_score/reward_acr.py`
  - `rlvr/verl/utils/reward_score/reward_acr_batch.py`

## Checked-in runtime data
- Base RL train/dev:
  - `dataset/minerva_base_split/minerva-base-train.jsonl`
  - `dataset/minerva_base_split/minerva-base-dev.jsonl`
  - `dataset/minerva_base_split/threat_actor_lookup.json`
  - `rlvr/mydata/minerva_base/minerva_base_train.parquet`
  - `rlvr/mydata/minerva_base/minerva_base_dev.parquet`
- Athena validation parquet files:
  - `rlvr/mydata/athena/athena_cti_ate.parquet`
  - `rlvr/mydata/athena/athena_cti_ckt.parquet`
  - `rlvr/mydata/athena/athena_cti_rcm.parquet`
  - `rlvr/mydata/athena/athena_cti_rms.parquet`
  - `rlvr/mydata/athena/athena_cti_taa.parquet`
  - `rlvr/mydata/athena/athena_cti_vsp.parquet`
- Noctua extras:
  - `dataset/label_details/`
  - `dataset/models/textcnn-response-only-lr6e-4-k345-f384-e300-t1024-d0p25/`
- DART SFT data:
  - `rlvr/mydata/sft/train_v2_from_llama8b_direct_from_v3_cap200_seed.parquet`
  - `rlvr/mydata/sft/minerva_dev_v2_from_minerva_dev_v3_from_v2.parquet`
  - `rlvr/mydata/sft/athena_bench_v2_from_athena_bench_v3_from_v2.parquet`
- These runtime artifacts are intended to live in Git LFS. Treat them as generated data, not hand-edited source files.

## Supported training paths
- Minerva-Noctua:
  - shared launcher: `rlvr/cti-scripts/train_minerva_noctua.sh`
  - common wrappers: `train_minerva_noctua_llama3b.sh`, `train_minerva_noctua_qwen4b.sh`, `train_minerva_noctua_qwen8b.sh`
  - uses GRPO, ACR/ACRD, label details, and the local TextCNN model
  - rollout backend is `vllm`
- Plain GRPO:
  - `rlvr/cti-scripts/train_minerva_base_llama3b.sh`
  - `rlvr/cti-scripts/train_minerva_base_llama8b.sh`
  - `rlvr/cti-scripts/train_minerva_base_qwen4b.sh`
  - `rlvr/cti-scripts/train_minerva_base_qwen8b.sh`
  - uses `algorithm.adv_estimator=grpo` and `reward_minerva.py`
  - rollout backend is `vllm`
- DART SFT:
  - shared launcher: `rlvr/cti-scripts/train_minerva_sft.sh`
  - model wrappers under `dart/`
  - fixed train/validation data comes from `rlvr/mydata/sft/`
- Secondary or legacy paths still exist in the tree, but the repo-level supported flows are Noctua, plain GRPO, and DART SFT.

## Rebuilding Minerva training data
- This repo no longer keeps the full raw dataset caches by default.
- To rebuild Minerva from scratch, first restore or regenerate the builder inputs expected by `minerva/config.yaml`, including:
  - `dataset/nvd/`
  - `dataset/mitre/`
  - `dataset/capec/`
  - `dataset/cwe/`
  - `dataset/mappings-explorer/`
  - `dataset/sigma/`
  - `dataset/detection/`
- Common rebuild flow:
  - `python -m minerva.pipeline --config minerva/config.yaml --variant base --output-root dataset/minerva_base`
  - `python -m minerva.split --input-dir dataset/minerva_base --output-dir dataset/minerva_base_split --file-prefix minerva-base`
  - `python scripts/build_label_details.py`
  - `python rlvr/mydata/data_prepare/cti.py --data_dir dataset/minerva_base_split --out_dir rlvr/mydata/minerva_base`
- To regenerate Athena validation parquet files, place the Athena JSONLs alongside the Minerva split inputs before rerunning `cti.py`.

## Config and environment notes
- Main dataset config: `minerva/config.yaml`
- Useful env vars:
  - `NVD_API_KEY`
  - `NVD_DELAY_S`
- W&B output under `wandb/` is ignored at the repo root.

## Repo hygiene and gotchas
- Avoid hand-editing checked-in dataset files unless explicitly requested.
- `rlvr/` is large; do not assume the whole tree was synced from the source repo. The current curated path is the minimal set needed for Noctua, plain GRPO, and DART SFT.
- External CTI fetches can be slow and rate-limited. Prefer existing local caches when available.
- Be careful not to reintroduce removed runtime datasets such as old `seceval` validation files unless the user asks for them.

## Reference docs
- `README.md`
- `minerva/README.md`
- `docs/task-descriptions.md`
