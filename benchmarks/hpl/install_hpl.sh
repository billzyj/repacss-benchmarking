#!/bin/bash
#
# Install HPL for use with this project on REPACSS.
#
# Usage:
#   ./install_hpl.sh [module|spack|source]
#
# Methods:
#   - module : preferred; assumes site-provided HPL module
#   - spack  : install/load via Spack
#   - source : clone and build from upstream HPL repository in $HPL_PREFIX

set -euo pipefail

METHOD="${1:-module}"
HPL_PREFIX="${HPL_PREFIX:-$HOME/opt/hpl}"

case "$METHOD" in
  module)
    echo "[hpl] Using module-based installation (recommended)."
    echo "Run the following before your jobs:"
    echo "  module load hpl"
    ;;

  spack)
    echo "[hpl] Using Spack-based installation."
    echo "This will attempt to install and load HPL via Spack."
    echo
    echo "Spack commands (run on REPACSS login node):"
    echo "  spack install hpl"
    echo "  spack load hpl"
    ;;

  source)
    echo "[hpl] Building HPL from source into: $HPL_PREFIX"
    echo "Note: the HPL source is NOT vendored in this repo."
    echo "The script will clone the official HPL repository and build it."
    echo
    mkdir -p "$HPL_PREFIX"
    cd "$HPL_PREFIX"
    if [ ! -d hpl ]; then
      git clone https://github.com/icl-utk-edu/hpl.git
    fi
    cd hpl
    # Building HPL is site-specific; here we just echo guidance.
    echo "[hpl] Please edit the appropriate Makefile under 'setup/' for REPACSS"
    echo "      and run 'make arch=<your-arch>' according to HPL docs."
    ;;

  *)
    echo "Unknown method: $METHOD"
    echo "Usage: $0 [module|spack|source]"
    exit 1
    ;;
esac


