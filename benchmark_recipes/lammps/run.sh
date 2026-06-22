#!/bin/bash
#
# Slurm batch recipe for LAMMPS on REPACSS Zen4 using unified run artifacts.
#
# Optional environment variables:
# - DATASET_ID            (default: small)
# - DATASET_ROOT          (default: $HOME/data)
# - LAMMPS_INPUT          (override input file path)
# - LAMMPS_RANKS          (comma-separated, default: 256,224,192,160,128,96,64,48,32,24,16,12,8,4,2,1)
# - RUN_ROOT, EXPERIMENT_ID, SITE_PROFILE

#SBATCH --job-name=lammps_zen4_scaling
#SBATCH --partition=zen4
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=256
#SBATCH --time=24:00:00
#SBATCH --exclusive
#SBATCH --output=slurm-lammps.%j.out
#SBATCH --error=slurm-lammps.%j.err

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BENCH_DIR="$SCRIPT_DIR"
source "$REPO_ROOT/repacss_runtime/artifacts.sh"

DATASET_ID="${DATASET_ID:-small}"
DATASET_ROOT="${DATASET_ROOT:-$HOME/data}"
repacss_make_run_dirs "lammps" "${SITE_PROFILE:-repacss_zen4}"
repacss_write_context "lammps" "slurm_batch" "$DATASET_ID"
repacss_init_normalized_artifacts "lammps" "LAMMPS" "$DATASET_ID"

source ~/.bashrc
spack load lammps || true

LAMMPS_BIN="${LAMMPS_BIN:-lmp}"
if ! command -v "$LAMMPS_BIN" >/dev/null 2>&1; then
  echo "Error: ${LAMMPS_BIN} binary not found on PATH."
  echo "Use './install.sh spack' or './install.sh source', or set LAMMPS_BIN for your binary name."
  echo "Use './install.sh module' only for REPACSS compiler and MPI dependency modules."
  exit 1
fi

input_default=""
case "$DATASET_ID" in
  small)
    input_default="$BENCH_DIR/inputs/lj/in.lj"
    ;;
  production)
    input_default="$DATASET_ROOT/lammps/in.lj"
    ;;
  *)
    echo "Error: unsupported DATASET_ID '$DATASET_ID' (supported: small, production)."
    exit 1
    ;;
esac

INPUT_FILE="${LAMMPS_INPUT:-$input_default}"
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: LAMMPS input file not found: $INPUT_FILE"
  exit 1
fi

IFS=',' read -r -a ranks_list <<< "${LAMMPS_RANKS:-256,224,192,160,128,96,64,48,32,24,16,12,8,4,2,1}"

WORK_DIR="${RAW_DIR}/work"
mkdir -p "$WORK_DIR"
cp "$INPUT_FILE" "$WORK_DIR/in.lj"

echo "$(repacss_iso8601_utc),run,input_file,${INPUT_FILE}" >> "${NORM_DIR}/decisions.csv"
echo "$(repacss_iso8601_utc),run,ranks=${LAMMPS_RANKS:-256,224,192,160,128,96,64,48,32,24,16,12,8,4,2,1},from env" >> "${NORM_DIR}/decisions.csv"

echo "[lammps] RUN_DIR=$RUN_DIR"
echo "[lammps] Running on host: $(hostname)"
echo "[lammps] Job ID: ${SLURM_JOB_ID:-local}"
echo "[lammps] LAMMPS binary: $(command -v "$LAMMPS_BIN")"

job_start_epoch="$(date +%s)"

for nt in "${ranks_list[@]}"; do
  nt="$(echo "$nt" | xargs)"
  [[ -n "$nt" ]] || continue

  run_log="${RAW_DIR}/log.rank${nt}.lammps"
  start_epoch="$(date +%s)"
  (
    cd "$WORK_DIR"
    mpirun --bind-to core --map-by core -np "$nt" \
      "$LAMMPS_BIN" -in in.lj -l "$run_log"
  )
  end_epoch="$(date +%s)"

  echo "$(repacss_iso8601_utc),run,runtime_seconds,$((end_epoch - start_epoch)),s,np=${nt}" >> "${NORM_DIR}/telemetry.csv"
done

job_end_epoch="$(date +%s)"
echo "$(repacss_iso8601_utc),run,total_runtime_seconds,$((job_end_epoch - job_start_epoch)),s,lammps scaling batch runtime" >> "${NORM_DIR}/telemetry.csv"

"$SCRIPT_DIR/parse.sh" "$RUN_DIR" "${NORM_DIR}/summary.json"
repacss_finalize_normalized_artifacts "success"
echo "[lammps] Completed. Artifacts: $RUN_DIR"
