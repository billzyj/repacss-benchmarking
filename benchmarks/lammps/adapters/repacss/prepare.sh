#!/bin/bash
# Prepare LAMMPS runtime on REPACSS.
set -euo pipefail

METHOD="${1:-spack}"

case "$METHOD" in
  module)
    echo "[lammps] Use site module if available."
    ;;
  spack)
    echo "[lammps] Spack commands:"
    echo "  spack install lammps"
    echo "  spack load lammps"
    ;;
  source)
    echo "[lammps] Build from source in user space (site-specific)."
    echo "[lammps] Upstream: https://github.com/lammps/lammps"
    ;;
  *)
    echo "Usage: $0 [module|spack|source]"
    exit 1
    ;;
esac
