# Repository Tools

## `check_repo_layout.sh`

Validates the install/run-oriented REPACSS repository layout:

- obsolete root names are absent
- project-level `AGENTS.md` and `CLAUDE.md` are absent so global assistant rules apply
- `benchmark_index/benchmarks.yaml` keeps benchmark classification sections
- `repacss_cluster/hardware.yaml` is present and recipe partitions exist in it
- `repacss_cluster/modules.yaml` is present and recipe module references point to it
- recipe `installation` metadata declares a valid default method, supported methods, and matching `install.sh` default alias
- each recipe has `recipe.yaml`, `install.sh`, `run.sh`, and `parse.sh`
- the obsolete `adapters/` layer is absent
- operator docs and runtime helpers are present

Run:

```bash
bash repo_tools/check_repo_layout.sh
```
