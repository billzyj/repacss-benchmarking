#!/bin/bash
# Template run adapter for REPACSS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

DATASET_ID="${DATASET_ID:-param_small}"
DATASET_ROOT="${DATASET_ROOT:-$HOME/data}"

INPUT_MODE=""
RUN_ARGS=""
REQUIRED_FILES=()

case "$DATASET_ID" in
  param_small)
    INPUT_MODE="parametric"
    RUN_ARGS="--size 1024 --iters 10"
    ;;
  file_small)
    INPUT_MODE="file_bundle"
    INPUT_FILE="$BENCH_DIR/inputs/dummy_small.in"
    RUN_ARGS="--input $INPUT_FILE"
    REQUIRED_FILES+=("$INPUT_FILE")
    ;;
  prod)
    INPUT_MODE="hybrid"
    INPUT_FILE="$DATASET_ROOT/dummy/prod_case.in"
    RUN_ARGS="--input $INPUT_FILE --iters 1000"
    REQUIRED_FILES+=("$INPUT_FILE")
    ;;
  *)
    echo "Unknown DATASET_ID: $DATASET_ID"
    echo "Supported: param_small, file_small, prod"
    exit 1
    ;;
esac

for f in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing required input file: $f"
    exit 1
  fi
done

BIN="${DUMMY_BIN:-dummy-benchmark}"

echo "[dummy] DATASET_ID=$DATASET_ID INPUT_MODE=$INPUT_MODE"
echo "[dummy] Command: $BIN $RUN_ARGS"

if command -v "$BIN" >/dev/null 2>&1; then
  # shellcheck disable=SC2086
  "$BIN" $RUN_ARGS
else
  echo "[dummy] Binary '$BIN' not found. Dry-run only."
fi
