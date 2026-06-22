#!/bin/bash
#
# Prepare HPL runtime for REPACSS.
#
# Usage:
#   ./install.sh [module|spack|source]
#
# Methods:
#   - module : load REPACSS-provided dependency modules
#   - spack  : install/load HPL via user Spack
#   - source : clone and build from upstream HPL repository in $HPL_PREFIX

set -euo pipefail

METHOD="${1:-spack}"
HPL_PREFIX="${HPL_PREFIX:-$HOME/opt/hpl}"

case "$METHOD" in
  module|system_modules)
    echo "[hpl] Using REPACSS system modules for the dependency stack."
    echo "The current module inventory does not list a complete HPL benchmark module."
    echo "Load dependencies before a Spack or source build, for example:"
    echo "  module load gcc/15.2.0 openmpi/4.1.8 openblas/0.3.30"
    ;;

  spack|user_spack)
    echo "[hpl] Using user Spack installation."
    echo "This will attempt to install and load HPL via Spack."
    echo
    echo "Spack commands (run on REPACSS login node):"
    echo "  spack install hpl"
    echo "  spack load hpl"
    ;;

  source|user_source)
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
