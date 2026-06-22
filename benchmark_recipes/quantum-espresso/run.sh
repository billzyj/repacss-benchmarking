#!/bin/bash
# Run Quantum Espresso on REPACSS with unified run artifact contract (WIP).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BENCH_DIR="$SCRIPT_DIR"
source "$REPO_ROOT/repacss_runtime/artifacts.sh"

DATASET_ID="${DATASET_ID:-small}"
DATASET_ROOT="${DATASET_ROOT:-$HOME/data}"
repacss_make_run_dirs "quantum_espresso" "${SITE_PROFILE:-repacss_zen4}"
repacss_write_context "quantum_espresso" "launcher" "$DATASET_ID"
repacss_init_normalized_artifacts "quantum_espresso" "Quantum Espresso" "$DATASET_ID"

NP="${QE_NP:-${SLURM_NTASKS:-1}}"
if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
  NP="$1"
  shift
fi

input_default=""
case "$DATASET_ID" in
  small)
    input_default="$BENCH_DIR/inputs/si/si_sssp.scf.in"
    ;;
  production)
    input_default="$DATASET_ROOT/quantum-espresso/si_long_md.in"
    ;;
  *)
    echo "Error: unsupported DATASET_ID '$DATASET_ID' (supported: small, production)."
    exit 1
    ;;
esac

INPUT_FILE="${QE_INPUT_FILE:-$input_default}"
if [[ -n "${1:-}" ]]; then
  INPUT_FILE="$1"
  shift
fi

echo "$(repacss_iso8601_utc),run,np=${NP},from env/args" >> "${NORM_DIR}/decisions.csv"
echo "$(repacss_iso8601_utc),run,input_file=${INPUT_FILE},resolved from dataset/profile args" >> "${NORM_DIR}/decisions.csv"

if ! command -v pw.x >/dev/null 2>&1; then
  echo "[qe] Error: pw.x not found on PATH." | tee "${RAW_DIR}/qe.stderr.log"
  echo "[qe] Use './install.sh spack' or './install.sh source', then add pw.x to PATH."
  echo "[qe] Use './install.sh module' only for REPACSS compiler, MPI, and BLAS dependency modules."
  exit 2
fi

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "[qe] Error: input file not found: $INPUT_FILE" | tee "${RAW_DIR}/qe.stderr.log"
  exit 2
fi

WORK_DIR="${RAW_DIR}/work"
mkdir -p "$WORK_DIR"
cp "$INPUT_FILE" "$WORK_DIR/input.in"

RUN_LOG="${RAW_DIR}/pw.out"
echo "[qe] RUN_DIR=$RUN_DIR"
echo "[qe] Command: mpirun -np $NP pw.x -in input.in"

start_epoch="$(date +%s)"
(
  cd "$WORK_DIR"
  mpirun -np "$NP" pw.x -in input.in
) 2>&1 | tee "$RUN_LOG"
end_epoch="$(date +%s)"

runtime_sec=$((end_epoch - start_epoch))
echo "$(repacss_iso8601_utc),run,runtime_seconds,${runtime_sec},s,pw.x wall-clock" >> "${NORM_DIR}/telemetry.csv"

"$SCRIPT_DIR/parse.sh" "$RUN_DIR" "${NORM_DIR}/summary.json"
repacss_finalize_normalized_artifacts "success"
echo "[qe] Completed. Artifacts: $RUN_DIR"
