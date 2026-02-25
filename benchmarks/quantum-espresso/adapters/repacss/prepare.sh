#!/bin/bash
# Prepare Quantum Espresso runtime on REPACSS.
set -euo pipefail

METHOD="${1:-module}"

case "$METHOD" in
  module)
    echo "[qe] Load site-provided Quantum Espresso module if available."
    ;;
  spack)
    echo "[qe] Spack commands:"
    echo "  spack install quantum-espresso"
    echo "  spack load quantum-espresso"
    ;;
  source)
    echo "[qe] Build from source in user space (site-specific)."
    echo "[qe] Upstream: https://github.com/QEF/q-e"
    ;;
  *)
    echo "Usage: $0 [module|spack|source]"
    exit 1
    ;;
esac
