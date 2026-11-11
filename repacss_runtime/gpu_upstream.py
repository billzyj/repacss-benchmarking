#!/usr/bin/env python3
"""Pinned upstream GPU recipes; importing this module never accesses a GPU.

Installation is a plan unless --execute is supplied. Execution requires an
existing, single-task Slurm GPU step. No clock, power, or monitoring controls.
Only the Python standard library is required by this wrapper and its parsers.
"""

import argparse
import csv
import hashlib
import io
import json
import math
import os
from pathlib import Path
import re
import shlex
import shutil
import socket
import statistics
import subprocess
import sys
import time
from datetime import datetime, timezone


NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?"
TELEMETRY_HEADER = ["timestamp_utc", "phase", "metric", "value", "unit", "details"]
DECISIONS_HEADER = ["timestamp_utc", "component", "decision", "reason"]


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def positive(value):
    result = int(value)
    if result <= 0:
        raise ValueError("Expected a positive integer")
    return result


def finite(value, allow_zero=False):
    result = float(str(value).replace(",", ""))
    if not math.isfinite(result) or result < 0 or (result == 0 and not allow_zero):
        raise ValueError(f"Invalid benchmark metric: {value}")
    return result


def paths(recipe, config):
    root = Path(os.environ.get("GPU_BENCH_BUILD_ROOT", recipe.parents[1] / "build" / "gpu-benchmarks"))
    arch = os.environ.get("GPU_ARCH", "sm_90")
    if not re.fullmatch(r"sm_[0-9]+", arch):
        raise ValueError("GPU_ARCH must be a CUDA architecture such as sm_90")
    build = root.expanduser().resolve() / config["id"] / config["commit"][:12] / arch
    return build, build / "source", build / "compiled", arch


def build_commands(recipe, config):
    root, source, compiled, arch = paths(recipe, config)
    jobs = str(positive(os.environ.get("BUILD_JOBS", "4")))
    cuda_home = os.environ.get("CUDA_HOME", "/usr/local/cuda")
    nvcc = os.environ.get("NVCC", str(Path(cuda_home) / "bin" / "nvcc"))
    if not Path(nvcc).is_file():
        nvcc = shutil.which("nvcc") or nvcc
    commands = [
        ["git", "init", str(source)],
        ["git", "-C", str(source), "remote", "add", "origin", config["repository"]],
        ["git", "-C", str(source), "fetch", "--depth", "1", "origin", config["commit"]],
        ["git", "-C", str(source), "checkout", "--detach", "FETCH_HEAD"],
    ]
    if config["builder"] == "cmake":
        commands += [["cmake", "-S", str(source), "-B", str(compiled),
                      "-DCMAKE_BUILD_TYPE=Release", "-DMODEL=cuda",
                      f"-DCMAKE_CUDA_COMPILER={nvcc}", f"-DCUDA_ARCH={arch}",
                      *config.get("cmake_flags", [])],
                     ["cmake", "--build", str(compiled), "--parallel", jobs]]
    elif config["builder"] == "xsbench":
        commands += [["make", "-C", str(source / "cuda"), f"-j{jobs}",
                      f"SM_VERSION={arch[3:]}", f"CC={nvcc}", "OPTIMIZE=yes"]]
    elif config["builder"] == "nccl":
        nccl_home = os.environ.get("NCCL_HOME", "/usr")
        commands += [["make", "-C", str(source), f"-j{jobs}", "MPI=0",
                      f"CUDA_HOME={cuda_home}", f"NCCL_HOME={nccl_home}",
                      f"NVCC={nvcc}", f"BUILDDIR={compiled}",
                      f"NVCC_GENCODE=-gencode=arch=compute_{arch[3:]},code={arch}"]]
    else:
        raise ValueError("Unknown builder")
    return root, commands


