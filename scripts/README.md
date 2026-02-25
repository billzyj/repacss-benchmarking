# Repository Scripts

- `check_repo_layout.sh`
  Validate benchmark adapter layout, catalog script paths, benchmark-to-catalog id registration,
  and cross-file consistency between `catalog/benchmarks.yaml` and `benchmarks/*/benchmark.yaml`.

Usage:

```bash
bash scripts/check_repo_layout.sh
```

CI:
- `.github/workflows/repo-layout-check.yml` runs this check on push and pull requests.
