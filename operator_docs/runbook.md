# REPACSS Benchmark Runbook

## Prerequisites

- Slurm access on REPACSS
- Access to the target partition
- Benchmark software available through user Spack, user-space source build, a complete REPACSS module, or a user Conda environment
- REPACSS system modules available for compiler, MPI, math, CUDA, and profiling dependencies when a recipe needs them
- `$HOME/data` or `DATASET_ROOT` available for run artifacts and production inputs

## Optional Debug Allocations

For CPU benchmark debugging with the CXL reservation:

```bash
salloc -p zen4 --exclusive -t 04:00:00 --reservation=cxl
```

If the reservation is unavailable, retry without `--reservation=cxl`.

For GPU benchmark debugging with the CXL reservation:

```bash
salloc -p h100 -t 04:00:00 --reservation=cxl
```

If the reservation is unavailable, retry without `--reservation=cxl`.

Release the allocation with:

```bash
exit
```

## Common Environment Variables

- `DATASET_ID`: dataset profile, usually `small` or `production`
- `DATASET_ROOT`: default `$HOME/data`
- `RUN_ROOT`: default `${DATASET_ROOT}/runs`
- `EXPERIMENT_ID`: default `manual`
- `SITE_PROFILE`: default run identity such as `repacss_zen4`
- `RUN_ID`: default `job-$SLURM_JOB_ID` or a local timestamp

## Cluster Reference

Use the static hardware reference when choosing benchmark parameters:

```bash
less repacss_cluster/hardware.yaml
```

Use live scheduler state before launch:

```bash
sinfo -p zen4,h100,h100-build,mi210
```

The file `repacss_cluster/sinfo_snapshot.txt` records a 2026-06-18 snapshot only. Do not use it as the current node-state source.

Use the module inventory when choosing an install method:

```bash
less repacss_cluster/modules.yaml
module avail
```

The file `repacss_cluster/modules.yaml` records known REPACSS system modules by partition. Use live `module avail` before relying on a module.

## Install Or Load Benchmarks

Each recipe has an `install.sh` entrypoint:

```bash
bash benchmark_recipes/osu/install.sh source
bash benchmark_recipes/hpl/install.sh spack
bash benchmark_recipes/ior/install.sh spack
bash benchmark_recipes/lammps/install.sh spack
```

The install scripts are intentionally lightweight. They show the REPACSS system-module, Spack, source-build, or Conda path for each benchmark without hiding site-specific build decisions.

Install methods:

- `system_modules`: use REPACSS-provided benchmark modules or dependency modules.
- `user_spack`: install or load the benchmark with user Spack.
- `user_source`: compile upstream source code in user space.
- `user_conda`: use a user MiniForge or Conda environment, mainly for Python, ML, and GPU benchmarks.

See `operator_docs/install_methods.md` before adding or changing installation paths.

## IOR

Submit directly:

```bash
sbatch benchmark_recipes/ior/run.sh
```

Useful overrides:

```bash
IOR_TARGETS=MEM_IO,LOCAL_IO \
IOR_NUM_PROCS=1,16,64 \
sbatch benchmark_recipes/ior/run.sh
```

## LAMMPS

Submit directly:

```bash
sbatch benchmark_recipes/lammps/run.sh
```

Small run input defaults to `benchmark_recipes/lammps/inputs/lj/in.lj`.

## HPL

Run inside an allocation:

```bash
bash benchmark_recipes/hpl/install.sh spack
spack load hpl
bash benchmark_recipes/hpl/run.sh 4 benchmark_recipes/hpl/inputs/hpl/HPL-small.dat
```

## OSU Micro-Benchmarks

Run inside an allocation:

```bash
bash benchmark_recipes/osu/install.sh source
export PATH="$HOME/opt/osu-micro-benchmarks/bin:$PATH"
bash benchmark_recipes/osu/run.sh osu_latency 2
```

## Quantum Espresso

Quantum Espresso support is experimental. Run inside an allocation after loading `pw.x`:

```bash
bash benchmark_recipes/quantum-espresso/install.sh spack
spack load quantum-espresso
bash benchmark_recipes/quantum-espresso/run.sh 4 benchmark_recipes/quantum-espresso/inputs/si/si_sssp.scf.in
```

## Verification

Run before committing structural changes:

```bash
bash repo_tools/check_repo_layout.sh
find benchmark_recipes repacss_runtime repo_tools -name '*.sh' -print0 | xargs -0 bash -n
```
