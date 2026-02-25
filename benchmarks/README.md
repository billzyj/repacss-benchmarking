# Workload Adapters

This directory stores benchmark-specific adapters.

Adapter contract (per benchmark):
- `benchmark.yaml`: site-agnostic benchmark metadata and adapter entry points
- `adapters/<site>/prepare.sh`: resolve/install runtime environment for a site
- `adapters/<site>/run.sh`: execute one benchmark run
- `adapters/<site>/parse.sh`: normalize raw outputs into a summary artifact

Recommended benchmark layout:
- `benchmarks/<id>/benchmark.yaml`
- `benchmarks/<id>/adapters/<site>/prepare.sh`
- `benchmarks/<id>/adapters/<site>/run.sh`
- `benchmarks/<id>/adapters/<site>/parse.sh`
- `benchmarks/<id>/inputs/` (optional, benchmark-specific static input templates)

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

Starter templates:
- Use `benchmarks/templates/dummy-benchmark` as a baseline when adding a new benchmark adapter.
