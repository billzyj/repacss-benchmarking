#!/bin/bash
set -euo pipefail

LOG_PATH="${1:-}"
OUT_PATH="${2:-summary.json}"

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "hpl",
  "status": "wip",
  "source_log": "${LOG_PATH}",
  "note": "Implement HPL parse normalization here."
}
JSON

echo "[hpl] Wrote placeholder summary to $OUT_PATH"
