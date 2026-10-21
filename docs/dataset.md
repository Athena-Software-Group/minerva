# Minerva-CTI dataset preparation

Minerva-CTI is the dataset in [the Minerva paper](https://openreview.net/forum?id=w1IMu9exKC): **32,000 training examples and 1,200 validation examples across 16 tasks**. The checked-in runtime files are `dataset/minerva_base_split/minerva-base-{train,dev}.jsonl` and the corresponding parquet files in `rlvr/mydata/minerva_base/`.

## Sources and raw caches

The builder uses public CTI sources: NVD CVEs, MITRE ATT&CK, CAPEC, CWE, mappings-explorer, Sigma, Atomic Red Team, Microsoft Sentinel, and Splunk Security Content. Input paths and task options are configured in [`minerva/config.yaml`](../minerva/config.yaml).

Restore or regenerate the raw caches before rebuilding: `dataset/nvd/`, `dataset/mitre/`, `dataset/capec/`, `dataset/cwe/`, `dataset/mappings-explorer/`, `dataset/sigma/`, and `dataset/detection/`. The curated repository includes final runtime assets, not all raw inputs. `NVD_API_KEY` is optional and helps with NVD rate limits.

## Task counts

These counts match the checked-in JSONL splits and the current targets in [`minerva/split.py`](../minerva/split.py). Names below are the builder's task keys; scenario rows use the corresponding `scenario_to_attack_*` aliases.

| Task | Train | Validation |
| --- | ---: | ---: |
| `cve_to_attack_exploitation` | 245 | 20 |
| `cve_to_attack_primary_impact` | 210 | 20 |
| `cve_to_attack_secondary_impact` | 64 | 10 |
| `sigma_to_attack_technique` | 950 | 50 |
| `sigma_to_attack_tactics` | 950 | 50 |
| `art_to_attack_technique` | 950 | 50 |
| `sentinel_to_attack_technique` | 950 | 50 |
| `splunk_to_attack_technique` | 280 | 20 |
| `scenario_to_technique` | 7,780 | 220 |
| `scenario_to_tactics` | 1,950 | 50 |
| `scenario_to_mitigations` | 7,780 | 220 |
| `cve_to_cwe` | 6,696 | 220 |
| `cve_to_cvss_v31` | 1,900 | 100 |
| `threat_actor` | 779 | 60 |
| `capec_example_to_capec` | 340 | 40 |
| `capec_example_to_cwe` | 176 | 20 |
| **Total** | **32,000** | **1,200** |

The pipeline resamples to fixed per-task totals with seed 1337. The split step reserves the configured validation count for each task and assigns the remainder to training. Source-cache versions affect a fresh rebuild; use the checked-in runtime files for the released split.

CVSS v4.0 and CAPEC-to-ATT&CK builders are retained as optional utilities but have zero target samples in the released configuration. Legacy LHC candidate-pool augmentation is separate from the Minerva-CTI split used by MinervaRL.

## Rebuild and convert

After completing the [repository setup](../README.md#first-setup) and restoring the raw caches, run from the repository root:

```bash
source .venv/bin/activate

python -m minerva.pipeline \
  --config minerva/config.yaml \
  --variant base \
  --output-root dataset/minerva_base

python -m minerva.split \
  --input-dir dataset/minerva_base \
  --output-dir dataset/minerva_base_split \
  --file-prefix minerva-base

python -m scripts.build_label_details

python rlvr/mydata/data_prepare/cti.py \
  --data_dir dataset/minerva_base_split \
  --out_dir rlvr/mydata/minerva_base
```

The conversion preserves task-specific rewards and prepares the CTI prompts for VeRL. Label-detail construction writes the canonical reference store under `dataset/label_details/`, which the MinervaRL teacher uses during ACR generation. It does not require the removed TARBA retrieval service.

The AthenaBench-Mini validation parquets are already in `rlvr/mydata/athena/`. They contain 950 examples across six tasks, including 50 TAA examples. The [method guide](acrd.md#baselines-and-evaluation) explains their use for validation and overlap with final evaluation tasks.

See [task descriptions](task-descriptions.md) and the [dataset package guide](../minerva/README.md) for source and prompt details.
