# REPACSS Benchmarking

REPACSS-only benchmark recipes for installing, running, and parsing HPC benchmark workloads.

Current benchmark recipes default to the REPACSS Zen4 partition. Cluster reference files also record H100, H100-build, and MI210 facts so GPU recipes can be added without changing the repository shape.

This repository is intentionally practical: each benchmark has a short path to install guidance, a run command, a parser, and benchmark-local inputs.

## Start Here

1. Pick a benchmark directory under `benchmark_recipes/`.
2. Read its `recipe.yaml` to confirm the default partition and run mode.
3. Choose an install method from the recipe's `installation` block.
4. Check stable hardware facts in `repacss_cluster/hardware.yaml`.
5. Check available system modules in `repacss_cluster/modules.yaml` and live module state with `module avail`.
6. Check live scheduler state with `sinfo` before launching jobs.
7. Run `install.sh`, then `run.sh`, then `parse.sh`.
8. Use the normalized artifacts described in `operator_docs/artifact_contract.md`.

## Root Layout

```text
.
|-- benchmark_recipes/    # one directory per benchmark; install.sh, run.sh, parse.sh
|-- repacss_cluster/      # stable hardware facts and dynamic sinfo snapshots
|-- repacss_runtime/      # shared REPACSS artifact helpers sourced by run.sh
|-- benchmark_index/      # benchmark identity and classification only
|-- operator_docs/        # architecture, install methods, artifact contract, and runbook
|-- repo_tools/           # repository checks and maintenance tools
`-- .github/workflows/    # CI layout and shell checks
```

## What Goes Where

| Path | Purpose |
|---|---|
| `benchmark_recipes/<id>/install.sh` | Show or perform benchmark installation/loading steps for REPACSS. |
| `benchmark_recipes/<id>/run.sh` | Run the benchmark on REPACSS. Some are `sbatch` scripts; some run inside an allocation. |
| `benchmark_recipes/<id>/parse.sh` | Parse raw benchmark logs into normalized summary artifacts. |
| `benchmark_recipes/<id>/recipe.yaml` | REPACSS run metadata for that benchmark. |
| `benchmark_recipes/<id>/inputs/` | Small or smoke-test inputs that belong with the benchmark recipe. |
| `repacss_runtime/artifacts.sh` | Shared run-directory and normalized artifact helper functions. |
| `repacss_cluster/hardware.yaml` | Stable REPACSS partition hardware facts used when choosing benchmark parameters. |
| `repacss_cluster/modules.yaml` | REPACSS system module inventory used when choosing install methods and dependencies. |
| `repacss_cluster/sinfo_snapshot.txt` | Example scheduler-state snapshot; use live `sinfo` before launching jobs. |
| `benchmark_index/benchmarks.yaml` | Benchmark classification: what each benchmark is and what it measures. |
| `operator_docs/install_methods.md` | Install method model: system modules, user Spack, user source builds, and user Conda. |
| `operator_docs/runbook.md` | Operator-facing commands for installing and running benchmarks. |
| `repo_tools/check_repo_layout.sh` | Layout check for this simplified structure. |

## Supported Benchmarks

| Benchmark | Status | Default partition | Default install | Run mode |
|---|---|---|---|---|
| HPL | ready | `zen4` | `user_spack` | launcher inside an allocation |
| OSU Micro-Benchmarks | ready | `zen4` | `user_source` | launcher inside an allocation |
| IOR | ready | `zen4` | `user_spack` | Slurm batch script |
| LAMMPS | ready | `zen4` | `user_spack` | Slurm batch script |
| Quantum Espresso | experimental | `zen4` | `user_spack` | launcher inside an allocation |

## Quick Start

Check the repository layout:

```bash
bash repo_tools/check_repo_layout.sh
```

Check static partition facts and live scheduler state:

```bash
less repacss_cluster/hardware.yaml
sinfo -p zen4,h100,h100-build,mi210
```

Check module inventory and live module state:

```bash
less repacss_cluster/modules.yaml
module avail
```

Use the recipe default install method:

```bash
bash benchmark_recipes/hpl/install.sh spack
bash benchmark_recipes/osu/install.sh source
bash benchmark_recipes/ior/install.sh spack
```

Run batch-style benchmarks:

```bash
sbatch benchmark_recipes/ior/run.sh
sbatch benchmark_recipes/lammps/run.sh
```

Run launcher-style benchmarks inside a REPACSS allocation:

```bash
bash benchmark_recipes/hpl/install.sh spack
spack load hpl
bash benchmark_recipes/hpl/run.sh 4 benchmark_recipes/hpl/inputs/hpl/HPL-small.dat

