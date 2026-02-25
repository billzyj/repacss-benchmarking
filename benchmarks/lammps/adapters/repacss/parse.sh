#!/bin/bash
set -euo pipefail

INPUT_PATH="${1:-}"
OUT_PATH="${2:-}"

if [[ -d "$INPUT_PATH" ]]; then
  RUN_DIR="$INPUT_PATH"
  RAW_DIR="$RUN_DIR/raw"
  NORM_DIR="$RUN_DIR/normalized"
  OUT_PATH="${OUT_PATH:-$NORM_DIR/summary.json}"
  LOG_GLOB="$RAW_DIR/log.rank*.lammps"
else
  LOG_GLOB="$INPUT_PATH"
  OUT_PATH="${OUT_PATH:-summary.json}"
  NORM_DIR="$(cd "$(dirname "$OUT_PATH")" && pwd)"
  mkdir -p "$NORM_DIR"
fi

mkdir -p "$NORM_DIR"
[[ -f "$NORM_DIR/telemetry.csv" ]] || echo "timestamp_utc,phase,metric,value,unit,details" > "$NORM_DIR/telemetry.csv"
[[ -f "$NORM_DIR/decisions.csv" ]] || echo "timestamp_utc,component,decision,reason" > "$NORM_DIR/decisions.csv"

log_count=0
parsed_rows=0
best_runtime=""
best_np=""

for log_file in $LOG_GLOB; do
  [[ -f "$log_file" ]] || continue
  log_count=$((log_count + 1))
  np="$(basename "$log_file" | sed -E 's/^log\.rank([0-9]+)\.lammps$/\1/')"

  read -r loop_time steps atoms ns_day < <(
    awk '
      /Loop time of/ {
        for (i = 1; i <= NF; i++) {
          if ($i == "of") loop_time=$(i+1)
          if ($i == "for") steps=$(i+1)
          if ($i == "with") atoms=$(i+1)
        }
      }
      /Performance:/ {ns_day=$2}
      END {print loop_time, steps, atoms, ns_day}
    ' "$log_file"
  )

  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  details="np=${np};file=$(basename "$log_file")"

  if [[ -n "${loop_time}" ]]; then
    echo "${ts},parse,loop_time_seconds,${loop_time},s,${details};steps=${steps};atoms=${atoms}" >> "$NORM_DIR/telemetry.csv"
    parsed_rows=$((parsed_rows + 1))
    if [[ -z "${best_runtime}" ]] || awk -v a="$loop_time" -v b="$best_runtime" 'BEGIN{exit !(a+0 < b+0)}'; then
      best_runtime="$loop_time"
      best_np="$np"
    fi
  fi
  if [[ -n "${ns_day}" ]]; then
    echo "${ts},parse,performance_ns_per_day,${ns_day},ns/day,${details}" >> "$NORM_DIR/telemetry.csv"
    parsed_rows=$((parsed_rows + 1))
  fi
done

status="partial"
if [[ "$parsed_rows" -gt 0 ]]; then
  status="ok"
fi

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "lammps",
  "status": "${status}",
  "log_files_seen": ${log_count},
  "metrics_rows_written": ${parsed_rows},
  "best_loop_time_seconds": "${best_runtime}",
  "best_np": "${best_np}"
}
JSON

echo "[lammps] Wrote summary to $OUT_PATH"
