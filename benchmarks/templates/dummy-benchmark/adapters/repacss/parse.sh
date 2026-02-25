#!/bin/bash
# Template parse adapter for REPACSS.
set -euo pipefail

LOG_PATH="${1:-}"
OUT_PATH="${2:-summary.json}"

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "dummy",
  "dataset_id": "${DATASET_ID:-unknown}",
  "source_log": "${LOG_PATH}",
  "status": "wip",
  "note": "Implement benchmark-specific parsing and metric normalization here."
}
JSON

echo "[dummy] Wrote placeholder summary to $OUT_PATH"
