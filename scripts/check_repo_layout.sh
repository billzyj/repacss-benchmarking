#!/bin/bash
# Verify benchmark adapter layout and catalog/benchmark consistency.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BENCH_ROOT="$REPO_ROOT/benchmarks"
CATALOG_FILE="$REPO_ROOT/catalog/benchmarks.yaml"

errors=0
warnings=0

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; warnings=$((warnings + 1)); }
log_err() { echo "[ERROR] $*"; errors=$((errors + 1)); }

trim_scalar() {
  echo "$1" | sed -E "s/^[[:space:]]+//; s/[[:space:]]+$//; s/^['\"]//; s/['\"]$//"
}

require_file() {
  local path="$1"
  local what="$2"
  if [[ ! -f "$path" ]]; then
    log_err "$what missing: ${path#$REPO_ROOT/}"
    return 1
  fi
  return 0
}

require_exec() {
  local path="$1"
  local what="$2"
  if [[ ! -x "$path" ]]; then
    log_err "$what not executable: ${path#$REPO_ROOT/}"
    return 1
  fi
  return 0
}

if [[ ! -d "$BENCH_ROOT" ]]; then
  log_err "benchmarks directory not found"
  exit 1
fi

if [[ ! -f "$CATALOG_FILE" ]]; then
  log_err "catalog file missing: catalog/benchmarks.yaml"
  exit 1
fi

catalog_table="$(mktemp)"
trap 'rm -f "$catalog_table"' EXIT

current_id=""
current_benchmark_file=""
current_prepare=""
current_run=""
current_parse=""
in_benchmarks=0

flush_current() {
  if [[ -n "$current_id" ]]; then
    printf "%s\t%s\t%s\t%s\t%s\n" \
      "$current_id" "$current_benchmark_file" "$current_prepare" "$current_run" "$current_parse" >> "$catalog_table"
  fi
}

log_info "Parsing catalog benchmark entries"
while IFS= read -r raw_line; do
  line="${raw_line%%#*}"

  if [[ "$line" =~ ^[[:space:]]*benchmarks:[[:space:]]*$ ]]; then
    in_benchmarks=1
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]*artifacts_not_benchmarks_examples:[[:space:]]*$ ]]; then
    flush_current
    in_benchmarks=0
    current_id=""
    break
  fi

  [[ "$in_benchmarks" -eq 1 ]] || continue

  if [[ "$line" =~ ^[[:space:]]*-[[:space:]]id:[[:space:]]*([A-Za-z0-9_.-]+)[[:space:]]*$ ]]; then
    flush_current
    current_id="${BASH_REMATCH[1]}"
    current_benchmark_file=""
    current_prepare=""
    current_run=""
    current_parse=""
    continue
  fi

  [[ -n "$current_id" ]] || continue

  if [[ "$line" =~ ^[[:space:]]*benchmark_file:[[:space:]]*(.+)$ ]]; then
    current_benchmark_file="$(trim_scalar "${BASH_REMATCH[1]}")"
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]*prepare_script:[[:space:]]*(.+)$ ]]; then
    current_prepare="$(trim_scalar "${BASH_REMATCH[1]}")"
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]*run_script:[[:space:]]*(.+)$ ]]; then
    current_run="$(trim_scalar "${BASH_REMATCH[1]}")"
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]*parse_script:[[:space:]]*(.+)$ ]]; then
    current_parse="$(trim_scalar "${BASH_REMATCH[1]}")"
    continue
  fi
done < "$CATALOG_FILE"

flush_current

if [[ ! -s "$catalog_table" ]]; then
  log_err "no benchmark entries parsed from catalog/benchmarks.yaml"
  exit 1
fi

dup_ids="$(cut -f1 "$catalog_table" | sort | uniq -d || true)"
if [[ -n "$dup_ids" ]]; then
  log_err "duplicate benchmark id(s) in catalog: $dup_ids"
fi

log_info "Checking catalog rows"
while IFS=$'\t' read -r cid cfile cprep crun cparse; do
  [[ -n "$cid" ]] || continue

  if [[ -z "$cfile" ]]; then
    log_err "catalog benchmark_file missing for id=$cid"
  else
    require_file "$REPO_ROOT/$cfile" "catalog benchmark_file for id=$cid"
    if [[ -f "$REPO_ROOT/$cfile" ]]; then
      file_id="$(sed -n 's/^id:[[:space:]]*//p' "$REPO_ROOT/$cfile" | head -n1 | tr -d '"\r')"
      if [[ "$file_id" != "$cid" ]]; then
        log_err "id mismatch: catalog id=$cid but $cfile has id=$file_id"
      fi
    fi
  fi

  if [[ -z "$cprep" || -z "$crun" || -z "$cparse" ]]; then
    log_err "catalog script path missing for id=$cid (need prepare_script/run_script/parse_script)"
    continue
  fi

  require_file "$REPO_ROOT/$cprep" "catalog prepare_script for id=$cid"
  require_file "$REPO_ROOT/$crun" "catalog run_script for id=$cid"
  require_file "$REPO_ROOT/$cparse" "catalog parse_script for id=$cid"

  require_exec "$REPO_ROOT/$cprep" "catalog prepare_script for id=$cid"
  require_exec "$REPO_ROOT/$crun" "catalog run_script for id=$cid"
  require_exec "$REPO_ROOT/$cparse" "catalog parse_script for id=$cid"
