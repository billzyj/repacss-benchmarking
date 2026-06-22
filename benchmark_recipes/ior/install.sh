#!/bin/bash
# Prepare IOR runtime on REPACSS.
set -euo pipefail

METHOD="${1:-spack}"

case "$METHOD" in
  module|system_modules)
    echo "[ior] Using REPACSS system modules for the dependency stack."
    echo "The current module inventory does not list a complete IOR benchmark module."
    echo "Load dependencies before a Spack or source build, for example:"
    echo "  module load gcc/15.2.0 mpich/4.3.2"
    ;;
  spack|user_spack)
    echo "[ior] Spack commands:"
    echo "  spack install ior"
    echo "  spack load ior"
    ;;
  source|user_source)
    echo "[ior] Build from source in user space (site-specific)."
    echo "[ior] Upstream: https://github.com/hpc/ior"
    ;;
  *)
    echo "Usage: $0 [module|spack|source]"
    exit 1
    ;;
esac
