# Benchmark Catalog

This directory stores benchmark taxonomy metadata used for planning, filtering, and portability.

## Files

- `benchmarks.yaml`
  - benchmark entries using the three-layer model (`object`, `semantics`, `execution`)
  - each benchmark entry should include `benchmark_file` pointing to `benchmarks/<id>/benchmark.yaml`
- `taxonomy.schema.yaml`
  - controlled vocabulary and required field reference

## Usage

1. Add new benchmark metadata to `benchmarks.yaml`.
2. Keep required fields complete.
3. Use enum values from `taxonomy.schema.yaml`.
4. Provide `benchmark_file` for each benchmark entry.
5. Mark adapter execution support (for example `repacss.status`).
6. Provide adapter entry points as `prepare_script`, `run_script`, and `parse_script`.
7. Define run-specific subsets in `experiments/*.yaml` instead of editing the catalog.
8. Keep scheduler/module/path specifics in `sites/*.yaml` instead of benchmark entries.
9. Run `bash scripts/check_repo_layout.sh` after catalog edits.

## Notes

- This catalog is intentionally benchmark-centric.
- Power telemetry/profiling taxonomy is out of scope for this repository.
- Treat this directory as stable metadata; experiment selection logic belongs in `experiments/`.
