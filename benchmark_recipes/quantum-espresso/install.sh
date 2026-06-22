#!/bin/bash
# Prepare Quantum Espresso runtime on REPACSS.
set -euo pipefail

METHOD="${1:-spack}"

case "$METHOD" in
  module|system_modules)
    echo "[qe] Using REPACSS system modules for the dependency stack."
    echo "The current module inventory does not list a complete Quantum Espresso benchmark module."
    echo "Load dependencies before a Spack or source build, for example:"
    echo "  module load gcc/15.2.0 openmpi/4.1.8 openblas/0.3.30"
    ;;
  spack|user_spack)
    echo "[qe] Spack commands:"
    echo "  spack install quantum-espresso"
    echo "  spack load quantum-espresso"
    ;;
  source|user_source)
    echo "[qe] Build from source in user space (site-specific)."
    echo "[qe] Upstream: https://github.com/QEF/q-e"
    ;;
  *)
    echo "Usage: $0 [module|spack|source]"
    exit 1
    ;;
esac