def install(recipe, config, execute):
    root, commands = build_commands(recipe, config)
    if not execute:
        print("Installation plan only. Use install.sh source --execute to download and build.")
        print(f"Build directory: {root}")
        for command in commands:
            print(shlex.join(command))
        return 0
    # A new directory prevents mixing architectures, partial builds, or local edits.
    root.mkdir(parents=True, exist_ok=False)
    with (root / "install.log").open("w") as log:
        for command in commands:
            log.write("$ " + shlex.join(command) + "\n")
            log.flush()
            subprocess.run(command, check=True, stdout=log, stderr=subprocess.STDOUT)
    actual = subprocess.check_output(["git", "-C", str(root / "source"), "rev-parse", "HEAD"], text=True).strip()
    if actual != config["commit"]:
        raise ValueError("Fetched source does not match the pinned commit")
    binary = root / config["binary"]
    if not binary.is_file() or not os.access(binary, os.X_OK):
        raise ValueError(f"Build did not produce executable {binary}")
    manifest = {"schema_version": "v1", "benchmark_id": config["id"],
                "repository": config["repository"], "git_commit": actual,
                "built_at_utc": utc_now(), "binary": str(binary),
                "binary_sha256": sha256(binary), "commands": commands,
                "recipe": config, "backend": "cuda", "architecture": paths(recipe, config)[3],
                "environment": selected_environment()}
    write_json(root / "build.json", manifest)
    print(f"Built {binary}; runtime validation is still pending.")
    return 0


def selected_environment():
    names = {"CUDA_VISIBLE_DEVICES", "CUDA_HOME", "NCCL_HOME", "GPU_ARCH", "NVCC",
             "CC", "CXX", "PATH", "LD_LIBRARY_PATH", "OMP_NUM_THREADS",
             "SLURM_JOB_ID", "SLURM_STEP_ID", "SLURM_STEP_NUM_TASKS",
             "SLURM_JOB_NUM_NODES", "SLURM_NODELIST", "SLURM_JOB_GPUS", "SLURM_STEP_GPUS"}
    names.update(name for name in os.environ if name.startswith("NCCL_"))
    return {name: os.environ[name] for name in sorted(names) if name in os.environ}


def run_plan(recipe, config, profile_name, gpu_count=None):
    if profile_name not in config["profiles"]:
        raise ValueError(f"Unknown profile {profile_name}; choose {', '.join(config['profiles'])}")
    profile = config["profiles"][profile_name]
    root, source, _, _ = paths(recipe, config)
    count = positive(gpu_count or profile.get("gpu_count", 1))
    if config["id"] == "nccl_tests":
        if count not in (2, 4):
            raise ValueError("This single-node NCCL recipe requires 2 or 4 GPUs")
    elif count != 1:
        raise ValueError("This recipe runs on one GPU")
    argv = [str(root / config["binary"])]
    argv.extend(arg.replace("{source}", str(source)).replace("{gpus}", str(count))
                for arg in profile["argv"])
    return {"argv": argv, "profile_name": profile_name, "profile": profile,
            "gpu_count": count, "build_root": str(root)}


def require_allocation(count):
    if not os.environ.get("SLURM_JOB_ID") or not os.environ.get("SLURM_STEP_ID"):
        raise ValueError("Run inside an existing Slurm GPU job step; this recipe does not allocate GPUs")
    if os.environ["SLURM_STEP_ID"] in ("batch", "extern"):
        raise ValueError("Use an explicit srun GPU job step inside the allocation")
    # Every recipe launches one process; NCCL uses -g for local GPU ranks.
    if positive(os.environ.get("SLURM_STEP_NUM_TASKS", os.environ.get("SLURM_NTASKS", "1"))) != 1:
        raise ValueError("Use one Slurm task, including for NCCL multi-GPU runs")
    if positive(os.environ.get("SLURM_JOB_NUM_NODES", "1")) != 1:
        raise ValueError("These recipes support single-node runs only")
    visible = [v.strip() for v in os.environ.get("CUDA_VISIBLE_DEVICES", "").split(",") if v.strip()]
    if not visible or len(visible) != count or len(set(visible)) != count:
        raise ValueError(f"The GPU step must expose exactly {count} device(s) through CUDA_VISIBLE_DEVICES")
    if any(v == "-1" or v.startswith("MIG-") for v in visible):
        raise ValueError("Use allocated full GPUs; disabled visibility and MIG are not supported")
    if any(os.environ.get(k) for k in ("NCCL_TESTS_SPLIT", "NCCL_TESTS_SPLIT_MASK")):
        raise ValueError("Unset NCCL_TESTS_SPLIT variables; these profiles measure the full allocated group")