bash benchmark_recipes/osu/install.sh source
export PATH="$HOME/opt/osu-micro-benchmarks/bin:$PATH"
bash benchmark_recipes/osu/run.sh osu_latency 2
```

See `operator_docs/runbook.md` for the full operator workflow.

See `operator_docs/install_methods.md` for the install model. System modules may provide a complete benchmark or only the compiler, MPI, math, CUDA, and profiling dependencies needed for a user-owned install.

## Single-Benchmark Parameters

Each benchmark is configured in two places:

1. `benchmark_recipes/<id>/recipe.yaml` records stable defaults: partition, run mode, install method, dataset profiles, required input files, and example run arguments.
2. `benchmark_recipes/<id>/run.sh` accepts runtime parameters through command-line arguments and environment variables.

Use `recipe.yaml` first to understand the intended shape:

```bash
less benchmark_recipes/hpl/recipe.yaml
less benchmark_recipes/ior/recipe.yaml
```

Common experiment identity variables are shared by all recipes:

```bash
export EXPERIMENT_ID=repacss-smoke-2026-06-18
export DATASET_ID=small
export DATASET_ROOT=$HOME/data/repacss-benchmarks
export RUN_ROOT=$DATASET_ROOT/runs
export SITE_PROFILE=repacss_zen4
```

Benchmark-specific parameters stay close to each recipe:

```bash
# HPL: positional arguments
bash benchmark_recipes/hpl/run.sh 4 benchmark_recipes/hpl/inputs/hpl/HPL-small.dat

# OSU: positional arguments
bash benchmark_recipes/osu/run.sh osu_latency 2

# IOR: environment variables for a Slurm batch recipe
IOR_TARGETS=MEM_IO,LOCAL_IO \
IOR_NUM_PROCS=1,16,64 \
IOR_BLOCKSIZES=64g,1g,256m \
sbatch benchmark_recipes/ior/run.sh

# LAMMPS: environment variables for input and rank sweep
DATASET_ID=small \
LAMMPS_INPUT=benchmark_recipes/lammps/inputs/lj/in.lj \
LAMMPS_RANKS=256,128,64,32 \
sbatch benchmark_recipes/lammps/run.sh

# Quantum Espresso: environment variables or positional override
QE_NP=4 \
QE_INPUT_FILE=benchmark_recipes/quantum-espresso/inputs/si/si_sssp.scf.in \
bash benchmark_recipes/quantum-espresso/run.sh
```

Production inputs should live under `DATASET_ROOT`, not inside the repository:

```text
$DATASET_ROOT/
|-- hpl/HPL.dat
|-- lammps/in.lj
|-- quantum-espresso/si_long_md.in
`-- ior_nfs/
```

## Multiple-Benchmark Experiments

Use one `EXPERIMENT_ID` for the whole experiment. Each recipe will write its own run directory under the same experiment tree:

```text
$RUN_ROOT/$EXPERIMENT_ID/$SITE_PROFILE/
|-- hpl/<run_id>/
|-- osu/<run_id>/
|-- ior/<run_id>/
`-- lammps/<run_id>/
```

For a small manual run, choose benchmarks with a shell array and dispatch each recipe explicitly:

```bash
export EXPERIMENT_ID=repacss-smoke-2026-06-18
export DATASET_ID=small
export DATASET_ROOT=$HOME/data/repacss-benchmarks
export RUN_ROOT=$DATASET_ROOT/runs
export SITE_PROFILE=repacss_zen4

selected_benchmarks=(hpl osu ior lammps)

for bench in "${selected_benchmarks[@]}"; do
  case "$bench" in
    hpl)
      spack load hpl
      bash benchmark_recipes/hpl/run.sh 4 benchmark_recipes/hpl/inputs/hpl/HPL-small.dat
      ;;
    osu)
      export PATH="$HOME/opt/osu-micro-benchmarks/bin:$PATH"
      bash benchmark_recipes/osu/run.sh osu_latency 2
      ;;
    ior)
      IOR_TARGETS=MEM_IO,LOCAL_IO IOR_NUM_PROCS=1,16,64 sbatch benchmark_recipes/ior/run.sh
      ;;
    lammps)
      DATASET_ID=small LAMMPS_RANKS=256,128,64,32 sbatch benchmark_recipes/lammps/run.sh
      ;;
    *)
      echo "Unknown benchmark: $bench" >&2
      exit 1
      ;;
  esac
done
```

Keep multi-benchmark scripts thin. They should select recipes, set experiment-level environment variables, and call each recipe's `install.sh` or `run.sh`; they should not duplicate benchmark-specific launch logic from `benchmark_recipes/<id>/run.sh`.

## Run Artifacts

Each `run.sh` writes:

- `raw/` for benchmark-native logs and copied inputs
- `normalized/meta.json` for benchmark, job, node, and run identity
- `normalized/telemetry.csv` for normalized performance observations
- `normalized/decisions.csv` for resolved options and inputs
- `normalized/summary.json` for parsed benchmark-specific results

See `operator_docs/artifact_contract.md` for field-level expectations.

## Boundaries

This repository owns benchmark install/run/parse recipes. It does not own power telemetry, TimescaleDB queries, infrastructure monitoring, energy accounting, DVFS policy logic, or data-center portability.

Power data can be joined later by downstream analysis using `job_id`, node list, and run timestamps from the normalized artifacts.

This repository intentionally does not carry project-level assistant rule files. Reusable language policy and assistant behavior are inherited from global configuration.
