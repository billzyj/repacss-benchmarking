#!/bin/bash
# Prepare IOR runtime on REPACSS.
set -euo pipefail

METHOD="${1:-module}"

case "$METHOD" in
  module)
    echo "[ior] Use site module if provided by REPACSS admins."
    ;;
  spack)
    echo "[ior] Spack commands:"
    echo "  spack install ior"
    echo "  spack load ior"
    ;;
  source)
    echo "[ior] Build from source in user space (site-specific)."
    echo "[ior] Upstream: https://github.com/hpc/ior"
    ;;
  *)
    echo "Usage: $0 [module|spack|source]"
    exit 1
    ;;
esac
