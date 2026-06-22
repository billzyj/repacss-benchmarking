# Architecture

## Role

`repacss-benchmarking` is the REPACSS benchmark install/run repository. It keeps benchmark-specific recipes close to their inputs and separates shared REPACSS runtime helpers from benchmark classification metadata.

The repository is intentionally not a portable data-center framework.

## Boundaries

This repository owns:

- benchmark-local install guidance and preparation scripts
- benchmark launch scripts for REPACSS
- benchmark-native raw output preservation
- normalized benchmark result artifacts
- benchmark identity and classification metadata

This repository does not own:

- telemetry ingestion
- power query logic
- energy accounting
- DVFS policy decisions
- cross-data-center migration layers

## Source Of Truth

`benchmark_recipes/<id>/recipe.yaml` answers how to install and run one benchmark on REPACSS.

`benchmark_recipes/<id>/install.sh`, `run.sh`, and `parse.sh` are the executable recipe commands.

`repacss_runtime/artifacts.sh` stores shared run-directory and artifact helpers.

`repacss_cluster/hardware.yaml` stores stable REPACSS partition hardware facts. Benchmark recipes reference it through their `partition` and `hardware_reference` fields.

`repacss_cluster/modules.yaml` stores the REPACSS system module inventory used by recipe installation metadata.

`repacss_cluster/sinfo_snapshot.txt` stores a captured scheduler-state example. It is not a source of immutable hardware facts.

`benchmark_index/benchmarks.yaml` answers what each benchmark is and what it measures.

## Directory Model

The root layout uses five stable roles:

| Role | Path | Owns | Does Not Own |
|---|---|---|---|
| Recipe layer | `benchmark_recipes/` | benchmark-local install, run, parse, inputs, dataset hints | global benchmark taxonomy |
| Runtime layer | `repacss_runtime/` | shared run-directory and artifact helpers | benchmark-specific parsing |
| Cluster reference layer | `repacss_cluster/` | hardware facts, module inventory, scheduler snapshots | live scheduler or module state |
| Index layer | `benchmark_index/` | benchmark identity and classification | install methods, scheduler resources, paths |
| Operator layer | `operator_docs/` | human workflow, architecture, install model, artifact contract | executable benchmark behavior |

This keeps the repository small while still making each decision easy to locate.

## Data Flow

```text
benchmark_recipes/<id>/run.sh
  -> benchmark-native execution
  -> raw logs under <RUN_DIR>/raw
  -> benchmark_recipes/<id>/parse.sh
  -> normalized/meta.json
  -> normalized/telemetry.csv
  -> normalized/decisions.csv
  -> normalized/summary.json
```

Downstream repos should consume run artifacts. They should not depend on fixed checkout paths or recipe internals.

## Static And Dynamic Cluster Data

Use `repacss_cluster/hardware.yaml` for stable benchmark parameter reasoning, such as ranks per node, GPU count, memory capacity, and storage assumptions.

Use `repacss_cluster/modules.yaml` for install-method reasoning, such as whether REPACSS already provides a benchmark module or only a dependency stack.

Use live `sinfo` output for launch decisions, because node state changes frequently.

Use live `module avail` output for final install decisions, because module inventory can change independently of this repository.

## Adding A Benchmark

1. Add a directory under `benchmark_recipes/<id>/`.
2. Add `recipe.yaml` with REPACSS execution metadata.
3. Add an `installation` block with `system_modules`, `user_spack`, `user_source`, or `user_conda` methods as appropriate.
4. Add `install.sh`, `run.sh`, and `parse.sh`.
5. Add benchmark classification to `benchmark_index/benchmarks.yaml`.
6. Make sure the recipe `partition` exists in `repacss_cluster/hardware.yaml` and `repacss_cluster/modules.yaml` when it uses system modules.
7. Run `bash repo_tools/check_repo_layout.sh`.
