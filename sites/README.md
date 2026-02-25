# Site Profiles

This directory stores data-center-specific execution profiles.

Purpose:
- keep scheduler, resource, and software-environment details out of `catalog/`
- allow the same benchmark catalog and experiment matrix to run across sites

## Files

- `repacss_h100.yaml`: REPACSS GPU-node execution defaults
- `repacss_zen4.yaml`: REPACSS CPU-node execution defaults

## Notes

- `catalog/benchmarks.yaml` remains site-agnostic benchmark metadata.
- `experiments/*.yaml` chooses one `site_profile` per run.
- Site profiles define how to resolve environment (`module -> spack -> source`) and job launch defaults.
