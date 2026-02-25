#!/bin/bash
# Shared run-directory and artifact contract for REPACSS benchmark adapters.

set -euo pipefail

repacss_iso8601_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

repacss_make_run_dirs() {
  if [[ "$#" -lt 1 ]]; then
    echo "Usage: repacss_make_run_dirs <bench_id> [default_site_profile]"
    return 1
  fi

  local bench_id="$1"
  local default_site_profile="${2:-repacss_zen4}"
  local default_run_id=""

  RUN_ROOT="${RUN_ROOT:-${DATASET_ROOT:-$HOME/data}/runs}"
  EXPERIMENT_ID="${EXPERIMENT_ID:-manual}"
  SITE_PROFILE="${SITE_PROFILE:-$default_site_profile}"

  if [[ -n "${SLURM_JOB_ID:-}" ]]; then
    default_run_id="job-${SLURM_JOB_ID}"
  else
    default_run_id="local-$(date +%Y%m%d_%H%M%S)"
  fi

  RUN_ID="${RUN_ID:-$default_run_id}"
  RUN_DIR="${RUN_ROOT%/}/${EXPERIMENT_ID}/${SITE_PROFILE}/${bench_id}/${RUN_ID}"
  RAW_DIR="${RUN_DIR}/raw"
  NORM_DIR="${RUN_DIR}/normalized"

  mkdir -p "$RAW_DIR" "$NORM_DIR"

  export RUN_ROOT EXPERIMENT_ID SITE_PROFILE RUN_ID RUN_DIR RAW_DIR NORM_DIR
}

repacss_write_context() {
  if [[ "$#" -lt 3 ]]; then
    echo "Usage: repacss_write_context <bench_id> <run_mode> <dataset_id>"
    return 1
  fi

  local bench_id="$1"
  local run_mode="$2"
  local dataset_id="$3"
  local start_utc
  start_utc="$(repacss_iso8601_utc)"

  cat > "${RAW_DIR}/context.env" <<EOF
BENCH_ID=${bench_id}
RUN_MODE=${run_mode}
DATASET_ID=${dataset_id}
RUN_ROOT=${RUN_ROOT}
EXPERIMENT_ID=${EXPERIMENT_ID}
SITE_PROFILE=${SITE_PROFILE}
RUN_ID=${RUN_ID}
RUN_DIR=${RUN_DIR}
RAW_DIR=${RAW_DIR}
NORM_DIR=${NORM_DIR}
SLURM_JOB_ID=${SLURM_JOB_ID:-}
SLURM_NODELIST=${SLURM_NODELIST:-}
HOSTNAME=$(hostname)
START_TIME_UTC=${start_utc}
EOF
}

repacss_init_normalized_artifacts() {
  if [[ "$#" -lt 3 ]]; then
    echo "Usage: repacss_init_normalized_artifacts <bench_id> <benchmark_name> <dataset_id>"
    return 1
  fi

  local bench_id="$1"
  local benchmark_name="$2"
  local dataset_id="$3"

  cat > "${NORM_DIR}/meta.json" <<EOF
{
  "benchmark": "${bench_id}",
  "benchmark_name": "${benchmark_name}",
  "dataset_id": "${dataset_id}",
  "experiment_id": "${EXPERIMENT_ID}",
  "site_profile": "${SITE_PROFILE}",
  "run_id": "${RUN_ID}",
  "run_dir": "${RUN_DIR}",
  "slurm_job_id": "${SLURM_JOB_ID:-}",
  "hostname": "$(hostname)",
  "created_at_utc": "$(repacss_iso8601_utc)"
}
EOF

  cat > "${NORM_DIR}/telemetry.csv" <<EOF
timestamp_utc,phase,metric,value,unit,details
EOF

  cat > "${NORM_DIR}/decisions.csv" <<EOF
timestamp_utc,component,decision,reason
EOF
}

