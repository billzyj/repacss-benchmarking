# REPACSS Benchmarking

Benchmark orchestration repository for CPU/GPU/HPC workloads, with a REPACSS-first execution path and a clean extension path to other data centers.

This repository is intentionally **benchmarking-focused**.
Power telemetry, infrastructure queries, and rack/system power analysis are handled externally.

## Scope

What this repository owns:
- Benchmark launch scripts and benchmark-specific wrappers
- REPACSS-oriented run templates (Slurm + module/spack/source workflows)
- Result organization for benchmark performance runs
- A migration path to config-driven benchmark orchestration
- A script-first layout (no Python package installation layer)

What this repository does not own:
- In-band or out-of-band power profiling pipelines
- TimescaleDB and infrastructure power query workflows
- Data center specific power monitoring stacks
- Python packaging metadata for editable installs (`setup.py`, `requirements/`)

For power workflows, use the external project:
- `external/Repacss-power-profiling` (submodule)
- Upstream: <https://github.com/billzyj/Repacss-power-profiling>

## Design Strategy

The key design decision is to separate stable experiment intent from data-center-specific execution details.

### 1. Experiment Contract (portable)
Define *what* to run:
- benchmark id and input scale
- policy id (`max_freq`, `everest`, `oracle_static`, etc.)
- target constraints (`pd_target`, repetitions, warmup, window)
- required output metrics (`runtime`, `perf_rel`, `power_rel`, `energy_rel`)

This layer should stay stable across REPACSS, AMD test nodes, and future data centers.

### 2. Site Profile (replaceable)
Define *how this site runs jobs*:
- scheduler templates and partition/account defaults
- node shape (for example `4xH100`)
- software resolution priority (`module -> spack -> source`)
- site paths, module names, launcher conventions
- vendor backend selection hooks (NVIDIA vs AMD)

This layer is where REPACSS-specific details live.
Site profiles are stored under `sites/*.yaml`.

### 3. Workload Adapter (benchmark-specific)
Each benchmark adapter should expose a minimal lifecycle:
- `prepare()` resolve executable via module/spack/source
- `run()` render and execute launch command
- `parse()` normalize output into a common result schema

This lets you add benchmarks without coupling them to every site implementation.

### 4. External Integrations (optional)
Power is integrated as an external dependency, not embedded into benchmark runners.

## Benchmark Taxonomy (Three-layer)

Benchmark classification now follows three independent layers:
- `object`: what the artifact is (`benchmark`, `suite`, `ranking`, `tool`)
- `semantics`: what it measures (`scope`, `target_subsystems`, `workload_nature`, domain/method tags)
- `execution`: how it runs (`benchmark_scale`, programming model, primary metrics, portability)

Why this matters:
- avoids mixing workload benchmarks with tools/rankings
- supports both REPACSS-first execution and cross-site portability
- keeps classification queryable for run-plan generation

Detailed guide:
- `docs/guides/benchmark_taxonomy.md`

Catalog files:
- `catalog/benchmarks.yaml`
- `catalog/taxonomy.schema.yaml`

## Catalog and Experiment Subsets

Use a three-file pattern:
- `catalog/benchmarks.yaml`: full benchmark registry (all supported benchmarks)
- `experiments/*.yaml`: run-time subset and matrix for a specific study
- `sites/*.yaml`: data-center-specific execution profiles

This keeps benchmark metadata stable while allowing each experiment to select only a subset and bind one site profile.

Recommended selection keys in an experiment file:
- `include_ids`: explicit benchmark ids to include
- `filters`: taxonomy-based filter conditions
- `exclude_ids`: ids to remove after include/filter

Conflict resolution:
1. Start from `include_ids` if provided; otherwise start from all catalog entries.
2. Apply `filters`.
3. Apply `exclude_ids` last (highest priority).

Example:

```yaml
name: core_io_network
site_profile: repacss_zen4

benchmark_selection:
  include_ids: [ior, osu, hpl]
  filters:
    scope: component
    target_subsystems_any: [storage, network]
  exclude_ids: [quantum_espresso]

run_matrix:
  repeats: 5
  warmup: 1
  policies: [max_freq, everest]
```

## Architecture Check (Current)

Current structure is now aligned to the separation-of-concerns goal:
- `catalog/` = machine-readable benchmark registry and taxonomy vocabulary
- `experiments/` = run subset and matrix definitions
- `sites/` = site-specific scheduler/environment/runtime defaults
- `benchmarks/` = executable benchmark wrappers and install/run helpers
- `docs/guides/` = human-readable design rules

Remaining optimization target:
- move per-site execution details out of benchmark entries (`catalog/benchmarks.yaml`) into adapters plus `sites/` resolution rules over time.

## Repository Layout (Current)

