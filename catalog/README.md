# Benchmark Catalog

This directory stores benchmark taxonomy metadata used for planning, filtering, and portability.

## Files

- `benchmarks.yaml`
  - benchmark entries using the three-layer model (`object`, `semantics`, `execution`)
- `taxonomy.schema.yaml`
  - controlled vocabulary and required field reference

## Usage

1. Add new benchmark metadata to `benchmarks.yaml`.
2. Keep required fields complete.
3. Use enum values from `taxonomy.schema.yaml`.
4. Mark adapter execution support (for example `repacss.status`).
5. Define run-specific subsets in `experiments/*.yaml` instead of editing the catalog.
6. Keep scheduler/module/path specifics in `sites/*.yaml` instead of benchmark entries.

## Notes

- This catalog is intentionally benchmark-centric.
- Power telemetry/profiling taxonomy is out of scope for this repository.
- Treat this directory as stable metadata; experiment selection logic belongs in `experiments/`.
