#!/bin/bash
set -euo pipefail

INPUT_PATH="${1:-}"
OUT_PATH="${2:-}"

if [[ -d "$INPUT_PATH" ]]; then
  RUN_DIR="$INPUT_PATH"
  RAW_DIR="$RUN_DIR/raw"
  NORM_DIR="$RUN_DIR/normalized"
  OUT_PATH="${OUT_PATH:-$NORM_DIR/summary.json}"
  LOG_PATH="$RAW_DIR/pw.out"
else
  LOG_PATH="$INPUT_PATH"
  OUT_PATH="${OUT_PATH:-summary.json}"
  NORM_DIR="$(cd "$(dirname "$OUT_PATH")" && pwd)"
  mkdir -p "$NORM_DIR"
fi

mkdir -p "$NORM_DIR"
[[ -f "$NORM_DIR/telemetry.csv" ]] || echo "timestamp_utc,phase,metric,value,unit,details" > "$NORM_DIR/telemetry.csv"
[[ -f "$NORM_DIR/decisions.csv" ]] || echo "timestamp_utc,component,decision,reason" > "$NORM_DIR/decisions.csv"

total_energy_ry=""
job_done="false"
wall_time_line=""

if [[ -f "$LOG_PATH" ]]; then
  total_energy_ry="$(awk '/^!/ {energy=$5} END {print energy}' "$LOG_PATH")"
  if grep -q "JOB DONE" "$LOG_PATH"; then
    job_done="true"
  fi
  wall_time_line="$(grep -E 'PWSCF[[:space:]]*:' "$LOG_PATH" | tail -n 1 || true)"
fi

if [[ -n "${total_energy_ry}" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),parse,total_energy,${total_energy_ry},Ry,extracted from QE output" >> "$NORM_DIR/telemetry.csv"
fi

status="partial"
if [[ "${job_done}" == "true" ]]; then
  status="success"
fi

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "quantum_espresso",
  "status": "${status}",
  "source_log": "${LOG_PATH}",
  "job_done": ${job_done},
  "total_energy_ry": "${total_energy_ry}",
  "wall_time_line": "${wall_time_line}"
}
JSON

echo "[qe] Wrote summary to $OUT_PATH"
