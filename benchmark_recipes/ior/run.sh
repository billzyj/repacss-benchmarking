#!/bin/bash
#
# Slurm batch recipe for IOR on REPACSS Zen4 using unified run artifacts.
#
# Optional environment variables:
# - DATASET_ID            (default: production)
# - DATASET_ROOT          (default: $HOME/data)
# - RUN_ROOT              (default: ${DATASET_ROOT}/runs)
# - EXPERIMENT_ID         (default: manual)
# - SITE_PROFILE          (default: repacss_zen4)
# - MEM_IO                (default: /dev/shm/$USER/ior)
# - LOCAL_IO              (default: <RUN_DIR>/local_io)
# - NFS_IO                (default: ${DATASET_ROOT}/ior_nfs)
# - IOR_NUM_RUNS          (default: 1)
# - IOR_XFERSIZES         (comma-separated, default: 16k,1m,16m)
# - IOR_NUM_PROCS         (comma-separated, default: 1,64,256)
# - IOR_BLOCKSIZES        (comma-separated, default: 64g,1g,256m)
# - IOR_TARGETS           (comma-separated var names, default: MEM_IO,LOCAL_IO,NFS_IO)

#SBATCH --job-name=ior_zen4
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err
#SBATCH --partition=zen4
#SBATCH --nodes=1
#SBATCH --ntasks=256
#SBATCH --cpus-per-task=1
#SBATCH --mem=0
#SBATCH --time=24:00:00

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BENCH_DIR="$SCRIPT_DIR"
source "$REPO_ROOT/repacss_runtime/artifacts.sh"

DATASET_ID="${DATASET_ID:-production}"
DATASET_ROOT="${DATASET_ROOT:-$HOME/data}"
repacss_make_run_dirs "ior" "${SITE_PROFILE:-repacss_zen4}"
repacss_write_context "ior" "slurm_batch" "$DATASET_ID"
repacss_init_normalized_artifacts "ior" "IOR" "$DATASET_ID"

echo "===== IOR job ${SLURM_JOB_ID:-local} on ${SLURM_NODELIST:-local} ====="
echo "[ior] RUN_DIR=$RUN_DIR"

source ~/.bashrc
if command -v module >/dev/null 2>&1; then
  module load mpich/4.3.2 || module load openmpi/4.1.8 || true
elif command -v ml >/dev/null 2>&1; then
  ml load mpich/4.3.2 || ml load openmpi/4.1.8 || true
fi
export PMIX_MCA_psec=none
spack load ior || true

if ! command -v ior >/dev/null 2>&1; then
  echo "Error: ior binary not found on PATH."
  echo "Use './install.sh spack' or './install.sh source', then add ior to PATH."
  exit 1
fi

IOR_BIN="$(command -v ior)"
LOGDIR="${RAW_DIR}/ior_logs"
mkdir -p "$LOGDIR"

MEM_IO="${MEM_IO:-/dev/shm/${USER}/ior}"
LOCAL_IO="${LOCAL_IO:-${RUN_DIR}/local_io}"
NFS_IO="${NFS_IO:-${DATASET_ROOT}/ior_nfs}"

IFS=',' read -r -a TARGETS <<< "${IOR_TARGETS:-MEM_IO,LOCAL_IO,NFS_IO}"
IFS=',' read -r -a XFERSIZES <<< "${IOR_XFERSIZES:-16k,1m,16m}"
IFS=',' read -r -a NUM_PROCS <<< "${IOR_NUM_PROCS:-1,64,256}"
IFS=',' read -r -a BLOCKSIZES <<< "${IOR_BLOCKSIZES:-64g,1g,256m}"
IOR_NUM_RUNS="${IOR_NUM_RUNS:-1}"

if [[ "${#NUM_PROCS[@]}" -ne "${#BLOCKSIZES[@]}" ]]; then
  echo "Error: IOR_NUM_PROCS and IOR_BLOCKSIZES must have same length."
  exit 1
