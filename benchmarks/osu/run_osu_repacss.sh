#!/bin/bash
#
# Run a selected OSU Micro-Benchmark on REPACSS.
#
# This script assumes OSU is available via either:
#   - module load osu-micro-benchmarks
#   - spack load osu-micro-benchmarks
#   - PATH pointing at a custom build (see install_osu.sh -- source method)
#
# Usage:
#   ./run_osu_repacss.sh <benchmark> <np> [extra-mpirun-args...]
#     benchmark: e.g., osu_latency, osu_bw, osu_allreduce
#     np       : number of MPI ranks

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <benchmark> <np> [extra-mpirun-args...]"
  exit 1
fi

BENCH="$1"
NP="$2"
shift 2

if ! command -v "$BENCH" >/dev/null 2>&1; then
  echo "Error: '$BENCH' not found on PATH."
  echo "Load it via 'module load osu-micro-benchmarks' or 'spack load osu-micro-benchmarks',"
  echo "or install from source and add its bin directory to PATH."
  exit 1
fi

echo "[osu] Running $BENCH with np=$NP on hosts: ${SLURM_NODELIST:-local}"
echo "[osu] Command: mpirun -np $NP $BENCH $*"

mpirun -np "$NP" "$BENCH" "$@"


