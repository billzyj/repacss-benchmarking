#!/bin/bash
set -euo pipefail
RECIPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METHOD="${1:-source}"
if [[ "$#" -gt 0 && "$1" == source ]]; then shift; fi
if [[ "$METHOD" != source ]]; then
  echo "Usage: install.sh [source] [--execute]; default prints the build plan." >&2
  exit 2
fi
exec "${PYTHON:-python3}" "$RECIPE_DIR/../../repacss_runtime/gpu_upstream.py" --recipe "$RECIPE_DIR" install "$@"
