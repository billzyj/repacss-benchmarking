#!/bin/bash
# Submit one power-report check job.
#   run.sh cpu|gpu [sbatch options, e.g. --reservation=... --nodelist=...]
# Records go to Output/experiments/<cpu|gpu>-both/ in the repository; the reports are delivered there too.
set -euo pipefail
RECIPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$RECIPE_DIR/../.." && pwd)"
kind="${1:?cpu or gpu}"; shift
OUT_ROOT="$REPO_ROOT/Output/experiments/$kind-both"
mkdir -p "$OUT_ROOT"
export RECIPE_DIR OUT_ROOT
case "$kind" in
  cpu) MODE=both sbatch --comment=power:both --chdir="$OUT_ROOT" --export=ALL "$@" "$RECIPE_DIR/zen4_lammps.sbatch" ;;
  gpu) sbatch --chdir="$OUT_ROOT" --export=ALL "$@" "$RECIPE_DIR/h100_babelstream.sbatch" ;;
  *) echo "unknown job kind $kind; use cpu or gpu" >&2; exit 2 ;;
esac
