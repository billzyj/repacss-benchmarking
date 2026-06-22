#!/bin/bash
# Validate the REPACSS benchmark install/run repository layout.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECIPE_ROOT="$REPO_ROOT/benchmark_recipes"
INDEX_FILE="$REPO_ROOT/benchmark_index/benchmarks.yaml"

errors=0
warnings=0

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; warnings=$((warnings + 1)); }
log_err() { echo "[ERROR] $*"; errors=$((errors + 1)); }

trim_scalar() {
  echo "$1" | sed -E "s/^[[:space:]]+//; s/[[:space:]]+$//; s/^['\"]//; s/['\"]$//"
}

extract_install_scalar() {
  local key="$1"
  local path="$2"
  awk -v key="$key" '
    /^installation:[[:space:]]*$/ {in_install=1; next}
    in_install && /^[^[:space:]]/ {in_install=0}
    in_install && $1 == key ":" {
      sub(/^[[:space:]]*[^:]+:[[:space:]]*/, "")
      print
      exit
    }
  ' "$path" | tr -d '"\r'
}

install_method_alias() {
  case "$1" in
    system_modules) echo "module" ;;
    user_spack) echo "spack" ;;
    user_source) echo "source" ;;
    user_conda) echo "conda" ;;
    *) echo "" ;;
  esac
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

for obsolete in \
  "AGENTS.md" \
  "CLAUDE.md" \
  ".gitmodules" \
  "benchmarks" \
  "catalog" \
  "docs" \
  "scripts" \
  "sites" \
  "experiments" \
  "external/Repacss-power-profiling"
do
  if [[ -e "$REPO_ROOT/$obsolete" ]]; then
    log_err "obsolete root layout entry still present: $obsolete"
  fi
done

require_file "$INDEX_FILE" "benchmark classification index"
require_file "$REPO_ROOT/repacss_runtime/artifacts.sh" "REPACSS artifact helper"
require_file "$REPO_ROOT/repacss_cluster/README.md" "REPACSS cluster reference README"
require_file "$REPO_ROOT/repacss_cluster/hardware.yaml" "REPACSS hardware reference"
require_file "$REPO_ROOT/repacss_cluster/modules.yaml" "REPACSS module inventory"
require_file "$REPO_ROOT/repacss_cluster/sinfo_snapshot.txt" "REPACSS sinfo snapshot"
require_file "$REPO_ROOT/README.md" "repository README"
require_file "$REPO_ROOT/benchmark_recipes/README.md" "benchmark recipes README"
require_file "$REPO_ROOT/benchmark_index/README.md" "benchmark index README"
require_file "$REPO_ROOT/operator_docs/architecture.md" "architecture document"
require_file "$REPO_ROOT/operator_docs/artifact_contract.md" "artifact contract document"
require_file "$REPO_ROOT/operator_docs/install_methods.md" "install methods document"
require_file "$REPO_ROOT/operator_docs/runbook.md" "REPACSS runbook"
require_file "$REPO_ROOT/repo_tools/README.md" "repository tools README"
require_file "$REPO_ROOT/repo_tools/check_repo_layout.sh" "layout check script"
require_exec "$REPO_ROOT/repo_tools/check_repo_layout.sh" "layout check script"

index_table="$(mktemp)"
trap 'rm -f "$index_table"' EXIT

current_id=""
current_recipe_file=""
has_object=0
has_semantics=0
has_execution=0
in_benchmarks=0

flush_current() {
  if [[ -z "$current_id" ]]; then
    return
  fi

  if [[ "$has_object" -ne 1 ]]; then
    log_err "index entry id=$current_id missing object classification"
  fi
  if [[ "$has_semantics" -ne 1 ]]; then
    log_err "index entry id=$current_id missing semantics classification"
  fi
  if [[ "$has_execution" -ne 1 ]]; then
    log_err "index entry id=$current_id missing execution classification"
  fi
  if [[ -z "$current_recipe_file" ]]; then
    log_err "index entry id=$current_id missing recipe_file"
  fi

  printf "%s\t%s\n" "$current_id" "$current_recipe_file" >> "$index_table"
}

