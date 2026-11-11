#!/bin/bash
# install.sh [module]            LAMMPS for the CPU job comes from the site module; print what env.sh loads.
# install.sh source [--execute]  BabelStream for the GPU job: print the build plan, or build it (load cuda/12.9.1 first).
set -euo pipefail
RECIPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METHOD="${1:-module}"
case "$METHOD" in
  module) echo "Nothing to build for the CPU job; env.sh loads: mpich/4.3.2 openblas/0.3.30 lammps/20250722" ;;
  source) shift; exec bash "$RECIPE_DIR/../babelstream/install.sh" source "$@" ;;
  *) echo "Usage: install.sh [module] | install.sh source [--execute]" >&2; exit 2 ;;
esac
