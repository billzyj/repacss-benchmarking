# REPACSS Cluster Reference

This directory stores REPACSS cluster facts used by benchmark recipes.

## Files

- `hardware.yaml`: stable partition and hardware reference. Update only when REPACSS hardware inventory or Slurm partition definitions change.
- `modules.yaml`: REPACSS system module inventory by partition. Use it to distinguish system-provided benchmark modules from system-provided dependency modules.
- `sinfo_snapshot.txt`: scheduler-state snapshot from 2026-06-18. This is dynamic operational context, not an immutable source of truth.

## Use In Benchmark Recipes

Use `hardware.yaml` for stable defaults and parameter reasoning:

- CPU cores and NUMA shape
- GPU count and GPU memory
- RAM size
- local storage notes
- partition-to-hardware mapping

Use live `sinfo` output before launching jobs:

```bash
sinfo -p zen4,h100,h100-build,mi210
```

The scheduler state changes frequently. Do not hard-code `idle`, `mix`, `alloc`, or `resv` node lists into benchmark recipes.

Use `modules.yaml` for install-method reasoning:

- benchmark or performance modules already provided by REPACSS
- compiler, MPI, math, CUDA, and profiling dependency modules
- partition-specific module roots

Always confirm live availability with `module avail` before running installation or launch commands.
