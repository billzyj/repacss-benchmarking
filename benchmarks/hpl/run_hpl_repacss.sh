#!/bin/bash
#
# Run HPL on REPACSS.
#
# This script assumes HPL is available via either:
#   - module load hpl
#   - spack load hpl
#   - PATH pointing at a custom build (see install_hpl.sh -- source method)
#
# Usage:
#   ./run_hpl_repacss.sh <np> <hpl_dat> [extra-mpirun-args...]
#     np      : number of MPI ranks (P*Q)
#     hpl_dat : path to HPL.dat to use (Zen4/H100 specific templates)

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <np> <hpl_dat> [extra-mpirun-args...]"
  exit 1
fi

NP="$1"
HPL_DAT="$2"
shift 2

if ! command -v xhpl >/dev/null 2>&1; then
  echo "Error: 'xhpl' not found on PATH."
  echo "Load it via 'module load hpl' or 'spack load hpl',"
  echo "or install from source and add its bin directory to PATH."
  exit 1
fi

if [ ! -f "$HPL_DAT" ]; then
  echo "Error: HPL.dat not found at: $HPL_DAT"
  exit 1
fi

cp "$HPL_DAT" ./HPL.dat

echo "[hpl] Running xhpl with np=$NP on hosts: ${SLURM_NODELIST:-local}"
echo "[hpl] Command: mpirun -np $NP xhpl $*"

mpirun -np "$NP" xhpl "$@"


