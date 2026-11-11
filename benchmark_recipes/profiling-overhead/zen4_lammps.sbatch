#!/bin/bash
# One overhead job on an exclusive Zen4 node: idle, then RUNS LAMMPS LJ runs (32,000 atoms, STEPS steps, 256 ranks,
# one per core, socket 0 first). The profiling mode is set by the job comment (--comment on the sbatch line);
# MODE only labels the output. Writes job_info.txt, runs.csv and runner.csv into $OUT.
#SBATCH --job-name=ovh-zen4
#SBATCH --partition=zen4
#SBATCH --nodes=1
#SBATCH --ntasks=256
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --mem=0
#SBATCH --time=00:30:00
set -euo pipefail
: "${MODE:?}" "${OUT_ROOT:?}" "${RECIPE_DIR:?}"
RUNS="${RUNS:-2}"; STEPS="${STEPS:-800000}"; GAP_S="${GAP_S:-30}"; NP="${NP:-256}"
CPU_RECIPE="$RECIPE_DIR"
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
source "$CPU_RECIPE/env.sh"; cpu_modules; cpu_runtime_env
job_header > job_info.txt
record_runner runner_start.csv
echo "boost=$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null) governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" >> job_info.txt
sed -e "s/^run.*/run		$STEPS/" -e '/^restart/d' "$CPU_RECIPE/inputs/in.lj" > in.lj
echo "run,start_unix,end_unix,wall_s,loop_s,returncode" > runs.csv
failed=0
for i in $(seq 1 "$RUNS"); do
  sleep "$GAP_S"
  t0=$(now)
  if cpu_srun "$NP" lmp -in in.lj -log "log.$i" -screen none > "stdout.$i" 2>&1; then rc=0; else rc=$?; fi
  t1=$(now)
  loop=$(awk '/^Loop time/ {print $4}' "log.$i" 2>/dev/null || true)
  if [[ "$rc" != 0 || -z "$loop" ]]; then failed=1; fi
  echo "$i,$t0,$t1,$(awk -v a="$t0" -v b="$t1" 'BEGIN {printf "%.3f", b - a}'),$loop,$rc" >> runs.csv
done
exit "$failed"
