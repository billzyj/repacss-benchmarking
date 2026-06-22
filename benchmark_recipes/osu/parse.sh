#!/bin/bash
set -euo pipefail

INPUT_PATH="${1:-}"
OUT_PATH="${2:-}"

if [[ -d "$INPUT_PATH" ]]; then
  RUN_DIR="$INPUT_PATH"
  RAW_DIR="$RUN_DIR/raw"
  NORM_DIR="$RUN_DIR/normalized"
  OUT_PATH="${OUT_PATH:-$NORM_DIR/summary.json}"
  LOG_PATH="$(find "$RAW_DIR" -maxdepth 1 -type f -name 'osu.*.log' | sort | tail -n 1)"
else
  LOG_PATH="$INPUT_PATH"
  OUT_PATH="${OUT_PATH:-summary.json}"
  NORM_DIR="$(cd "$(dirname "$OUT_PATH")" && pwd)"
  mkdir -p "$NORM_DIR"
fi

mkdir -p "$NORM_DIR"
[[ -f "$NORM_DIR/telemetry.csv" ]] || echo "timestamp_utc,phase,metric,value,unit,details" > "$NORM_DIR/telemetry.csv"
[[ -f "$NORM_DIR/decisions.csv" ]] || echo "timestamp_utc,component,decision,reason" > "$NORM_DIR/decisions.csv"

bench_name=""
last_size=""
last_value=""

if [[ -n "${LOG_PATH:-}" && -f "$LOG_PATH" ]]; then
  bench_name="$(basename "$LOG_PATH" | sed -E 's/^osu\.([^.]+)\.log$/\1/')"
  read -r last_size last_value < <(
    awk '
      $1 ~ /^[0-9]+$/ && $2 ~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ {
        size=$1; value=$2
      }
      END {print size, value}
    ' "$LOG_PATH"
  )
fi

metric_name="value"
metric_unit="unknown"
if [[ "$bench_name" =~ bw ]]; then
  metric_name="bandwidth"
  metric_unit="MB/s"
elif [[ "$bench_name" =~ latency ]]; then
  metric_name="latency"
  metric_unit="us"
fi

if [[ -n "${last_value}" ]]; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),parse,${metric_name},${last_value},${metric_unit},message_size=${last_size}" >> "$NORM_DIR/telemetry.csv"
fi

status="partial"
if [[ -n "${last_value}" ]]; then
  status="success"
fi

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "osu",
  "status": "${status}",
  "source_log": "${LOG_PATH:-}",
  "benchmark_name": "${bench_name}",
  "last_message_size": "${last_size}",
  "last_value": "${last_value}",
  "metric": "${metric_name}",
  "unit": "${metric_unit}"
}
JSON

echo "[osu] Wrote summary to $OUT_PATH"
