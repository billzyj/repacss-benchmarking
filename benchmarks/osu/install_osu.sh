#!/bin/bash
#
# Install OSU Micro-Benchmarks for use with this project on REPACSS.
#
# Usage:
#   ./install_osu.sh [module|spack|source]
#
# Methods:
#   - module : preferred; assumes site-provided module environment
#   - spack  : install/load via Spack
#   - source : clone and build from upstream OSU repository in $OSU_PREFIX (not vendored here)

set -euo pipefail

METHOD="${1:-module}"
OSU_PREFIX="${OSU_PREFIX:-$HOME/opt/osu-micro-benchmarks}"

case "$METHOD" in
  module)
    echo "[osu] Using module-based installation (recommended)."
    echo "Run the following before your jobs:"
    echo "  module load osu-micro-benchmarks"
    ;;

  spack)
    echo "[osu] Using Spack-based installation."
    echo "This will attempt to install and load osu-micro-benchmarks via Spack."
    echo
    echo "Spack commands (run on REPACSS login node):"
    echo "  spack install osu-micro-benchmarks"
    echo "  spack load osu-micro-benchmarks"
    ;;

  source)
    echo "[osu] Building OSU from source into: $OSU_PREFIX"
    echo "Note: the OSU source is NOT vendored in this repo."
    echo "The script will clone the official OSU repository and build it."
    echo
    mkdir -p "$OSU_PREFIX"
    cd "$OSU_PREFIX"
    if [ ! -d osu-micro-benchmarks ]; then
      git clone https://github.com/OSU-MicroBenchmarks/osu-micro-benchmarks.git
    fi
    cd osu-micro-benchmarks
    ./configure --prefix="$OSU_PREFIX"
    make -j"$(nproc)"
    make install
    echo
    echo "[osu] Build complete. Add to PATH, e.g.:"
    echo "  export PATH=\"$OSU_PREFIX/bin:\$PATH\""
    ;;

  *)
    echo "Unknown method: $METHOD"
    echo "Usage: $0 [module|spack|source]"
    exit 1
    ;;
esac


