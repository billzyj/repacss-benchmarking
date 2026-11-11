#!/bin/bash
set -euo pipefail
RECIPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${PYTHON:-python3}" "$RECIPE_DIR/../../repacss_runtime/gpu_upstream.py" --recipe "$RECIPE_DIR" parse "$@"
