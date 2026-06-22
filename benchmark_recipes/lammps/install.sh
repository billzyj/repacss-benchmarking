#!/bin/bash
# Prepare LAMMPS runtime on REPACSS.
set -euo pipefail

METHOD="${1:-spack}"

case "$METHOD" in
  module|system_modules)
    echo "[lammps] Using REPACSS system modules for the dependency stack."
    echo "The current module inventory does not list a complete LAMMPS benchmark module."
    echo "Load dependencies before a Spack or source build, for example:"
    echo "  module load gcc/15.2.0 openmpi/4.1.8"
    ;;
  spack|user_spack)
    echo "[lammps] Spack commands:"
    echo "  spack install lammps"
    echo "  spack load lammps"
    ;;
  source|user_source)
    echo "[lammps] Build from source in user space (site-specific)."
    echo "[lammps] Upstream: https://github.com/lammps/lammps"
    ;;
  *)
    echo "Usage: $0 [module|spack|source]"
    exit 1
    ;;
esac
