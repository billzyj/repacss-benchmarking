#!/bin/bash
# Template prepare adapter for REPACSS.
set -euo pipefail

METHOD="${1:-module}"

case "$METHOD" in
  module)
    echo "[dummy] Load site module here."
    echo "[dummy] Example: module load dummy-benchmark"
    ;;
  spack)
    echo "[dummy] Spack commands:"
    echo "  spack install dummy-benchmark"
    echo "  spack load dummy-benchmark"
    ;;
  source)
    echo "[dummy] Build from source in user space (site-specific)."
    echo "[dummy] Add clone/build/install commands here."
    ;;
  *)
    echo "Usage: $0 [module|spack|source]"
    exit 1
    ;;
esac
