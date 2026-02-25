#!/bin/bash
# Example Slurm template for GPU partitions (H100) using adapter-first execution.
# Copy and adjust values for your benchmark.

#SBATCH --job-name=adapter_h100
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err
#SBATCH --partition=h100
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:4
#SBATCH --mem=0
#SBATCH --time=01:00:00

set -euo pipefail

# -------- Site-dependent defaults --------
ADAPTER_SITE="${ADAPTER_SITE:-repacss}"
PREPARE_METHOD="${PREPARE_METHOD:-module}"
DATASET_ROOT="${DATASET_ROOT:-$HOME/data}"
RUN_ROOT="${RUN_ROOT:-$DATASET_ROOT/runs}"
SITE_PROFILE="${SITE_PROFILE:-repacss_h100}"

# -------- Site-independent benchmark intent --------
BENCH_ID="${BENCH_ID:-osu}"
DATASET_ID="${DATASET_ID:-small}"
EXPERIMENT_ID="${EXPERIMENT_ID:-template_h100}"
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

# Optional site environment setup (mirror sites/repacss_h100.yaml)
source ~/.bashrc
module load cuda/12.9.0 || true

# Prepare runtime (module/spack/source)
"$PREPARE_SCRIPT" "$PREPARE_METHOD"

# Execute benchmark adapter
# shellcheck disable=SC2086
"$RUN_SCRIPT" $RUN_ARGS