fi

echo "$(repacss_iso8601_utc),run,targets=${IOR_TARGETS:-MEM_IO,LOCAL_IO,NFS_IO},from env" >> "${NORM_DIR}/decisions.csv"
echo "$(repacss_iso8601_utc),run,xfersizes=${IOR_XFERSIZES:-16k,1m,16m},from env" >> "${NORM_DIR}/decisions.csv"
echo "$(repacss_iso8601_utc),run,num_procs=${IOR_NUM_PROCS:-1,64,256},from env" >> "${NORM_DIR}/decisions.csv"
echo "$(repacss_iso8601_utc),run,blocksizes=${IOR_BLOCKSIZES:-64g,1g,256m},from env" >> "${NORM_DIR}/decisions.csv"

job_start_epoch="$(date +%s)"

for target_var in "${TARGETS[@]}"; do
  target_var="$(echo "$target_var" | xargs)"
  target_dir="${!target_var:-}"
  if [[ -z "$target_dir" ]]; then
    echo "Error: unresolved target var '$target_var'."
    exit 1
  fi
  mkdir -p "$target_dir"

  for xfersize in "${XFERSIZES[@]}"; do
    for idx in "${!NUM_PROCS[@]}"; do
      np="${NUM_PROCS[$idx]}"
      blocksize="${BLOCKSIZES[$idx]}"

      warm_file="${target_dir}/iorfile_${SLURM_JOB_ID:-local}_warm_${blocksize}_${xfersize}_${np}p"
      cold_file="${target_dir}/iorfile_${SLURM_JOB_ID:-local}_cold_${blocksize}_${xfersize}_${np}p"

      warm_log="${LOGDIR}/warm_${target_var,,}_${blocksize}_${xfersize}_${np}p.log"
      cold_log="${LOGDIR}/cold_${target_var,,}_${blocksize}_${xfersize}_${np}p.log"

      echo "[$(date)] Warm run: ${target_var} XS=${xfersize} NP=${np} BS=${blocksize}"
      start_epoch="$(date +%s)"
      mpirun -np "$np" "$IOR_BIN" -a POSIX -C -w -r -e \
        -t "$xfersize" -b "$blocksize" -i "$IOR_NUM_RUNS" \
        -o "$warm_file" > "$warm_log" 2>&1
      end_epoch="$(date +%s)"
      echo "$(repacss_iso8601_utc),run,warm_runtime_seconds,$((end_epoch - start_epoch)),s,target=${target_var};np=${np};bs=${blocksize};xs=${xfersize}" >> "${NORM_DIR}/telemetry.csv"

      if [[ "$target_var" != "MEM_IO" ]]; then
        echo "[$(date)] Cold run: ${target_var} XS=${xfersize} NP=${np} BS=${blocksize}"
        start_epoch="$(date +%s)"
        mpirun -np "$np" "$IOR_BIN" -a POSIX -C -w -r -e \
          -t "$xfersize" -b "$blocksize" -i "$IOR_NUM_RUNS" -O useO_DIRECT=1 \
          -o "$cold_file" > "$cold_log" 2>&1
        end_epoch="$(date +%s)"
        echo "$(repacss_iso8601_utc),run,cold_runtime_seconds,$((end_epoch - start_epoch)),s,target=${target_var};np=${np};bs=${blocksize};xs=${xfersize}" >> "${NORM_DIR}/telemetry.csv"
      fi

      rm -f "$warm_file" "$cold_file"
    done
  done
done

job_end_epoch="$(date +%s)"
echo "$(repacss_iso8601_utc),run,total_runtime_seconds,$((job_end_epoch - job_start_epoch)),s,ior batch runtime" >> "${NORM_DIR}/telemetry.csv"

"$SCRIPT_DIR/parse.sh" "$RUN_DIR" "${NORM_DIR}/summary.json"
repacss_finalize_normalized_artifacts "success"
echo "[ior] Completed. Artifacts: $RUN_DIR"
