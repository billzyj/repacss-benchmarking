#!/bin/bash
# Template run adapter for REPACSS with unified run artifact contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

COMMON_LIB="$BENCH_DIR/../common/repacss_contract.sh"
if [[ ! -f "$COMMON_LIB" ]]; then
  COMMON_LIB="$BENCH_DIR/../../common/repacss_contract.sh"
fi
source "$COMMON_LIB"

BENCH_ID="dummy"
DATASET_ID="${DATASET_ID:-param_small}"
DATASET_ROOT="${DATASET_ROOT:-$HOME/data}"

repacss_make_run_dirs "$BENCH_ID" "${SITE_PROFILE:-repacss_zen4}"
repacss_write_context "$BENCH_ID" "launcher" "$DATASET_ID"
repacss_init_normalized_artifacts "$BENCH_ID" "Dummy Benchmark (Template)" "$DATASET_ID"

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

echo "timestamp_utc,component,decision,reason" > "${NORM_DIR}/decisions.csv"
echo "$(repacss_iso8601_utc),run,input_mode=${INPUT_MODE},resolved from dataset profile ${DATASET_ID}" >> "${NORM_DIR}/decisions.csv"

BIN="${DUMMY_BIN:-dummy-benchmark}"
RUN_LOG="${RAW_DIR}/dummy.log"

echo "[dummy] RUN_DIR=$RUN_DIR"
echo "[dummy] DATASET_ID=$DATASET_ID INPUT_MODE=$INPUT_MODE"
echo "[dummy] Command: $BIN $RUN_ARGS"

if command -v "$BIN" >/dev/null 2>&1; then
  # shellcheck disable=SC2086
  "$BIN" $RUN_ARGS 2>&1 | tee "$RUN_LOG"
else
  echo "[dummy] Binary '$BIN' not found. Dry-run only." | tee "$RUN_LOG"
fi

"$SCRIPT_DIR/parse.sh" "$RUN_DIR" "${NORM_DIR}/summary.json"

echo "[dummy] Completed. Artifacts: $RUN_DIR"
