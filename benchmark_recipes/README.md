# Benchmark Recipes

Each directory under `benchmark_recipes/` is a REPACSS benchmark recipe.

Required layout:

```text
benchmark_recipes/<id>/
|-- recipe.yaml
|-- install.sh
|-- run.sh
|-- parse.sh
`-- inputs/              # optional benchmark-local inputs
```

## File Responsibilities

- `install.sh`: installation or environment-loading guidance for REPACSS.
- `run.sh`: benchmark execution entrypoint.
- `parse.sh`: normalization entrypoint for raw logs.
- `recipe.yaml`: REPACSS execution metadata, install methods, and dataset profile hints.
- `inputs/`: small benchmark-local inputs for smoke or example runs.

Benchmark classification lives in `benchmark_index/benchmarks.yaml`, not in recipe metadata.

## Run Modes

`launcher` means `run.sh` runs inside an existing allocation or another batch script.

`slurm_batch` means `run.sh` is submitted directly with `sbatch`.

## Install Methods

Each recipe declares its install options under `installation`:

- `system_modules`: use REPACSS-provided modules for the benchmark itself or for compiler, MPI, math, CUDA, and profiling dependencies.
- `user_spack`: install or load the benchmark through a user Spack environment.
- `user_source`: compile the benchmark from upstream source in user space.
- `user_conda`: activate a user MiniForge or Conda environment, mainly for Python, ML, or GPU benchmarks.

See `operator_docs/install_methods.md` for the full model.

## Artifacts

`run.sh` should source `repacss_runtime/artifacts.sh` and write artifacts under:

```text
${RUN_ROOT:-${DATASET_ROOT:-$HOME/data}/runs}/${EXPERIMENT_ID}/${SITE_PROFILE}/${BENCH_ID}/${RUN_ID}
```

The default `SITE_PROFILE` is only a run identity string such as `repacss_zen4`; it is not a portable site profile layer.
