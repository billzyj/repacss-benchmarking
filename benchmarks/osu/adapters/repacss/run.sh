#!/bin/bash
# Run OSU Micro-Benchmarks on REPACSS with a unified run artifact contract.
set -euo pipefail

if [[ "$#" -lt 2 ]]; then
  echo "Usage: $0 <benchmark> <np> [extra-mpirun-args...]"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$BENCH_DIR/../common/repacss_contract.sh"

BENCH="$1"
NP="$2"
shift 2

DATASET_ID="${DATASET_ID:-small}"
repacss_make_run_dirs "osu" "${SITE_PROFILE:-repacss_zen4}"
repacss_write_context "osu" "launcher" "$DATASET_ID"
repacss_init_normalized_artifacts "osu" "OSU Micro-Benchmarks" "$DATASET_ID"

if ! command -v "$BENCH" >/dev/null 2>&1; then
  echo "Error: '$BENCH' not found on PATH."
  echo "Load it via 'module load osu-micro-benchmarks' or 'spack load osu-micro-benchmarks',"
  echo "or install from source and add its bin directory to PATH."
  exit 1
fi

RUN_LOG="${RAW_DIR}/osu.${BENCH}.log"
echo "$(repacss_iso8601_utc),run,benchmark=${BENCH},from adapter argument" >> "${NORM_DIR}/decisions.csv"
echo "$(repacss_iso8601_utc),run,np=${NP},from adapter argument" >> "${NORM_DIR}/decisions.csv"

echo "[osu] RUN_DIR=$RUN_DIR"
echo "[osu] Running $BENCH with np=$NP on hosts: ${SLURM_NODELIST:-local}"
echo "[osu] Command: mpirun -np $NP $BENCH $*"

start_epoch="$(date +%s)"
mpirun -np "$NP" "$BENCH" "$@" 2>&1 | tee "$RUN_LOG"
end_epoch="$(date +%s)"

runtime_sec=$((end_epoch - start_epoch))
echo "$(repacss_iso8601_utc),run,runtime_seconds,${runtime_sec},s,mpirun wall-clock" >> "${NORM_DIR}/telemetry.csv"

"$SCRIPT_DIR/parse.sh" "$RUN_DIR" "${NORM_DIR}/summary.json"
echo "[osu] Completed. Artifacts: $RUN_DIR"
