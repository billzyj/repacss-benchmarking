# Job power-report checks

Two small jobs that exercise the REPACSS job power reports: one CPU benchmark and one GPU benchmark, each
between idle gaps so the workload stands out in the report plots.

## How a job asks for a report

The request is the Slurm job comment. Nothing has to be installed by the user.

| Job comment | Report | Source |
|---|---|---|
| `power:oob` | out-of-band (OOB) | the node's management controller (iDRAC): whole node and its components |
| `power:inband` | in-band (IB) | a collector on the node: CPU energy counters (RAPL) and, on GPU nodes, GPU energy counters (NVML) |
| `power:both` | both | both |

In-band collection covers the whole node, so `power:inband` and `power:both` need `--exclusive`. Collection
runs only on nodes where it has been enabled; ask which nodes and reservation to use.

## Jobs

| Script | Partition | Workload | Length |
|---|---|---|---|
| `zen4_lammps.sbatch` | `zen4`, one node | LAMMPS Lennard-Jones liquid (`inputs/in.lj`), 256 MPI ranks, two runs (site module via `env.sh`, no build) | about 6 min |
| `h100_babelstream.sbatch` | `h100`, one node | BabelStream (CUDA) on one of the four GPUs | about 5 min |

Both scripts read two variables: `RECIPE_DIR` (this directory) and `OUT_ROOT` (where the job writes its
records). `zen4_lammps.sbatch` also needs `MODE`, a label for the output directory, and takes its profiling
mode from `--comment` on the command line; `h100_babelstream.sbatch` sets `power:both` itself.

Run from the repository root:

```bash
export RECIPE_DIR=$PWD/benchmark_recipes/profiling-overhead

# CPU
export OUT_ROOT=$PWD/Output/experiments/cpu-both; mkdir -p "$OUT_ROOT"
MODE=both sbatch --comment=power:both --chdir="$OUT_ROOT" --export=ALL \
    --reservation=<reservation> --nodelist=<zen4 node> $RECIPE_DIR/zen4_lammps.sbatch

# GPU: build BabelStream once (about 20 s), then submit
module load cuda/12.9.1
bash benchmark_recipes/babelstream/install.sh source --execute
export OUT_ROOT=$PWD/Output/experiments/gpu-both; mkdir -p "$OUT_ROOT"
sbatch --chdir="$OUT_ROOT" --export=ALL \
    --reservation=<reservation> --nodelist=<h100 node> $RECIPE_DIR/h100_babelstream.sbatch
```

`--chdir="$OUT_ROOT"` matters: the reports are delivered into the job's working directory.

Shortcuts for the same steps: `install.sh source --execute` builds BabelStream, `run.sh cpu|gpu <sbatch options>`
submits a job with `OUT_ROOT=Output/experiments/<cpu|gpu>-both`, and `parse.sh <OUT_ROOT> <job_id>` lists what
was delivered and the in-band summary status.

## Output

Each job writes `$OUT_ROOT/<job_id>-<mode>/`:

- `job_info.txt`: job ID, node, comment, and Unix times of the job and of each workload;
- `runs.csv` (CPU) or `babelstream.log` and `runs/` (GPU): the benchmark's own results;
- `runner_start.csv`, `runner.csv`: the in-band collector unit seen on the node at the start and end of the job.

A few minutes after the job ends, the reports arrive in `$OUT_ROOT/power_reports/<job_id>/`:

- `oob/`: `power_timeseries.pdf`, `energy_ring.pdf`, `raw_power.csv`, `meta.txt`;
- `ib/`: `power_timeseries.pdf`, `raw_power.csv`, `summary.json`, `provenance.json`.

The same files are kept under `/mnt/SHARED-AREA/power_reports/$USER/<job_id>/`. `ib/summary.json` states
whether collection was `complete`, which nodes reported, how much of the job window the samples cover, and
the energy per component.
