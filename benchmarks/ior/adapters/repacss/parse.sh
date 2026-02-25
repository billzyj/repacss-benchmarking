#!/bin/bash
set -euo pipefail

LOG_PATH="${1:-}"
OUT_PATH="${2:-summary.json}"

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "ior",
  "status": "wip",
  "source_log": "${LOG_PATH}",
  "note": "Implement IOR parse normalization here."
}
JSON

echo "[ior] Wrote placeholder summary to $OUT_PATH"
