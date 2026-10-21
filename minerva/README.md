# Minerva-CTI dataset pipeline

This package constructs Minerva-CTI, the dataset used by MinervaRL in [the paper](https://openreview.net/forum?id=w1IMu9exKC). The training method is implemented in [`rlvr/`](../rlvr/); see the [MinervaRL guide](../docs/acrd.md).

## Released dataset

The released split has **32,000 training examples and 1,200 validation examples across 16 tasks**, covering CVE-to-ATT&CK mappings, Sigma/Atomic Red Team/Sentinel/Splunk technique mappings, scenario-to-technique/tactic/mitigation mappings, CVE-to-CWE and CVSS v3.1, threat-actor attribution, and CAPEC example-to-CAPEC/CWE mappings.

Builder outputs live under `dataset/minerva_base/`; the checked-in JSONL splits are in `dataset/minerva_base_split/`, and training parquets are in `rlvr/mydata/minerva_base/`. See [dataset preparation](../docs/dataset.md) for the per-task counts and raw-cache requirements.

## Run it

Use the [root setup instructions](../README.md#first-setup), restore the required source caches, then run:

```bash
source .venv/bin/activate
python -m minerva.pipeline --config minerva/config.yaml --variant base --output-root dataset/minerva_base
python -m minerva.split --input-dir dataset/minerva_base --output-dir dataset/minerva_base_split --file-prefix minerva-base
```

The prompt reference below also includes optional legacy builders (CVSS v4.0, detection strategies, and CAPEC-to-ATT&CK) that are outside the released 16-task split.

## Prompt references

### Mapping-explorer (CVE → ATT&CK)
- **Exploitation Technique / Primary Impact / Secondary Impact**
```
Given the vulnerability description below, output the single most appropriate MITRE ATT&CK Enterprise technique ID for:

<task-specific line>

Requirements:
- Use MITRE ATT&CK Enterprise technique IDs only.
- Return exactly ONE technique ID.
- Prefer a sub-technique ID (e.g., T1059.003) if it is more suitable; otherwise return the parent technique ID (e.g., T1059).

Vulnerability description:
{CVE_DESCRIPTION}
```
`<task-specific line>` is one of:
- Exploitation Technique - the method (technique) used to exploit the vulnerability.
- Primary Impact - the initial benefit (impact) gained through exploitation of the vulnerability.
- Secondary Impact - what the adversary can do by gaining the benefit of the primary impact. (Includes primary impact ID in the prompt.)

### CVE (NVD)
- **CVE → CWE**: `Given the Common Vulnerabilities and Exposures (CVE) description below, list EXACTLY {COUNT} Common Weakness Enumeration (CWE) ID{S_SUFFIX} in CWE-<number> format.`
- **CVE → CVSS v3.1**: `Given the Common Vulnerabilities and Exposures (CVE) description below, provide the CVSS v3.1 base vector string (format: CVSS:3.1/AV:X/AC:X/PR:X/UI:X/S:X/C:X/I:X/A:X).`
- **CVE → CVSS v4.0**: `Given the Common Vulnerabilities and Exposures (CVE) description below, provide the CVSS v4.0 base vector string (format: CVSS:4.0/AV:X/AC:X/AT:X/PR:X/UI:X/VC:X/VI:X/VA:X/SC:X/SI:X/SA:X).`

### Sigma → ATT&CK
- **Technique**: single ATT&CK technique ID (with requirements block; prefers sub-techniques).
- **Tactics**: list all applicable ATT&CK tactic IDs (TA000x) (with requirements block).

### Procedure scenarios → ATT&CK
- **Technique**: single ATT&CK technique ID (requirements block; prefers sub-techniques).
- **Tactics/Mitigations**: list EXACTLY the count provided per row (requirements block).
- **Detection Strategy**: single ATT&CK detection strategy ID (DET####) with requirements block.

### CAPEC examples
- **Example → CAPEC ID**: single CAPEC-<number>.
- **Example → CWE IDs**: EXACTLY the provided count of CWE-<number> IDs (up to 3).
- **Example → ATT&CK technique**: single ATT&CK technique ID (requirements block; prefers sub-techniques) when only one technique mapping exists.

### Threat actor MCQ
```
Given the observed adversary procedures below, choose the most likely threat actor.

Observed procedures:
{PROCEDURE_LIST}

Select the correct option (A-E) and return the option letter.

Options:
{OPTIONS_TEXT}
```
Multiple variants are generated per actor alias by resampling procedures and shuffling options.
