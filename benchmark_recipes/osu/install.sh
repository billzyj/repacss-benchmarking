#!/bin/bash
#
# Prepare OSU Micro-Benchmarks runtime for REPACSS.
#
# Usage:
#   ./install.sh [module|spack|source]
#
# Methods:
#   - module : load REPACSS-provided dependency modules
#   - spack  : install/load OSU via user Spack
#   - source : clone and build from upstream OSU repository in $OSU_PREFIX (not vendored here)

set -euo pipefail

METHOD="${1:-source}"
OSU_PREFIX="${OSU_PREFIX:-$HOME/opt/osu-micro-benchmarks}"

case "$METHOD" in
  module|system_modules)
    echo "[osu] Using REPACSS system modules for the dependency stack."
    echo "The current module inventory does not list a complete OSU Micro-Benchmarks module."
    echo "Load dependencies before a Spack or source build, for example:"
    echo "  module load gcc/15.2.0 openmpi/4.1.8"
    ;;

  spack|user_spack)
    echo "[osu] Using user Spack installation."
    echo "This will attempt to install and load osu-micro-benchmarks via Spack."
    echo
    echo "Spack commands (run on REPACSS login node):"
    echo "  spack install osu-micro-benchmarks"
    echo "  spack load osu-micro-benchmarks"
    ;;

  source|user_source)
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
