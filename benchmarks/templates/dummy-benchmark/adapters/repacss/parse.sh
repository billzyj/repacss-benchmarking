#!/bin/bash
# Template parse adapter for REPACSS with normalized artifact contract.
set -euo pipefail

INPUT_PATH="${1:-}"
OUT_PATH="${2:-}"

if [[ -d "$INPUT_PATH" ]]; then
  RUN_DIR="$INPUT_PATH"
  RAW_DIR="$RUN_DIR/raw"
  NORM_DIR="$RUN_DIR/normalized"
  OUT_PATH="${OUT_PATH:-$NORM_DIR/summary.json}"
  LOG_PATH="$RAW_DIR/dummy.log"
else
  LOG_PATH="$INPUT_PATH"
  OUT_PATH="${OUT_PATH:-summary.json}"
  NORM_DIR="$(cd "$(dirname "$OUT_PATH")" && pwd)"
  mkdir -p "$NORM_DIR"
fi

if [[ ! -f "${NORM_DIR}/meta.json" ]]; then
  cat > "${NORM_DIR}/meta.json" <<JSON
{
  "benchmark": "dummy",
  "dataset_id": "${DATASET_ID:-unknown}",
  "status": "standalone_parse"
}
JSON
fi

if [[ ! -f "${NORM_DIR}/telemetry.csv" ]]; then
  cat > "${NORM_DIR}/telemetry.csv" <<CSV
timestamp_utc,phase,metric,value,unit,details
CSV
fi

if [[ ! -f "${NORM_DIR}/decisions.csv" ]]; then
  cat > "${NORM_DIR}/decisions.csv" <<CSV
timestamp_utc,component,decision,reason
CSV
fi

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "dummy",
  "dataset_id": "${DATASET_ID:-unknown}",
  "source_log": "${LOG_PATH}",
  "status": "wip",
  "note": "Implement benchmark-specific parsing and metric normalization here."
}
JSON

echo "[dummy] Wrote summary to $OUT_PATH"
