#!/bin/bash
# Functional check of a GPU job report with a workload that needs no Python environment, dataset or container:
# one power:both job on an exclusive 4-GPU H100 node. BabelStream (CUDA, hbm-long profile, about 2.5 min) runs on one GPU
# between idle gaps, so the in-band report should show GPU energy with one GPU above idle and the OOB report the
# same node over the same window. It is not an overhead measurement.
# Build once before submitting (login or build node):
#   module load cuda/12.9.1 && bash benchmark_recipes/babelstream/install.sh source --execute
# Submit with --chdir="$OUT_ROOT" so report delivery lands next to the job's records:
#   OUT_ROOT=<dir> RECIPE_DIR=<this dir> sbatch --chdir="$OUT_ROOT" --export=ALL --reservation=llm \
#     --nodelist=rpg-93-8 h100_babelstream.sbatch
#SBATCH --job-name=profiling-h100-check
#SBATCH --partition=h100
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=480G
#SBATCH --gres=gpu:4
#SBATCH --exclusive
#SBATCH --time=00:20:00
#SBATCH --comment=power:both
set -euo pipefail
: "${OUT_ROOT:?}" "${RECIPE_DIR:?}"
PROFILE="${PROFILE:-hbm-long}"; REPS="${REPS:-1}"; GAP_S="${GAP_S:-60}"
MODE=h100-both
OUT="$OUT_ROOT/$SLURM_JOB_ID-$MODE"; mkdir -p "$OUT"; cd "$OUT"
source "$RECIPE_DIR/common.sh"
finish_job() {
  local status=$?
  record_runner runner.csv || true
  echo "job_end_unix=$(now)" >> job_info.txt
  echo "batch_exit_code=$status" >> job_info.txt
  return "$status"
}
trap finish_job EXIT
[[ -f /etc/profile.d/modules.sh ]] && source /etc/profile.d/modules.sh
module load "${GPU_CUDA_MODULE:-cuda/12.9.1}"
job_header > job_info.txt
echo "profile=$PROFILE repetitions=$REPS gap_s=$GAP_S" >> job_info.txt
record_runner runner_start.csv
sleep "$GAP_S"
t0=$(now)
# The recipe wrapper requires an explicit one-task step that sees exactly one GPU.
if RUN_ROOT="$OUT/runs" srun --ntasks=1 --cpus-per-task=8 --gpus-per-task=1 \
  bash "$RECIPE_DIR/../babelstream/run.sh" --profile "$PROFILE" --repetitions "$REPS" > babelstream.log 2>&1; then rc=0; else rc=$?; fi
t1=$(now)
echo "workload_start_unix=$t0 workload_end_unix=$t1 workload_rc=$rc" >> job_info.txt
sleep "$GAP_S"
exit "$rc"
