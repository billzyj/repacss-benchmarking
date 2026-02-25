#!/bin/bash
# Example Slurm template for CPU partitions (Zen4) using adapter-first execution.
# Copy and adjust values for your benchmark.

#SBATCH --job-name=adapter_zen4
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err
#SBATCH --partition=zen4
#SBATCH --nodes=1
#SBATCH --ntasks=256
#SBATCH --cpus-per-task=1
#SBATCH --mem=0
#SBATCH --time=24:00:00

set -euo pipefail

# -------- Site-dependent defaults --------
ADAPTER_SITE="${ADAPTER_SITE:-repacss}"
PREPARE_METHOD="${PREPARE_METHOD:-module}"
DATASET_ROOT="${DATASET_ROOT:-$HOME/data}"
RUN_ROOT="${RUN_ROOT:-$DATASET_ROOT/runs}"
SITE_PROFILE="${SITE_PROFILE:-repacss_zen4}"

# -------- Site-independent benchmark intent --------
BENCH_ID="${BENCH_ID:-osu}"
DATASET_ID="${DATASET_ID:-small}"
EXPERIMENT_ID="${EXPERIMENT_ID:-template_zen4}"
RUN_ARGS="${RUN_ARGS:-osu_latency 2}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BENCH_DIR="$REPO_ROOT/benchmarks/$BENCH_ID"
PREPARE_SCRIPT="$BENCH_DIR/adapters/$ADAPTER_SITE/prepare.sh"
RUN_SCRIPT="$BENCH_DIR/adapters/$ADAPTER_SITE/run.sh"
PARSE_SCRIPT="$BENCH_DIR/adapters/$ADAPTER_SITE/parse.sh"

if [[ ! -x "$PREPARE_SCRIPT" || ! -x "$RUN_SCRIPT" ]]; then
  echo "Missing adapter scripts for benchmark=$BENCH_ID site=$ADAPTER_SITE"
  echo "Expected: $PREPARE_SCRIPT and $RUN_SCRIPT"
  exit 1
fi

echo "[template] BENCH_ID=$BENCH_ID ADAPTER_SITE=$ADAPTER_SITE DATASET_ID=$DATASET_ID"
echo "[template] DATASET_ROOT=$DATASET_ROOT"
echo "[template] RUN_ROOT=$RUN_ROOT EXPERIMENT_ID=$EXPERIMENT_ID SITE_PROFILE=$SITE_PROFILE"

# Optional site environment setup (mirror sites/repacss_zen4.yaml)
source ~/.bashrc
ml load mpich/4.1.2 pmix/5.0.3 || true

# Prepare runtime (module/spack/source)
"$PREPARE_SCRIPT" "$PREPARE_METHOD"

# Execute benchmark adapter
# shellcheck disable=SC2086
"$RUN_SCRIPT" $RUN_ARGS
