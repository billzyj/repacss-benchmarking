# Benchmark Index

`benchmark_index/benchmarks.yaml` is the source of truth for benchmark identity and classification.

This index intentionally does not describe scheduler settings, module names, filesystem paths, run matrices, or power metrics. REPACSS execution details live in each benchmark recipe under `benchmark_recipes/<id>/`.

Required classification sections for each benchmark:

- `object`: what the artifact is
- `semantics`: what the benchmark measures
- `execution`: how the workload executes and which primary metrics it reports

Run `bash repo_tools/check_repo_layout.sh` after editing the index.