| Path | Purpose | Design Mapping |
|---|---|---|
| `catalog/` | Machine-readable benchmark registry and taxonomy vocabulary. | Experiment Contract + Taxonomy |
| `catalog/benchmarks.yaml` | Full list of supported benchmarks and their normalized metadata. | Experiment Contract |
| `catalog/taxonomy.schema.yaml` | Controlled vocabulary for fields/enums used by benchmark entries. | Taxonomy Governance |
| `experiments/` | Run-specific subset definitions and parameter matrices. | Experiment Contract (run instance) |
| `experiments/core_subset.yaml` | Example subset selecting benchmarks and run matrix values. | Experiment Selection |
| `sites/` | Site-specific execution profiles with scheduler/runtime defaults. | Site Profile |
| `sites/repacss_h100.yaml` | REPACSS GPU-node defaults (partition/resources/runtime backend). | Site Profile |
| `sites/repacss_zen4.yaml` | REPACSS CPU-node defaults (partition/resources/runtime backend). | Site Profile |
| `benchmarks/` | Benchmark adapters and helper scripts for prepare/run behavior. | Workload Adapter |
| `benchmarks/hpl/`, `benchmarks/osu/`, `benchmarks/ior/`, `benchmarks/lammps/` | Per-benchmark scripts for installation/run entry points. | Workload Adapter |
| `benchmarks/templates/` | Reusable Slurm template scripts for REPACSS partitions. | Site Profile Integration |
| `docs/guides/benchmark_taxonomy.md` | Human-readable design rules and classification principles. | Design Documentation |
| `external/Repacss-power-profiling/` | External submodule for power/infrastructure telemetry workflows. | External Integration |
| `README.md` | Repository-wide architecture, scope, and usage entry point. | Governance + Onboarding |

## REPACSS Quick Start (Run Now)

### Prerequisites
- Slurm access on REPACSS
- MPI runtime available on target partition
- Benchmark binaries available by one of:
  - module
  - spack
  - source build in user space

### Install Helpers

OSU:
```bash
bash benchmarks/osu/install_osu.sh module
# or
bash benchmarks/osu/install_osu.sh spack
# or
bash benchmarks/osu/install_osu.sh source
```

HPL:
```bash
bash benchmarks/hpl/install_hpl.sh module
# or
bash benchmarks/hpl/install_hpl.sh spack
# or
bash benchmarks/hpl/install_hpl.sh source
```

### Run IOR on Zen4

`benchmarks/ior/run_ior_repacss.sh` is a complete Slurm batch job.
Before submission, ensure these directories are set in your shell or directly in the script:
- `MEM_IO`
- `LOCAL_IO`
- `NFS_IO`

Submit:
```bash
sbatch benchmarks/ior/run_ior_repacss.sh
```

### Run LAMMPS on Zen4

Submit:
```bash
sbatch benchmarks/lammps/run_lammps_repacss.sh
```

Notes:
- Script currently expects LAMMPS from Spack (`spack load lammps`)
- Script currently uses `~/data` as working directory

### Run HPL

`benchmarks/hpl/run_hpl_repacss.sh` is a launcher wrapper (not a full Slurm script).
Use it inside an allocation or from your own batch script.

Example:
```bash
# inside an allocated job shell
module load hpl
bash benchmarks/hpl/run_hpl_repacss.sh 4 /path/to/HPL.dat
```

### Run OSU

`benchmarks/osu/run_osu_repacss.sh` is a launcher wrapper.

Example:
```bash
# inside an allocated job shell
module load osu-micro-benchmarks
bash benchmarks/osu/run_osu_repacss.sh osu_latency 2
```

## Current vs Target Output Contract

Current state:
- Slurm stdout/stderr (`slurm-*.out`, `slurm-*.err`)
- Benchmark native logs (for example IOR warm/cold logs)

Target state (recommended contract for future orchestration):
- `meta.json`
- `telemetry.csv`
- `decisions.csv`
- `summary.json`
- aggregated `results.csv`

This contract is recommended so new policies/methods can be added without changing analysis code.

## REPACSS-First, Then Portable

To avoid over-abstracting too early, use a phased approach:

### Phase A (immediate)
- Run on existing REPACSS H100/Zen4 resources
- Start with easiest benchmarks already available via modules
- Validate end-to-end run reliability and output collection

### Phase B
- Fill missing benchmark install paths (spack/source)
- Expand benchmark coverage gradually
- Start introducing config-driven matrix expansion

### Phase C
- Add AMD test node profile
- Reuse same experiment contract for cross-vendor runs
- Keep power as optional external join in analysis

## Extension Plan for Other Data Centers

When porting to a new site:
1. Keep benchmark definitions and experiment matrix unchanged
2. Add a new profile under `sites/` (scheduler + software resolution + launcher conventions)
3. Adjust benchmark `prepare()` only where site software layout differs
4. Keep output schema unchanged

This minimizes migration effort and preserves reproducibility.

## External Power Integration

This repo can be paired with external power data after runs complete.
Suggested workflow:
1. Run benchmark jobs from this repository
2. Collect power/infrastructure data from `Repacss-power-profiling`
3. Join by job id / node / timestamp window in post-processing

## Practical Notes

- `benchmarks/quantum-espresso/run_espresso_repacss.sh` is currently a placeholder.
- The active taxonomy and design rules are documented in `docs/guides/benchmark_taxonomy.md`.
- The experiment-subset pattern is documented in `experiments/README.md`.
- Site profile conventions are documented in `sites/README.md`.

## License

BSD 3-Clause. See `LICENSE`.
