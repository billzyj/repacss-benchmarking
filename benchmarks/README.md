# Workload Adapters

This directory stores benchmark-specific adapters.

Adapter contract (per benchmark):
- `benchmark.yaml`: site-agnostic benchmark metadata and adapter entry points
- `adapters/<site>/prepare.sh`: resolve/install runtime environment for a site
- `adapters/<site>/run.sh`: execute one benchmark run
- `adapters/<site>/parse.sh`: normalize raw outputs into a summary artifact
- `inputs/` (optional): static benchmark-local input files/templates

Recommended benchmark layout:
- `benchmarks/<id>/benchmark.yaml`
- `benchmarks/<id>/adapters/<site>/prepare.sh`
- `benchmarks/<id>/adapters/<site>/run.sh`
- `benchmarks/<id>/adapters/<site>/parse.sh`
- `benchmarks/<id>/inputs/` (optional, benchmark-specific static input templates)

Run artifact contract (REPACSS baseline):
- `<RUN_DIR>/raw/`: benchmark native logs and raw outputs
- `<RUN_DIR>/normalized/meta.json`
- `<RUN_DIR>/normalized/telemetry.csv`
- `<RUN_DIR>/normalized/decisions.csv`
- `<RUN_DIR>/normalized/summary.json`

Default run directory:
- `${RUN_ROOT:-${DATASET_ROOT:-$HOME/data}/runs}/${EXPERIMENT_ID}/${SITE_PROFILE}/${BENCH_ID}/${RUN_ID}`

Where:
- `RUN_ROOT` defaults to site workspace (`$HOME/data/runs`)
- `EXPERIMENT_ID` defaults to `manual`
- `SITE_PROFILE` defaults per adapter (`repacss_zen4` or `repacss_h100`)
- `RUN_ID` defaults to `job-$SLURM_JOB_ID` or a local timestamp

Shared helper:
- `benchmarks/common/repacss_contract.sh` provides directory creation and artifact initialization helpers for adapters.

Configuration boundary:
- Site-dependent: scheduler/runtime/module/path details (`sites/*.yaml`, batch templates).
- Site-independent: benchmark intent, dataset profile id, and run arguments.
- Mixed: dataset identity is site-independent, dataset filesystem path is site-dependent.

Fields in `benchmark.yaml`:
- `adapter_default`: default site key for local invocation.
- `datasets.id_env` / `datasets.root_env`: portable dataset id + site-specific dataset root.
- `adapters.<site>.run_mode`: `launcher` or `slurm_batch`.
  `launcher` means run inside an allocation.
  `slurm_batch` means the adapter script itself is a batch script submitted via `sbatch`.

Compatibility:
- Legacy `run_*_repacss.sh` and `install_*` script paths are kept as wrappers.
- New integrations should use adapter paths directly.

Cleanup policy:
- Do not add new root-level `config.json` files under benchmark directories.
- Keep benchmark root minimal; place executable behavior under `adapters/`.
- Do not keep transient run artifacts (checkpoint files, slurm logs, native output logs) in benchmark source directories.

Starter templates:
- Use `benchmarks/templates/dummy-benchmark` as a baseline when adding a new benchmark adapter.
