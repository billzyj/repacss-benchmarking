# Deferred test plan: BabelStream CUDA memory bandwidth

Status: **partly run**. The build (section 2) and the `smoke` and `hbm-long` profiles have run on H100;
the parser negative cases and the HBM pilot below have not.
Run these steps only after the experiment window becomes available. No H100
compatibility or performance result is claimed from source inspection alone.

## 1. CPU-only checks

Follow the static/parser commands in [the suite guide](../../operator_docs/gpu_benchmark_suite.md).
Read the synthetic tests in `repacss_runtime/test_gpu_upstream.py`; the examples
are authored fixtures, not captured GPU results. Confirm plan-only installation
and `--print-command` do not launch subprocesses or initialize any GPU library.
Check shell syntax, JSON configuration, layout/index membership and path quoting.

## 2. Build and source provenance

Load the intended CUDA build environment on a suitable node, inspect the install
plan, then use `install.sh source --execute`. Require the pinned commit and expected
binary, retain `install.log` and `build.json`, and record compiler/toolkit/library
versions. Do not reuse a failed build directory or silently change the source pin.
A new build root avoids mixing artifacts from compiler/architecture changes.

## 3. Correctness, output contract and failure handling

- Smoke: require five rows (Copy/Mul/Add/Triad/Dot), finite positive timings and
  bandwidth, zero exit status, and no validation errors on either output stream.
- Negative parser cases: missing kernel, missing CSV header, NaN/Inf, changed element
  count or precision, nonzero exit, truncated output, missing repetition.
- Pilot: compare `hbm` and `hbm-large`; document the bandwidth plateau criterion and
  observed kernel durations. Do not claim HBM behavior from `smoke`.
- Hold the element count/iterations/precision fixed within each DVFS comparison;
  evaluate bandwidth and time using the same aggregation rule at all frequencies.

Verify the artifact directory contains raw stdout/stderr, `manifest.json`,
`build.json`, and one process JSON per attempted repetition; normalized metadata,
summary, decisions and telemetry follow the repository contract. Reparse twice and
confirm stable metrics (the parser file hash may change only with code changes).
Test timeout/nonzero-exit/missing-output behavior with a CPU mock, not a GPU fault.
Never publish successful aggregate results when any requested repetition is absent
or failed. An existing RUN_ID must not overwrite earlier results.

## 4. DVFS and future acceptance

Use the default-clock smoke only to establish correctness. Freeze a separate pilot
profile before a frequency sweep. Start with at least five measured repetitions
and paired default-clock controls; report variability and increase repetitions if
needed. Preserve whole-process and upstream timing scopes separately. External
control should record requested/achieved frequency, control API, power limit,
throttle reasons, GPU identities/topology and interval-aligned energy.

Accept for experiments only after a real upstream log is checked against the parser,
correctness passes for all intended profiles, and timing/work-size definitions match
across conditions. Store future evidence under the run directory and record the
run IDs here before changing the recipe's validation status.

Evidence: build — pending; CPU tests — pending; smoke — pending; pilot — pending;
frequency/energy comparison — pending.