def safe_component(value):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", value):
        raise ValueError(f"Invalid run path component: {value!r}")
    return value


def run_benchmark(recipe, config, args):
    plan = run_plan(recipe, config, args.profile, args.gpus)
    if args.print_command:
        print(shlex.join(plan["argv"]))
        return 0
    require_allocation(plan["gpu_count"])
    repetitions = positive(args.repetitions)
    timeout = finite(args.timeout_seconds)
    root = Path(plan["build_root"])
    build = json.loads((root / "build.json").read_text())
    binary = Path(plan["argv"][0])
    if build["git_commit"] != config["commit"] or build["binary_sha256"] != sha256(binary):
        raise ValueError("Build provenance mismatch; rebuild in a fresh GPU_BENCH_BUILD_ROOT")
    # Deck hashes are recorded on every run so post-build input edits are visible.
    input_hashes = {}
    for relative in plan["profile"].get("input_files", []):
        path = root / "source" / relative
        input_hashes[relative] = sha256(path)
    default_runs = Path(os.environ["DATASET_ROOT"]) / "runs" if os.environ.get("DATASET_ROOT") else Path(__file__).resolve().parents[1] / "Output/runs"
    run_root = Path(os.environ.get("RUN_ROOT", str(default_runs))).expanduser()
    experiment = safe_component(os.environ.get("EXPERIMENT_ID", "manual"))
    site = safe_component(os.environ.get("SITE_PROFILE", "repacss_h100"))
    run_id = safe_component(os.environ.get("RUN_ID", f"job-{os.environ['SLURM_JOB_ID']}-step-{os.environ['SLURM_STEP_ID']}-{time.time_ns()}"))
    run_dir = (run_root / experiment / site / config["id"] / run_id).resolve()
    run_dir.mkdir(parents=True, exist_ok=False)
    raw, normalized = run_dir / "raw", run_dir / "normalized"
    raw.mkdir()
    normalized.mkdir()
    started = utc_now()
    meta = {"schema_version": "v1", "benchmark_id": config["id"], "benchmark_name": config["name"],
            "dataset_id": args.profile, "experiment_id": experiment, "site_profile": site,
            "run_id": run_id, "run_dir": str(run_dir), "job_id": os.environ["SLURM_JOB_ID"],
            "node_list": os.environ.get("SLURM_NODELIST", ""), "hostname": socket.gethostname(),
            "start_time_utc": started, "end_time_utc": "", "status": "running",
            "run_mode": "launcher", "install_method": "user_source", "git_commit": config["commit"]}
    write_json(normalized / "meta.json", meta)
    manifest = {**plan, "repetitions": repetitions, "timeout_seconds": timeout,
                "input_sha256": input_hashes, "environment": selected_environment(),
                "recipe": config, "wrapper_sha256": sha256(Path(__file__)),
                "timing_scope": "whole-process wall time is separate from upstream timed regions"}
    write_json(raw / "manifest.json", manifest)
    shutil.copyfile(root / "build.json", raw / "build.json")
    with (normalized / "telemetry.csv").open("w", newline="") as stream:
        csv.writer(stream).writerow(TELEMETRY_HEADER)
    with (normalized / "decisions.csv").open("w", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(DECISIONS_HEADER)
        writer.writerow([started, config["id"], json.dumps(plan), "fixed profile; external controller owns DVFS"])
    success = False
    try:
        for rep in range(1, repetitions + 1):
            rep_start, tick = utc_now(), time.perf_counter()
            exit_code, error = -1, None
            try:
                with (raw / f"repetition-{rep}.stdout").open("w") as out, (raw / f"repetition-{rep}.stderr").open("w") as err:
                    result = subprocess.run(plan["argv"], cwd=raw, stdout=out, stderr=err,
                                            timeout=timeout, check=False)
                    exit_code = result.returncode
            except (OSError, subprocess.TimeoutExpired) as exc:
                error = str(exc)
            finally:
                write_json(raw / f"repetition-{rep}.process.json",
                           {"repetition": rep, "start_time_utc": rep_start, "end_time_utc": utc_now(),
                            "process_wall_seconds": time.perf_counter() - tick,
                            "exit_code": exit_code, "error": error})
            # Stop on the first failed repetition; preserve the failure artifacts.
            if exit_code != 0:
                break
        summary = parse_run(config, run_dir)
        success = summary["success"]
    except BaseException as exc:
        write_json(normalized / "summary.json", {"benchmark": config["id"], "status": "failed",
                                                 "success": False, "error": str(exc)})
        raise
    finally:
        meta.update(status="success" if success else "failed", end_time_utc=utc_now())
        write_json(normalized / "meta.json", meta)
        print(f"Artifacts: {run_dir}")
    return 0 if success else 1


def parse_output(bench_id, stdout, stderr):
    """Parse only the pinned versions' output; incomplete results fail closed."""
    combined = stdout + "\n" + stderr
    if re.search(r"FAILED validation|Verification failed|INAVALID CHECKSUM|INVALID CHECKSUM", combined, re.I):
        raise ValueError("Upstream correctness check failed")
    if bench_id == "babelstream":
        lines = stdout.splitlines()
        header = next((i for i, line in enumerate(lines) if line.startswith("function,num_times,")), None)
        if header is None:
            raise ValueError("Missing BabelStream CSV header")
        rows = []
        for item in csv.DictReader(io.StringIO("\n".join(lines[header:]))):
            rows.append({"kernel": item["function"], "num_times": positive(item["num_times"]),
                         "elements": positive(item["n_elements"]), "element_bytes": positive(item["sizeof"]),
                         "max_bandwidth_MB_per_s": finite(item["max_MB_per_sec"]),
                         "min_runtime_seconds": finite(item["min_runtime"]),
                         "max_runtime_seconds": finite(item["max_runtime"]),
                         "avg_runtime_seconds": finite(item["avg_runtime"])})
        if len(rows) != 5 or {r["kernel"] for r in rows} != {"Copy", "Mul", "Add", "Triad", "Dot"}:
            raise ValueError("Expected all five classic BabelStream kernels")
        return {"correctness": "passed_upstream_validation", "kernels": rows,
                "timing_scope": "per-kernel host timing; first iteration excluded; bandwidth uses minimum time"}
    if bench_id == "minibude":
        outcomes = re.findall(r"outcome:\s*\{\s*valid:\s*(true|false)", stdout)
        if outcomes != ["true"]:
            raise ValueError("Expected exactly one valid miniBUDE configuration")
        metrics = {}
        for label in ("sum_ms", "avg_ms", "min_ms", "max_ms", "gflop/s"):
            match = re.search(r"^\s*" + re.escape(label) + r":\s*(" + NUMBER + r")\s*$", stdout, re.M)
            if not match:
                raise ValueError(f"Missing miniBUDE metric {label}")
            metrics[label] = finite(match.group(1))
        params = re.search(r"^\s*param:\s*\{\s*ppwi:\s*(\d+),\s*wgsize:\s*(\d+)\s*\}", stdout, re.M)
        config = re.search(r"^config:\s*\n(.*?)(?=^\S|\Z)", stdout, re.M | re.S)
        iterations = re.search(r"iterations:\s*(\d+)", config.group(1)) if config else None
        poses = re.search(r"poses:\s*(\d+)", config.group(1)) if config else None
        if not all((params, iterations, poses)):
            raise ValueError("Missing miniBUDE workload parameters")
        parameters = {"ppwi": int(params.group(1)), "work_group_size": int(params.group(2)),
                      "iterations": int(iterations.group(1)), "poses": int(poses.group(1))}
        return {"correctness": "passed_upstream_reference_energies", "metrics": metrics, "parameters": parameters,
                "timing_scope": "upstream kernel measurements; two warmup iterations excluded"}
    if bench_id == "xsbench":
        check = re.search(r"Verification checksum:\s*(\d+)\s*\(Valid\)", stdout)
        runtime = re.search(r"^Runtime:\s*(" + NUMBER + r") seconds", stdout, re.M)
        rate = re.search(r"^Lookups/s:\s*([\d,]+)", stdout, re.M)
        lookups = re.search(r"^Lookups:\s*([\d,]+)", stdout, re.M)
        if not all((check, runtime, rate, lookups)):
            raise ValueError("Missing valid XSBench checksum or result fields")
        return {"correctness": "passed_upstream_checksum", "checksum": int(check.group(1)),
                "runtime_seconds_upstream": finite(runtime.group(1)),
                "lookups_per_second": finite(rate.group(1)), "lookups": int(lookups.group(1).replace(",", "")),
                "timing_scope": "upstream estimated simulation time; initialization excluded; not a CUDA-event kernel timer"}
    if bench_id == "nccl_tests":
        footer = re.search(r"#\s*Out of bounds values\s*:\s*(\d+)\s+OK\s*$", stdout, re.M)
        if not footer or int(footer.group(1)) != 0:
            raise ValueError("Missing successful NCCL correctness footer")
        rows = []
        for line in stdout.splitlines():
            fields = line.split()
            if not fields or not fields[0].isdigit():
                continue
            if len(fields) != 13:
                raise ValueError("Unexpected NCCL row format (expected timestamp/per-iteration modes disabled)")
            if fields[2:5] != ["float", "sum", "-1"]:
                raise ValueError("Unexpected NCCL datatype/op/root")
            entry = {"size_bytes": positive(fields[0]), "count": positive(fields[1])}
            for name, start in (("out_of_place", 5), ("in_place", 9)):
                if int(fields[start + 3]) != 0:
                    raise ValueError("NCCL reported wrong elements")
                entry[name] = {"time_us": finite(fields[start]), "algbw_GB_per_s": finite(fields[start + 1], True),
                               "busbw_GB_per_s": finite(fields[start + 2], True), "wrong": 0}
            rows.append(entry)
        if not rows:
            raise ValueError("No NCCL measurement rows")
        return {"correctness": "passed_upstream_collective_checks", "messages": rows,
                "timing_scope": "per-operation GPU latency; in-place and out-of-place results retained separately"}
    raise ValueError(f"Unknown parser {bench_id}")


def validate_profile(bench_id, metrics, profile):
    """Reject a complete-looking log produced with a different workload."""
    if bench_id == "babelstream":
        for kernel in metrics["kernels"]:
            if (kernel["elements"], kernel["element_bytes"], kernel["num_times"]) != (
                    profile["elements_per_array"], profile["element_bytes"], profile["iterations"]):
                raise ValueError("BabelStream dimensions do not match the recorded profile")
    elif bench_id == "minibude":
        if any(value != profile[key] for key, value in metrics["parameters"].items()):
            raise ValueError("miniBUDE parameters do not match the recorded profile")
    elif bench_id == "xsbench":
        if (metrics["checksum"], metrics["lookups"]) != (profile["expected_checksum"], profile["lookups"]):
            raise ValueError("XSBench checksum/work count does not match the recorded profile")
    elif bench_id == "nccl_tests":
        expected = []
        size = profile["min_bytes"]
        while size <= profile["max_bytes"]:
            expected.append(size)
            size *= profile["step_factor"]
        if [row["size_bytes"] for row in metrics["messages"]] != expected:
            raise ValueError("NCCL message sweep incomplete or different from the recorded profile")
        if any(row["count"] * 4 != row["size_bytes"] for row in metrics["messages"]):
            raise ValueError("NCCL float element count does not match the message size")


def parse_run(config, run_dir):
    run_dir = Path(run_dir).resolve()
    raw, normalized = run_dir / "raw", run_dir / "normalized"
    manifest = json.loads((raw / "manifest.json").read_text())
    if manifest["recipe"]["id"] != config["id"] or manifest["recipe"]["commit"] != config["commit"]:
        raise ValueError("Run belongs to a different benchmark or source version")
    rows, failures, observations = [], [], []
    for rep in range(1, positive(manifest["repetitions"]) + 1):
        try:
            process = json.loads((raw / f"repetition-{rep}.process.json").read_text())
            if process["exit_code"] != 0 or process.get("error"):
                raise ValueError(f"Process failed: {process}")
            metrics = parse_output(config["id"], (raw / f"repetition-{rep}.stdout").read_text(),
                                   (raw / f"repetition-{rep}.stderr").read_text())
            validate_profile(config["id"], metrics, manifest["profile"])
            row = {**process, **metrics}
            rows.append(row)
            stamp = process["end_time_utc"]
            detail = f"repetition={rep}"
            observations.append([stamp, "whole_process", "process_wall_seconds",
                                 finite(process["process_wall_seconds"]), "s", detail])
            if config["id"] == "babelstream":
                for kernel in metrics["kernels"]:
                    observations.append([stamp, kernel["kernel"], "max_bandwidth", kernel["max_bandwidth_MB_per_s"], "MB/s", detail])
                    observations.append([stamp, kernel["kernel"], "avg_runtime", kernel["avg_runtime_seconds"], "s", detail])
            elif config["id"] == "minibude":
                observations.append([stamp, "kernel", "avg_runtime", metrics["metrics"]["avg_ms"], "ms", detail])
                observations.append([stamp, "kernel", "throughput", metrics["metrics"]["gflop/s"], "GFLOP/s", detail])
            elif config["id"] == "xsbench":
                observations.append([stamp, "simulation", "throughput", metrics["lookups_per_second"], "lookups/s", detail])
                observations.append([stamp, "simulation", "estimated_runtime", metrics["runtime_seconds_upstream"], "s", detail])
            else:
                for message in metrics["messages"]:
                    for mode in ("out_of_place", "in_place"):
                        details = f"{detail};size_bytes={message['size_bytes']};mode={mode}"
                        for key, unit in (("time_us", "us"), ("algbw_GB_per_s", "GB/s"), ("busbw_GB_per_s", "GB/s")):
                            observations.append([stamp, "all_reduce", key, message[mode][key], unit, details])
        except (OSError, ValueError, KeyError, TypeError) as exc:
            failures.append({"repetition": rep, "error": str(exc)})
    success = not failures and len(rows) == manifest["repetitions"]
    summary = {"benchmark": config["id"], "status": "success" if success else "failed", "success": success,
               "profile": manifest["profile_name"], "gpu_count": manifest["gpu_count"],
               "requested_repetitions": manifest["repetitions"], "parsed_repetitions": len(rows),
               "process_wall_seconds_median": statistics.median(r["process_wall_seconds"] for r in rows) if success else None,
               "repetitions": rows, "failures": failures, "source_commit": config["commit"],
               "parser_sha256": sha256(Path(__file__)), "raw_directory": str(raw),
               "energy": "external measurement required; no energy inferred from benchmark throughput"}
    normalized.mkdir(exist_ok=True)
    write_json(normalized / "summary.json", summary)
    with (normalized / "telemetry.csv").open("w", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(TELEMETRY_HEADER)
        writer.writerows(observations)
    return summary


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--recipe", required=True, type=Path)
    commands = parser.add_subparsers(dest="action", required=True)
    setup = commands.add_parser("install")
    setup.add_argument("--execute", action="store_true")
    run = commands.add_parser("run")
    run.add_argument("--profile", default="smoke")
    run.add_argument("--gpus", type=positive)
    run.add_argument("--repetitions", type=positive, default=1)
    run.add_argument("--timeout-seconds", type=finite, default=1800)
    run.add_argument("--print-command", action="store_true")
    parse = commands.add_parser("parse")
    parse.add_argument("run_dir", type=Path)
    args = parser.parse_args(argv)
    recipe = args.recipe.resolve()
    config = json.loads((recipe / "upstream.json").read_text())
    if args.action == "install":
        return install(recipe, config, args.execute)
    if args.action == "run":
        return run_benchmark(recipe, config, args)
    return 0 if parse_run(config, args.run_dir)["success"] else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.SubprocessError, KeyError) as error:
        print(f"GPU recipe error: {error}", file=sys.stderr)
        sys.exit(2)