log_info "Parsing benchmark classification index"
while IFS= read -r raw_line; do
  line="${raw_line%%#*}"

  if [[ "$line" =~ ^[[:space:]]*benchmarks:[[:space:]]*$ ]]; then
    in_benchmarks=1
    continue
  fi

  [[ "$in_benchmarks" -eq 1 ]] || continue

  if [[ "$line" =~ ^[[:space:]]*-[[:space:]]id:[[:space:]]*([A-Za-z0-9_.-]+)[[:space:]]*$ ]]; then
    flush_current
    current_id="${BASH_REMATCH[1]}"
    current_recipe_file=""
    has_object=0
    has_semantics=0
    has_execution=0
    continue
  fi

  [[ -n "$current_id" ]] || continue

  if [[ "$line" =~ ^[[:space:]]*recipe_file:[[:space:]]*(.+)$ ]]; then
    current_recipe_file="$(trim_scalar "${BASH_REMATCH[1]}")"
    continue
  fi
  if [[ "$line" =~ ^[[:space:]]*object:[[:space:]]*$ ]]; then
    has_object=1
    continue
  fi
  if [[ "$line" =~ ^[[:space:]]*semantics:[[:space:]]*$ ]]; then
    has_semantics=1
    continue
  fi
  if [[ "$line" =~ ^[[:space:]]*execution:[[:space:]]*$ ]]; then
    has_execution=1
    continue
  fi
done < "$INDEX_FILE"
flush_current

if [[ ! -s "$index_table" ]]; then
  log_err "no benchmark entries parsed from benchmark_index/benchmarks.yaml"
fi

dup_ids="$(cut -f1 "$index_table" 2>/dev/null | sort | uniq -d || true)"
if [[ -n "$dup_ids" ]]; then
  log_err "duplicate benchmark id(s) in index: $dup_ids"
fi

