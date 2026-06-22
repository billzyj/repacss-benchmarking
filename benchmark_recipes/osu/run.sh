#!/bin/bash
# Run OSU Micro-Benchmarks on REPACSS with a unified run artifact contract.
set -euo pipefail

if [[ "$#" -lt 2 ]]; then
  echo "Usage: $0 <benchmark> <np> [extra-mpirun-args...]"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BENCH_DIR="$SCRIPT_DIR"
source "$REPO_ROOT/repacss_runtime/artifacts.sh"

BENCH="$1"
NP="$2"
shift 2

DATASET_ID="${DATASET_ID:-small}"
repacss_make_run_dirs "osu" "${SITE_PROFILE:-repacss_zen4}"
repacss_write_context "osu" "launcher" "$DATASET_ID"
repacss_init_normalized_artifacts "osu" "OSU Micro-Benchmarks" "$DATASET_ID"

if ! command -v "$BENCH" >/dev/null 2>&1; then
  echo "Error: '$BENCH' not found on PATH."
  echo "Use './install.sh source' or './install.sh spack', then add the OSU binary directory to PATH."
  echo "Use './install.sh module' only for REPACSS compiler and MPI dependency modules."
  exit 1
fi

RUN_LOG="${RAW_DIR}/osu.${BENCH}.log"
echo "$(repacss_iso8601_utc),run,benchmark=${BENCH},from recipe argument" >> "${NORM_DIR}/decisions.csv"
echo "$(repacss_iso8601_utc),run,np=${NP},from recipe argument" >> "${NORM_DIR}/decisions.csv"

echo "[osu] RUN_DIR=$RUN_DIR"
echo "[osu] Running $BENCH with np=$NP on hosts: ${SLURM_NODELIST:-local}"
echo "[osu] Command: mpirun -np $NP $BENCH $*"

start_epoch="$(date +%s)"
mpirun -np "$NP" "$BENCH" "$@" 2>&1 | tee "$RUN_LOG"
end_epoch="$(date +%s)"

runtime_sec=$((end_epoch - start_epoch))
echo "$(repacss_iso8601_utc),run,runtime_seconds,${runtime_sec},s,mpirun wall-clock" >> "${NORM_DIR}/telemetry.csv"

"$SCRIPT_DIR/parse.sh" "$RUN_DIR" "${NORM_DIR}/summary.json"
repacss_finalize_normalized_artifacts "success"
echo "[osu] Completed. Artifacts: $RUN_DIR"
