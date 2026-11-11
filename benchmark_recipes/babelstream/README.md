# BabelStream CUDA memory bandwidth

**Status: experimental.** Built with `cuda/12.9.1` and run on an H100 node.

## Purpose and profiles

`smoke` uses 1,048,576 double-precision elements per array (24 MiB for three
arrays), with 10 iterations. This is a functional check and may measure cache.
`hbm` uses 268,435,456 elements per array (6 GiB total) with 100 iterations;
`hbm-large` doubles the size (12 GiB total). Host allocation/checking also needs memory.
All five classic kernels run; the first iteration is excluded by upstream statistics.
Bandwidth is decimal MB/s from each kernel's minimum runtime. Preserve all kernels.
The HBM profiles are candidates: test size stability and kernel duration before drawing
memory-bandwidth conclusions. CUDA builds link NVML for device information, without
changing clock settings. See the upstream custom license/Run Rules before publication.

Exact arguments are in [`upstream.json`](upstream.json); common operating rules and
measurement boundaries are in [the GPU suite guide](../../operator_docs/gpu_benchmark_suite.md).

## External GitHub / source code info and Reference

- Official source: [https://github.com/UoB-HPC/BabelStream](https://github.com/UoB-HPC/BabelStream).
- Pinned commit: [`17ab377b0e919e14fd3df2b67268761fdac8abb3`](https://github.com/UoB-HPC/BabelStream/tree/17ab377b0e919e14fd3df2b67268761fdac8abb3).
- License: STREAM-derived custom license; see upstream LICENSE and Run Rules.
- Survey relationship: Direct benchmark entry: benchmarks.babelstream.
- Survey snapshot: [benchmark list](https://github.com/FZJ-JSC/benchmark-survey/blob/34c82039381af95c214d37f67e7538a2e8178aed/benchmarks.yaml).
- Reference: Deakin, T., Price, J., Martineau, M., and McIntosh-Smith, S. Evaluating attainable memory bandwidth of parallel programming models via BabelStream. IJCSE 17(3), 247–262 (2018). [Source/reference](https://doi.org/10.1504/IJCSE.2018.095847).

## Prepare and run later

```bash
# From repository root; module/environment prerequisites are in the suite guide.
bash benchmark_recipes/babelstream/install.sh source
# Explicitly download and compile only when the build node is available:
bash benchmark_recipes/babelstream/install.sh source --execute
# Print native argv without running or querying a GPU:
bash benchmark_recipes/babelstream/run.sh --profile hbm --print-command
# Inside an existing single-node allocation; request one task:
srun --nodes=1 --ntasks=1 --cpus-per-task=8 --gpus-per-task=1 \
  bash benchmark_recipes/babelstream/run.sh --profile smoke
# Offline parsing of a completed run:
bash benchmark_recipes/babelstream/parse.sh /absolute/path/to/run-directory
```

Use `--repetitions 5` after a separate pilot, and `--timeout-seconds` for a per-run
failure limit. NCCL additionally accepts `--gpus 2` or `--gpus 4`; other recipes use
one GPU. `GPU_ARCH` defaults to `sm_90`; `GPU_BENCH_BUILD_ROOT`, `BUILD_JOBS`,
`CUDA_HOME`, and (for NCCL) `NCCL_HOME` configure later builds.

Raw logs, process timing, build provenance and input hashes accompany normalized
`meta.json`, `summary.json`, `telemetry.csv` and `decisions.csv`.
These recipes do not set GPU clocks or power caps. An external DVFS controller
must record achieved clocks and matching energy intervals.

## Tests

See [`TEST_PLAN.md`](TEST_PLAN.md) for the full test plan. The build and the `smoke` and
`hbm-long` profiles have been run on H100; the parser negative cases and the HBM pilot have not.
