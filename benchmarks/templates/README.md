# Adapter-first Job Templates

These templates are examples of how to run benchmark adapters under Slurm.

## Design intent

- Keep site-specific execution controls in Slurm directives and environment setup.
- Keep benchmark-specific intent in adapter selection and benchmark arguments.
- Keep dataset identity independent from site path layout.

## Configuration split

### Site-dependent (from `sites/*.yaml`)
- Slurm resources (`partition`, `nodes`, `ntasks`, `cpus-per-task`, `gres`, `time`)
- Module names and runtime launcher defaults
- Filesystem roots and scratch paths

### Site-independent (benchmark/experiment intent)
- Benchmark id (`BENCH_ID`)
- Adapter site key (`ADAPTER_SITE`)
- Dataset profile id (`DATASET_ID`, e.g. `small`, `production`)
- Benchmark arguments (`RUN_ARGS`)

### Mixed (identity vs location)
- Dataset identity is site-independent (`DATASET_ID`)
- Dataset path is site-dependent (`DATASET_ROOT`)

## Template usage notes

- `zen4_batch.sh` and `h100_batch.sh` are templates for launcher-style adapters.
- For adapters that are already full batch scripts, submit adapter directly:
  `sbatch benchmarks/<id>/adapters/repacss/run.sh`

## Dummy benchmark starter

Use `dummy-benchmark/` as a copy-and-edit starter when onboarding a new benchmark.

Includes:
- `dummy-benchmark/benchmark.yaml`
- `dummy-benchmark/adapters/repacss/prepare.sh`
- `dummy-benchmark/adapters/repacss/run.sh`
- `dummy-benchmark/adapters/repacss/parse.sh`
- `dummy-benchmark/inputs/dummy_small.in`

Create a new benchmark from template:

```bash
cp -R benchmarks/templates/dummy-benchmark benchmarks/<new-id>
```

Then update:
1. `benchmark.yaml` (`id`, `name`, adapter scripts, dataset profiles)
2. `prepare.sh` (module/spack/source resolution)
3. `run.sh` (real launch command + input resolution logic + run artifact contract)
4. `parse.sh` (result normalization into `meta.json/telemetry.csv/decisions.csv/summary.json`)
5. `inputs/` files (if file-based inputs are required)

## Output contract (required)

Each run should write artifacts under a single run directory:

```text
<RUN_DIR>/
  raw/
  normalized/
    meta.json
    telemetry.csv
    decisions.csv
    summary.json
```

Recommended default:

```text
${RUN_ROOT:-${DATASET_ROOT:-$HOME/data}/runs}/${EXPERIMENT_ID}/${SITE_PROFILE}/${BENCH_ID}/${RUN_ID}
```

Use helper functions from:
- `benchmarks/common/repacss_contract.sh`

## Input contract (`benchmark.yaml`)

Recommended fields under `inputs`:
- `mode`: default input mode (`parametric`, `file_bundle`, `hybrid`)
- `supported_modes`: explicit supported modes list
- `profile_env`: dataset profile selector env var (for example `DATASET_ID`)
- `root_env`: site-dependent dataset root env var (for example `DATASET_ROOT`)
- `profiles`: profile definitions including `mode`, `required_files`, and `run_args`

Mode guidance:
- `parametric`: input generated directly from runtime args, no required files.
- `file_bundle`: input requires benchmark-local files (usually under `inputs/`).
- `hybrid`: input uses both files and runtime args.
