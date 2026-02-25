#!/bin/bash
set -euo pipefail

LOG_PATH="${1:-}"
OUT_PATH="${2:-summary.json}"

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "lammps",
  "status": "wip",
  "source_log": "${LOG_PATH}",
  "note": "Implement LAMMPS parse normalization here."
}
JSON

echo "[lammps] Wrote placeholder summary to $OUT_PATH"
