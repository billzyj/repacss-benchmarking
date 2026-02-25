#!/bin/bash
set -euo pipefail

LOG_PATH="${1:-}"
OUT_PATH="${2:-summary.json}"

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "quantum_espresso",
  "status": "wip",
  "source_log": "${LOG_PATH}",
  "note": "Implement Quantum Espresso parse normalization here."
}
JSON

echo "[qe] Wrote placeholder summary to $OUT_PATH"
