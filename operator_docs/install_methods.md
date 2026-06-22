# Install Methods

REPACSS benchmark recipes support two broad install paths: system-provided software and user-owned software. The recipe metadata keeps these paths explicit so operators can tell whether a command is loading an existing module, installing with Spack, compiling source code, or using a user Conda environment.

## Method Names

| Method | Owner | Purpose |
|---|---|---|
| `system_modules` | REPACSS system | Use modules already available on REPACSS. These may provide the benchmark itself or only compiler, MPI, math, CUDA, or profiling dependencies. |
| `user_spack` | User | Install the benchmark in user space with Spack. |
| `user_source` | User | Compile upstream source code in user space, usually after loading compiler/MPI/math modules. |
| `user_conda` | User | Use a user-managed MiniForge or Conda environment, mainly for Python, ML, or GPU benchmarks. |

Each recipe supports only the methods listed in its `recipe.yaml`. When a method is supported, `install.sh` accepts short aliases for convenience:

```bash
bash benchmark_recipes/<id>/install.sh module
bash benchmark_recipes/<id>/install.sh spack
bash benchmark_recipes/<id>/install.sh source
bash benchmark_recipes/<id>/install.sh conda
```

The canonical names in `recipe.yaml` remain `system_modules`, `user_spack`, `user_source`, and `user_conda`.

No current recipe requires `user_conda`; it is reserved for future Python, ML, and GPU benchmark recipes.

## System Modules

System modules are listed in `repacss_cluster/modules.yaml`. They are partition-specific because Zen4 and H100 have different module roots and GPU dependencies.

For the current recipes, most `system_modules` entries are dependency stacks rather than complete benchmark binaries. For example, HPL can use REPACSS-provided compiler, MPI, and BLAS modules, but the benchmark binary may still need to come from Spack or a user source build.

Use live module commands before launching jobs:

```bash
module avail
module avail openmpi
module avail cuda
```

## User Spack

Use `user_spack` when the benchmark is not available as a complete REPACSS module or when the run needs a user-controlled package variant.

Typical flow:

```bash
bash benchmark_recipes/<id>/install.sh spack
spack load <package>
bash benchmark_recipes/<id>/run.sh
```

The install script prints the package name and expected load command. It does not hide site-specific Spack compiler or external package choices.

## User Source Build

Use `user_source` when a benchmark needs a custom upstream checkout, local patches, or a build mode that is awkward to express in Spack.

Typical flow:

```bash
module load gcc/15.2.0 openmpi/4.1.8 openblas/0.3.30
bash benchmark_recipes/<id>/install.sh source
```

The exact configure and compiler flags remain benchmark-specific.

## User Conda

Use `user_conda` for Python, ML, and GPU benchmarks that need a user-managed environment. REPACSS recommends MiniForge for this path. Follow the REPACSS MiniForge guide before running a Conda-backed recipe:

```text
https://guide.repacss.org/software/miniforge.html
```

The REPACSS MiniForge guide describes this as the path for user-installed Python-based data science, machine learning, and scientific computing packages.

A Conda-backed GPU recipe should still load the required system GPU modules first, such as CUDA, cuDNN, or NCCL on H100, then activate the recipe-specific environment.

Example shape:

```bash
module load cuda/13.0.2 cudnn/9.8.0.87-12 nccl/2.28.7-1
conda activate repacss-<benchmark>
bash benchmark_recipes/<id>/run.sh
```

## Recipe Metadata

Each `recipe.yaml` should declare:

- `installation.default_method`
- `installation.supported_methods`
- `installation.system_modules.module_inventory` when `system_modules` is supported
- `installation.user_spack.package` when `user_spack` is supported
- `installation.user_source.upstream` when `user_source` is supported
- `installation.user_conda.environment` when `user_conda` is supported
