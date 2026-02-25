#!/bin/bash
set -euo pipefail

INPUT_PATH="${1:-}"
OUT_PATH="${2:-}"

if [[ -d "$INPUT_PATH" ]]; then
  RUN_DIR="$INPUT_PATH"
  RAW_DIR="$RUN_DIR/raw"
  NORM_DIR="$RUN_DIR/normalized"
  OUT_PATH="${OUT_PATH:-$NORM_DIR/summary.json}"
  LOG_PATH="$RAW_DIR/hpl.stdout.log"
else
  LOG_PATH="$INPUT_PATH"
  OUT_PATH="${OUT_PATH:-summary.json}"
  NORM_DIR="$(cd "$(dirname "$OUT_PATH")" && pwd)"
  mkdir -p "$NORM_DIR"
fi

mkdir -p "$NORM_DIR"
[[ -f "$NORM_DIR/telemetry.csv" ]] || echo "timestamp_utc,phase,metric,value,unit,details" > "$NORM_DIR/telemetry.csv"
[[ -f "$NORM_DIR/decisions.csv" ]] || echo "timestamp_utc,component,decision,reason" > "$NORM_DIR/decisions.csv"

runtime_sec=""
gflops=""

if [[ -f "$LOG_PATH" ]]; then
  read -r runtime_sec gflops < <(
    awk '
      $1 ~ /^WR/ && NF >= 2 {rt=$(NF-1); gf=$NF}
      END {print rt, gf}
    ' "$LOG_PATH"
  )
fi

if [[ -n "${gflops}" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),parse,gflops,${gflops},GFLOP/s,extracted from WR line" >> "$NORM_DIR/telemetry.csv"
fi
if [[ -n "${runtime_sec}" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),parse,solver_time_seconds,${runtime_sec},s,extracted from WR line" >> "$NORM_DIR/telemetry.csv"
fi

status="partial"
if [[ -n "${gflops}" || -n "${runtime_sec}" ]]; then
  status="ok"
fi

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "hpl",
  "status": "${status}",
  "source_log": "${LOG_PATH}",
  "runtime_seconds": "${runtime_sec}",
  "gflops": "${gflops}"
}
JSON

echo "[hpl] Wrote summary to $OUT_PATH"
