# Experiments

This directory stores run-specific experiment definitions.

## Purpose

Use experiment files to select a subset of benchmarks from `catalog/benchmarks.yaml` and define run matrix settings.

Keep benchmark metadata in `catalog/` stable. Do not create experiment-specific forks of the catalog.

## Suggested Structure

```yaml
name: core_io_network
site_profile: repacss_zen4

benchmark_selection:
  include_ids: [ior, osu, hpl]
  filters:
    scope: component
    target_subsystems_any: [storage, network]
  exclude_ids: [quantum_espresso]

run_matrix:
  repeats: 5
  warmup: 1
  policies: [max_freq, everest]
```

## Selection Order

1. Start from `include_ids` if present; otherwise start from all catalog entries.
2. Apply `filters`.
3. Apply `exclude_ids` last.

This makes `exclude_ids` the highest-priority override.

## Site Profile Binding

- `site_profile` should reference a file in `sites/` (without `.yaml` suffix).
- Example: `site_profile: repacss_zen4` maps to `sites/repacss_zen4.yaml`.