done < "$catalog_table"

log_info "Checking benchmark directories"
for bench_dir in "$BENCH_ROOT"/*; do
  [[ -d "$bench_dir" ]] || continue
  bench_name="$(basename "$bench_dir")"

  if [[ "$bench_name" == "templates" ]]; then
    continue
  fi

  benchmark_yaml="$bench_dir/benchmark.yaml"
  if ! require_file "$benchmark_yaml" "benchmark metadata"; then
    continue
  fi

  bench_id="$(sed -n 's/^id:[[:space:]]*//p' "$benchmark_yaml" | head -n1 | tr -d '"\r')"
  if [[ -z "$bench_id" ]]; then
    log_err "benchmark id missing in ${benchmark_yaml#$REPO_ROOT/}"
    continue
  fi

  if ! row="$(awk -F'\t' -v id="$bench_id" '$1==id {print; found=1} END{exit(found?0:1)}' "$catalog_table")"; then
    log_err "benchmark id '$bench_id' not found in catalog/benchmarks.yaml"
    continue
  fi

  IFS=$'\t' read -r _ row_benchmark_file row_prepare row_run row_parse <<< "$row"

  expected_benchmark_file="benchmarks/$bench_name/benchmark.yaml"
  if [[ "$row_benchmark_file" != "$expected_benchmark_file" ]]; then
    log_err "catalog benchmark_file mismatch for id=$bench_id: expected $expected_benchmark_file got $row_benchmark_file"
  fi

  local_prepare_sub="$(sed -n 's/^[[:space:]]*prepare:[[:space:]]*//p' "$benchmark_yaml" | head -n1 | tr -d '"\r')"
  local_run_sub="$(sed -n 's/^[[:space:]]*run:[[:space:]]*//p' "$benchmark_yaml" | head -n1 | tr -d '"\r')"
  local_parse_sub="$(sed -n 's/^[[:space:]]*parse:[[:space:]]*//p' "$benchmark_yaml" | head -n1 | tr -d '"\r')"

  if [[ -z "$local_prepare_sub" || -z "$local_run_sub" || -z "$local_parse_sub" ]]; then
    log_err "missing prepare/run/parse mapping in ${benchmark_yaml#$REPO_ROOT/}"
  else
    expected_prepare="benchmarks/$bench_name/$local_prepare_sub"
    expected_run="benchmarks/$bench_name/$local_run_sub"
    expected_parse="benchmarks/$bench_name/$local_parse_sub"

    if [[ "$row_prepare" != "$expected_prepare" ]]; then
      log_err "prepare_script mismatch for id=$bench_id: catalog=$row_prepare benchmark_yaml=$expected_prepare"
    fi
    if [[ "$row_run" != "$expected_run" ]]; then
      log_err "run_script mismatch for id=$bench_id: catalog=$row_run benchmark_yaml=$expected_run"
    fi
    if [[ "$row_parse" != "$expected_parse" ]]; then
      log_err "parse_script mismatch for id=$bench_id: catalog=$row_parse benchmark_yaml=$expected_parse"
    fi
  fi

  adapter_root="$bench_dir/adapters/repacss"
  if [[ ! -d "$adapter_root" ]]; then
    log_err "adapter directory missing: ${adapter_root#$REPO_ROOT/}"
    continue
  fi

  require_file "$adapter_root/prepare.sh" "prepare adapter"
  require_file "$adapter_root/run.sh" "run adapter"
  require_file "$adapter_root/parse.sh" "parse adapter"

  require_exec "$adapter_root/prepare.sh" "prepare adapter"
  require_exec "$adapter_root/run.sh" "run adapter"
  require_exec "$adapter_root/parse.sh" "parse adapter"

  if ! rg -n '^[[:space:]]*run_mode:[[:space:]]*(launcher|slurm_batch)[[:space:]]*$' "$benchmark_yaml" >/dev/null 2>&1; then
    log_warn "run_mode not set to launcher/slurm_batch in ${benchmark_yaml#$REPO_ROOT/}"
  fi
done

log_info "Checking for forbidden legacy root config files"
while IFS= read -r legacy_cfg; do
  log_err "remove legacy benchmark root config file: ${legacy_cfg#$REPO_ROOT/}"
done < <(find "$BENCH_ROOT" -mindepth 2 -maxdepth 2 -type f -name 'config.json' | sort)

if [[ "$warnings" -gt 0 ]]; then
  log_info "Completed with $warnings warning(s)."
fi

if [[ "$errors" -gt 0 ]]; then
  log_err "Layout check failed with $errors error(s)."
  exit 1
fi

log_info "Layout check passed."
