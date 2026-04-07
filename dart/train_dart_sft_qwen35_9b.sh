#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$REPO_ROOT/rlvr/cti-scripts/train_minerva_sft_qwen35_9b.sh" "$@"
