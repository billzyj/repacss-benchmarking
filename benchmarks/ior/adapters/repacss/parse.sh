#!/bin/bash
set -euo pipefail

INPUT_PATH="${1:-}"
OUT_PATH="${2:-}"

if [[ -d "$INPUT_PATH" ]]; then
  RUN_DIR="$INPUT_PATH"
  RAW_DIR="$RUN_DIR/raw"
  NORM_DIR="$RUN_DIR/normalized"
  OUT_PATH="${OUT_PATH:-$NORM_DIR/summary.json}"
  LOG_GLOB="$RAW_DIR/ior_logs/*.log"
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
best_bw=""
best_desc=""

for log_file in $LOG_GLOB; do
  [[ -f "$log_file" ]] || continue
  log_count=$((log_count + 1))

  base="$(basename "$log_file")"
  phase=""
  target=""
  blocksize=""
  xfersize=""
  np=""

  stem="${base%.log}"
  if [[ "$stem" == warm_* || "$stem" == cold_* ]]; then
    phase="${stem%%_*}"
    remain="${stem#${phase}_}"
    np_part="${remain##*_}"
    np="${np_part%p}"
    remain="${remain%_${np_part}}"
    xfersize="${remain##*_}"
    remain="${remain%_${xfersize}}"
    blocksize="${remain##*_}"
    target="${remain%_${blocksize}}"
  fi

  read -r max_write write_unit max_read read_unit < <(
    awk '
      /Max[[:space:]]+Write:/ {write=$3; wunit=$4}
      /Max[[:space:]]+Read:/  {read=$3; runit=$4}
      END {print write, wunit, read, runit}
    ' "$log_file"
  )

  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  details="file=${base};target=${target};np=${np};blocksize=${blocksize};xfersize=${xfersize}"

  if [[ -n "${max_write}" ]]; then
    echo "${ts},parse,write_bandwidth,${max_write},${write_unit:-MiB/s},${details}" >> "$NORM_DIR/telemetry.csv"
    parsed_rows=$((parsed_rows + 1))
    if awk -v a="${max_write}" -v b="${best_bw:-0}" 'BEGIN{exit !(a+0 > b+0)}'; then
      best_bw="${max_write}"
      best_desc="${phase}/${target}/np=${np}/bs=${blocksize}/xs=${xfersize}/write"
    fi
  fi
  if [[ -n "${max_read}" ]]; then
    echo "${ts},parse,read_bandwidth,${max_read},${read_unit:-MiB/s},${details}" >> "$NORM_DIR/telemetry.csv"
    parsed_rows=$((parsed_rows + 1))
    if awk -v a="${max_read}" -v b="${best_bw:-0}" 'BEGIN{exit !(a+0 > b+0)}'; then
      best_bw="${max_read}"
      best_desc="${phase}/${target}/np=${np}/bs=${blocksize}/xs=${xfersize}/read"
    fi
  fi
done

status="partial"
if [[ "$parsed_rows" -gt 0 ]]; then
  status="ok"
fi

cat > "$OUT_PATH" <<JSON
{
  "benchmark": "ior",
  "status": "${status}",
  "log_files_seen": ${log_count},
  "metrics_rows_written": ${parsed_rows},
  "best_bandwidth": "${best_bw}",
  "best_bandwidth_context": "${best_desc}"
}
JSON

echo "[ior] Wrote summary to $OUT_PATH"