log_info "Checking benchmark recipes"
for recipe_dir in "$RECIPE_ROOT"/*; do
  [[ -d "$recipe_dir" ]] || continue
  recipe_name="$(basename "$recipe_dir")"

  recipe_yaml="$recipe_dir/recipe.yaml"
  if ! require_file "$recipe_yaml" "benchmark recipe"; then
    continue
  fi

  bench_id="$(sed -n 's/^id:[[:space:]]*//p' "$recipe_yaml" | head -n1 | tr -d '"\r')"
  if [[ -z "$bench_id" ]]; then
    log_err "benchmark id missing in ${recipe_yaml#$REPO_ROOT/}"
    continue
  fi

  if ! row="$(awk -F'\t' -v id="$bench_id" '$1==id {print; found=1} END{exit(found?0:1)}' "$index_table")"; then
    log_err "benchmark id '$bench_id' not found in benchmark_index/benchmarks.yaml"
    continue
  fi

  IFS=$'\t' read -r _ row_recipe_file <<< "$row"
  expected_recipe_file="benchmark_recipes/$recipe_name/recipe.yaml"
  if [[ "$row_recipe_file" != "$expected_recipe_file" ]]; then
    log_err "index recipe_file mismatch for id=$bench_id: expected $expected_recipe_file got $row_recipe_file"
  fi

  status="$(sed -n 's/^status:[[:space:]]*//p' "$recipe_yaml" | head -n1 | tr -d '"\r')"
  case "$status" in
    ready|experimental) ;;
    *) log_err "status must be ready or experimental in ${recipe_yaml#$REPO_ROOT/}" ;;
  esac

  run_mode="$(sed -n 's/^run_mode:[[:space:]]*//p' "$recipe_yaml" | head -n1 | tr -d '"\r')"
  case "$run_mode" in
    launcher|slurm_batch) ;;
    *) log_err "run_mode must be launcher or slurm_batch in ${recipe_yaml#$REPO_ROOT/}" ;;
  esac

  install_file="$(sed -n 's/^[[:space:]]*install:[[:space:]]*//p' "$recipe_yaml" | head -n1 | tr -d '"\r')"
  run_file="$(sed -n 's/^[[:space:]]*run:[[:space:]]*//p' "$recipe_yaml" | head -n1 | tr -d '"\r')"
  parse_file="$(sed -n 's/^[[:space:]]*parse:[[:space:]]*//p' "$recipe_yaml" | head -n1 | tr -d '"\r')"
  partition="$(sed -n 's/^partition:[[:space:]]*//p' "$recipe_yaml" | head -n1 | tr -d '"\r')"
  hardware_reference="$(sed -n 's/^hardware_reference:[[:space:]]*//p' "$recipe_yaml" | head -n1 | tr -d '"\r')"
  default_install_method="$(extract_install_scalar "default_method" "$recipe_yaml")"
  supported_methods="$(extract_install_scalar "supported_methods" "$recipe_yaml")"
  module_inventory="$(extract_install_scalar "module_inventory" "$recipe_yaml")"

  if [[ -z "$partition" ]]; then
    log_err "partition missing in ${recipe_yaml#$REPO_ROOT/}"
  elif ! grep -Eq "^[[:space:]]{2}${partition}:" "$REPO_ROOT/repacss_cluster/hardware.yaml"; then
    log_err "partition '$partition' from ${recipe_yaml#$REPO_ROOT/} not found in repacss_cluster/hardware.yaml"
  fi

  expected_hardware_reference="repacss_cluster/hardware.yaml#partitions.${partition}"
  if [[ "$hardware_reference" != "$expected_hardware_reference" ]]; then
    log_err "hardware_reference mismatch in ${recipe_yaml#$REPO_ROOT/}: expected $expected_hardware_reference got ${hardware_reference:-<missing>}"
  fi

  if ! grep -q "^installation:" "$recipe_yaml"; then
    log_err "installation block missing in ${recipe_yaml#$REPO_ROOT/}"
  fi

  case "$default_install_method" in
    system_modules|user_spack|user_source|user_conda) ;;
    *) log_err "installation.default_method must be one of system_modules, user_spack, user_source, user_conda in ${recipe_yaml#$REPO_ROOT/}" ;;
  esac

  if [[ -z "$supported_methods" ]]; then
    log_err "installation.supported_methods missing in ${recipe_yaml#$REPO_ROOT/}"
  elif [[ "$supported_methods" != *"$default_install_method"* ]]; then
    log_err "installation.default_method '$default_install_method' is not listed in supported_methods in ${recipe_yaml#$REPO_ROOT/}"
  fi

  if [[ "$supported_methods" == *system_modules* ]]; then
    if ! grep -Eq "^[[:space:]]{2}${partition}:" "$REPO_ROOT/repacss_cluster/modules.yaml"; then
      log_err "partition '$partition' from ${recipe_yaml#$REPO_ROOT/} not found in repacss_cluster/modules.yaml"
    fi

    expected_module_inventory="repacss_cluster/modules.yaml#partitions.${partition}"
    if [[ "$module_inventory" != "$expected_module_inventory" ]]; then
      log_err "installation.system_modules.module_inventory mismatch in ${recipe_yaml#$REPO_ROOT/}: expected $expected_module_inventory got ${module_inventory:-<missing>}"
    fi
  fi

  if [[ -z "$install_file" || -z "$run_file" || -z "$parse_file" ]]; then
    log_err "commands.install/run/parse missing in ${recipe_yaml#$REPO_ROOT/}"
    continue
  fi

  require_file "$recipe_dir/$install_file" "install command for id=$bench_id"
  require_file "$recipe_dir/$run_file" "run command for id=$bench_id"
  require_file "$recipe_dir/$parse_file" "parse command for id=$bench_id"
  require_exec "$recipe_dir/$install_file" "install command for id=$bench_id"
  require_exec "$recipe_dir/$run_file" "run command for id=$bench_id"
  require_exec "$recipe_dir/$parse_file" "parse command for id=$bench_id"

  expected_install_alias="$(install_method_alias "$default_install_method")"
  if [[ -n "$expected_install_alias" ]]; then
    install_default_alias="$(sed -n -E 's/^[[:space:]]*METHOD="\$\{1:-([^}]+)\}".*/\1/p' "$recipe_dir/$install_file" | head -n1)"
    if [[ "$install_default_alias" != "$expected_install_alias" ]]; then
      log_err "install.sh default alias mismatch for id=$bench_id: expected $expected_install_alias from $default_install_method got ${install_default_alias:-<missing>}"
    fi
  fi

  if [[ -d "$recipe_dir/adapters" ]]; then
    log_err "adapters/ layer is obsolete in ${recipe_dir#$REPO_ROOT/}"
  fi
done

if [[ "$warnings" -gt 0 ]]; then
  log_info "Completed with $warnings warning(s)."
fi

if [[ "$errors" -gt 0 ]]; then
  log_err "Layout check failed with $errors error(s)."
  exit 1
fi

log_info "Layout check passed."
