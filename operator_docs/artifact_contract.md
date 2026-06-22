# REPACSS Benchmark Artifact Contract

Version: `v1`

Each benchmark run should write one run directory:

```text
<RUN_DIR>/
|-- raw/
|-- normalized/
|   |-- meta.json
|   |-- telemetry.csv
|   |-- decisions.csv
|   `-- summary.json
```

## `raw/`

Store benchmark-native outputs needed for auditability:

- benchmark stdout and stderr
- scheduler logs when available
- copied input files or generated working files
- benchmark-native result files

## `normalized/meta.json`

Required fields:

- `schema_version`
- `benchmark_id`
- `benchmark_name`
- `dataset_id`
- `experiment_id`
- `site_profile`
- `run_id`
- `run_dir`
- `job_id`
- `node_list`
- `hostname`
- `start_time_utc`
- `end_time_utc`
- `status`

Recommended fields:

- `partition`
- `run_mode`
- `install_method`
- `git_commit`

The shared helper currently guarantees the required fields. Recipe scripts may add recommended fields later when the launch context can resolve them reliably.

## `normalized/telemetry.csv`

Required header:

```csv
timestamp_utc,phase,metric,value,unit,details
```

This file stores normalized benchmark observations such as runtime, bandwidth, throughput, latency, or parsed benchmark-specific performance metrics.

## `normalized/decisions.csv`

Required header:

```csv
timestamp_utc,component,decision,reason
```

This file records run-time choices such as resolved input file, rank count, dataset id, target filesystem, and environment-derived options.

## `normalized/summary.json`

Required fields:

- `benchmark`
- `status`

Recommended fields:

- `runtime_seconds`
- `success`
- `exit_code`
- benchmark-specific best or final metrics
- parser provenance fields such as source log paths

## Join Keys For Downstream Analysis

Use these fields to join benchmark artifacts with power exports or method orchestration outputs:

- `run_id`
- `job_id`
- `node_list`
- `start_time_utc`
- `end_time_utc`
- `benchmark_id`
- `dataset_id`
