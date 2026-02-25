#!/bin/bash
# Run HPL on REPACSS with a unified run artifact contract.
set -euo pipefail

if [[ "$#" -lt 2 ]]; then
  echo "Usage: $0 <np> <hpl_dat> [extra-mpirun-args...]"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$BENCH_DIR/../common/repacss_contract.sh"

NP="$1"
HPL_DAT="$2"
shift 2

DATASET_ID="${DATASET_ID:-small}"
repacss_make_run_dirs "hpl" "${SITE_PROFILE:-repacss_zen4}"
repacss_write_context "hpl" "launcher" "$DATASET_ID"
repacss_init_normalized_artifacts "hpl" "High Performance Linpack" "$DATASET_ID"

if ! command -v xhpl >/dev/null 2>&1; then
  echo "Error: 'xhpl' not found on PATH."
  echo "Load it via 'module load hpl' or 'spack load hpl',"
  echo "or install from source and add its bin directory to PATH."
  exit 1
fi

if [[ ! -f "$HPL_DAT" ]]; then
  echo "Error: HPL.dat not found at: $HPL_DAT"
  exit 1
fi

WORK_DIR="${RAW_DIR}/work"
RUN_LOG="${RAW_DIR}/hpl.stdout.log"
mkdir -p "$WORK_DIR"
cp "$HPL_DAT" "$WORK_DIR/HPL.dat"

echo "$(repacss_iso8601_utc),run,input_file,${HPL_DAT}" >> "${NORM_DIR}/decisions.csv"
echo "$(repacss_iso8601_utc),run,np=${NP},from adapter argument" >> "${NORM_DIR}/decisions.csv"

echo "[hpl] RUN_DIR=$RUN_DIR"
echo "[hpl] Running xhpl with np=$NP on hosts: ${SLURM_NODELIST:-local}"
echo "[hpl] Command: mpirun -np $NP xhpl $*"

start_epoch="$(date +%s)"
(
  cd "$WORK_DIR"
  mpirun -np "$NP" xhpl "$@"
) 2>&1 | tee "$RUN_LOG"
end_epoch="$(date +%s)"

runtime_sec=$((end_epoch - start_epoch))
echo "$(repacss_iso8601_utc),run,runtime_seconds,${runtime_sec},s,mpirun wall-clock" >> "${NORM_DIR}/telemetry.csv"

"$SCRIPT_DIR/parse.sh" "$RUN_DIR" "${NORM_DIR}/summary.json"
echo "[hpl] Completed. Artifacts: $RUN_DIR"
