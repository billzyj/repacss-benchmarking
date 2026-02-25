# Benchmark Taxonomy Design Guide

This guide defines the benchmark classification model for this repository.

Goal:
- make benchmark metadata searchable and consistent
- separate benchmark semantics from site-specific execution details
- keep REPACSS-first execution simple while preserving portability

## Why a new taxonomy

A single `system/component` label is not enough. It mixes together:
- what an artifact is (benchmark vs suite vs tool)
- what it measures (CPU/memory/network/storage/GPU)
- how it is executed (single-node/multi-node, MPI/CUDA/HIP, vendor constraints)

The taxonomy here uses three independent layers.

## Three-layer model

## Layer 1: Object Layer (`object`)

Describes what the artifact is.

Required fields:
- `artifact_type`: `benchmark | suite | ranking | tool`

Optional fields:
- `parent_suite`: for a benchmark inside a suite
- `children`: for suites that include multiple benchmarks

Examples:
- HPL -> `artifact_type=benchmark`
- HPCC -> `artifact_type=suite`
- Green500 -> `artifact_type=ranking`
- PAPI/Darshan -> `artifact_type=tool`

## Layer 2: Semantic Layer (`semantics`)

Describes workload meaning and measurement intent.

Required fields:
- `scope`: `system | component`
- `target_subsystems`: list from `cpu, memory, network, storage, gpu, mixed`
- `workload_nature`: `synthetic | proxy | real_app`

Recommended fields:
- `application_domain`: `md, cfd, weather, chemistry, ai_ml, io, communication, ...`
- `method_type`: `dense_la, sparse_la, fft, graph, monte_carlo, ...`
- `characteristics`: list from `compute, memory_access, communication, io, control_flow`

## Layer 3: Execution Layer (`execution`)

Describes runtime constraints and comparability boundaries.

Required fields:
- `benchmark_scale`: `single_node | multi_node | both`
- `programming_models`: list from `mpi, openmp, cuda, hip, openacc, sycl, pthread, ...`
- `metrics_primary`: list from `time_to_solution, flops, bandwidth, latency, throughput, energy_to_solution`

Recommended fields:
- `programming_languages`: list such as `c, c++, fortran, python`
- `portability`: `cpu_only | nvidia_only | amd_only | cross_vendor`
- `runtime_needs`: mpi/gpu driver/container requirements

## Design principles

1. Orthogonality
Each field should answer one question only. Do not encode execution constraints in semantic fields.

2. Non-overlap
Do not label tools and rankings as workload benchmarks. Use `artifact_type` to separate them.

3. Normalized values
Use fixed enums for high-level filters. Add free-text only as supplemental notes.

4. Suite decomposition
Treat a suite as a container. Record suite-level metadata and benchmark-level metadata separately.

5. Comparability guardrail
Never compare unlike metrics directly. For example, network latency and HPL FLOPS should not share one scalar score.

6. Portability-first semantics
Keep Layer 1 and Layer 2 site-agnostic. Put site details in site profiles and adapters.

7. Vendor explicitness
Use explicit portability tags (`nvidia_only`, `amd_only`, `cross_vendor`) to prevent accidental cross-vendor assumptions.

8. Minimal required contract
Only keep a small required set so onboarding new benchmarks is fast.

9. Evolution-safe
Allow adding new enum values without breaking old benchmark entries.

10. REPACSS-first workflow
A benchmark can be `taxonomy-complete` even before every site adapter exists.

## Mapping to benchmark-survey style dimensions

This taxonomy aligns with the benchmark-survey tag style by keeping explicit dimensions for:
- `benchmark_scale`
- `programming_models`
- `programming_languages`
- `application_domain`
- `method_type`
- `characteristics` (compute/memory/communication/io)

Repository-specific additions:
- `artifact_type` (benchmark/suite/ranking/tool)
- `metrics_primary`
- `portability`

These additions improve engineering workflow and run-plan generation.

## Practical classification examples

- HPL
  - object: `benchmark`
  - semantics: `system`, `mixed`, `synthetic`, `dense_la`
  - execution: `multi_node`, `mpi`, `flops/time_to_solution`, `cpu_only`

- OSU Micro-Benchmarks
  - object: `benchmark`
  - semantics: `component`, `network`, `synthetic`, `communication`
  - execution: `single_node|multi_node`, `mpi`, `latency/bandwidth`

- IOR
  - object: `benchmark`
  - semantics: `component`, `storage`, `synthetic`, `io`
  - execution: `single_node|multi_node`, `mpi`, `bandwidth/throughput`

- LAMMPS
  - object: `benchmark`
  - semantics: `system`, `mixed`, `real_app`, `md`
  - execution: `single_node|multi_node`, `mpi(+optional gpu backends)`, `time_to_solution`

## Onboarding checklist

For each new benchmark entry:
1. Fill all required fields in `catalog/benchmarks.yaml`.
2. Validate enum values against `catalog/taxonomy.schema.yaml`.
3. Add adapter status (`ready` or `wip`) and script paths.
4. Bind runtime site details through a profile in `sites/*.yaml`.
5. Record the primary metric used for baseline comparison.
6. Avoid power-specific metrics in this repo; join with external power data later.
