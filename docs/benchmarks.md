# HPC Benchmarks Documentation

## Overview

This project provides standard HPC benchmarks and organizes their outputs for later analysis.
The benchmarks included in this project are:

1. OSU Micro-benchmarks - For measuring communication performance
2. HPL (High Performance Linpack) - For measuring system performance

## Getting the benchmarks

Benchmark **binaries are not vendored** in this repository. On REPACSS they are typically provided by:

- **Environment modules** (preferred):
  ```bash
  module load osu-micro-benchmarks
  module load hpl
  ```

- **Spack**:
  ```bash
  spack install osu-micro-benchmarks
  spack install hpl
  spack load osu-micro-benchmarks
  spack load hpl
  ```

This project provides per-benchmark configuration files next to each benchmark
(`benchmarks/osu/config.json`, `benchmarks/hpl/config.json`) and template batch scripts
(`benchmarks/templates/*.sh`) that assume these modules/Spack packages are available on REPACSS.

## OSU Micro-benchmarks

### Overview

The OSU Micro-benchmarks suite is a collection of benchmarks designed to measure the performance of various operations in parallel computing environments. It includes tests for:

- Point-to-point communication (latency, bandwidth)
- Collective communication (allreduce, broadcast, etc.)
- One-sided communication
- I/O operations

### Installation

On REPACSS, OSU is normally provided via a module or Spack as shown above. If you need a custom
build for research, build a separate local copy outside this repository and adjust your batch
scripts accordingly.

### Available Tests

The OSU Micro-benchmarks suite includes numerous tests. Here are some of the most commonly used:

1. **Latency Test** (`osu_latency`): Measures the latency of point-to-point communication
2. **Bandwidth Test** (`osu_bandwidth`): Measures the bandwidth of point-to-point communication
3. **Allreduce Test** (`osu_allreduce`): Measures the performance of the MPI_Allreduce operation
4. **Broadcast Test** (`osu_broadcast`): Measures the performance of the MPI_Broadcast operation
5. **Alltoall Test** (`osu_alltoall`): Measures the performance of the MPI_Alltoall operation

### Running OSU Benchmarks

Once the OSU binaries are on your `PATH` (via module or Spack), you can run them directly in your
job scripts, for example:

```bash
mpirun -np 2 osu_latency
mpirun -np 2 osu_bw
```

Use this repository’s configs and batch scripts as examples for how to structure runs for data
collection, but rely on the cluster-provided OSU installation.

### Understanding OSU Results

OSU benchmark results typically include:

- Message size (in bytes)
- Latency (in microseconds)
- Bandwidth (in MB/s)

Example output:
```
# OSU MPI Latency Test v5.6.2
# Size          Latency (us)
4               1.23
8               1.24
16              1.25
32              1.26
64              1.28
128             1.31
256             1.35
512             1.42
1024            1.57
2048            1.87
4096            2.28
8192            2.91
16384           4.18
32768           6.72
65536           11.82
131072          21.82
262144          41.82
524288          81.82
1048576         161.82
```

### Analysis for OSU

You can combine OSU performance data from this repository with external power data (for example,
from [`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling)) to perform
power-performance studies such as communication efficiency and scaling behavior.

## HPL (High Performance Linpack)

### Overview

HPL (High Performance Linpack) is a benchmark used to evaluate the performance of high-performance computing systems. It solves a dense linear system of equations using Gaussian elimination with partial pivoting. HPL is the benchmark used to rank systems on the TOP500 list of supercomputers.

### Installation

On REPACSS, HPL is normally provided via a module or Spack as shown above. If you need a custom
HPL build, do so outside this repository and point your job scripts to that build.

### Configuration

HPL requires a configuration file (`HPL.dat`) that specifies:

1. Problem size (N)
2. Block size (NB)
3. Process grid (P x Q)
4. Algorithm parameters

Example `HPL.dat`:
```
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
1000         Ns
1            # of NBs
128          NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
2            Ps
2            Qs
16.0         threshold
1            # of panel fact
2            PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
4            NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
1            RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
1            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1            # of lookahead depth
1            DEPTHs (>=0)
2            SWAP (0=bin-exch,1=long,2=mix)
64           swapping threshold
0            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form
1            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)
```

### Running HPL

After loading HPL via module or Spack, typical runs look like:

```bash
mpirun -np <P*Q> xhpl
```

Use your site’s recommended `HPL.dat` templates for Zen4 / H100 or adapt examples provided by
the REPACSS admins.

### Understanding HPL Results

HPL output includes:

- Problem size (N)
- Block size (NB)
- Process grid (P x Q)
- Performance (Gflops)
- Time to solution

Example output:
```
================================================================================
HPLinpack 2.3  --  High-Performance Linpack benchmark  --   December 2, 2018
Written by A. Petitet and R. Clint Whaley,  Innovative Computing Laboratory, UTK
Modified by Piotr Luszczek, Innovative Computing Laboratory, UTK
Modified by Julien Langou, University of Colorado Denver
================================================================================
An explanation of the input/output parameters follows:
T/V    : Wall time / encoded variant.
N      : The order of the coefficient matrix A.
NB     : The size of the computational blocks.
P      : The number of process rows in the process grid.
Q      : The number of process columns in the process grid.
Time   : Time in seconds to solve the linear system.
Gflops : Rate of execution for solving the linear system.
The following parameter values will be used:
N      :   1000
NB     :     128
P      :       2
Q      :       2
PFACT  :   Crout
NBMIN  :       4
NDIV   :       2
RFACT  :   Crout
BCAST  :   1ringM
DEPTH  :       1
SWAP   : Mix (threshold = 64)
L1     : transposed form
U      : transposed form
Equil  : yes
ALIGN  : 8 double precision words
--------------------------------------------------------------------------------
- The matrix A is randomly generated for each test.
- The following scaled residual check will be computed:
   ||Ax-b||_oo / ( eps * ||A||_1  * N        ) / ||b||_oo )
- The relative machine precision (eps) is taken to be
   1.110223e-16
- I am going to time the factorization and solve separately
================================================================================
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WC00C2R2       1000   128     2     2               0.34              1.958e+00
HPL_pdgesv() start time Sun Mar 21 12:34:56 2021
HPL_pdgesv() end time   Sun Mar 21 12:34:56 2021
--------------------------------------------------------------------------------
||Ax-b||_oo/(eps*(||A||_oo*||x||_oo+||b||_oo)*N)=   0.0022932 ...... PASSED
================================================================================
Finished      1 tests with the following results:
              1 tests completed and passed residual checks,
              0 tests completed and failed residual checks,
              0 tests skipped because of illegal input values.
--------------------------------------------------------------------------------
End of Tests.
================================================================================
```

### Analysis for HPL

You can combine HPL performance data from this repository with external power data (for example,
from [`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling)) to analyze
Gflops per watt, scaling behavior, and phase-wise efficiency.

## Benchmark Integration

You can run multiple benchmarks in sequence using `scripts/run_benchmark.py` or your own orchestration
scripts, and then combine the resulting performance data with external power measurements
(`Repacss-power-profiling`) for full power-performance analysis.

## Best Practices

1. **Benchmark Selection**
   - Choose benchmarks that represent your workload
   - Consider both micro-benchmarks and application benchmarks
   - Include both communication and computation tests

2. **Parameter Selection**
   - Use appropriate problem sizes for your system
   - Consider scaling studies with different problem sizes
   - Test different process configurations

3. **Data Collection**
   - Collect both performance and power data
   - Use consistent sampling intervals
   - Include system information in your data

4. **Analysis**
   - Calculate power-performance metrics (e.g., Gflops/Watt)
   - Compare different configurations
   - Consider both peak and average power consumption

## Troubleshooting

### Common Issues

1. **MPI Configuration**
   - Ensure MPI is properly installed and configured
   - Check that the correct MPI implementation is being used
   - Verify that the number of processes is appropriate

2. **Benchmark Compilation**
   - Check for compilation errors
   - Ensure all dependencies are installed
   - Verify that the correct compiler is being used

3. **Performance Issues**
   - Check for system load from other processes
   - Verify that the system is not thermally throttling
   - Ensure that the network is not congested

### Debugging Tips

1. **Verbose Output**
   - Enable verbose output in MPI
   - Use debug flags when compiling benchmarks
   - Check system logs for errors

2. **Small Test Cases**
   - Start with small problem sizes
   - Use a small number of processes
   - Verify that basic functionality works

3. **System Checks**
   - Check CPU frequency and temperature
   - Verify memory availability
   - Check network connectivity

## Contributing

When adding new benchmarks:

1. Follow the existing benchmark structure
2. Include installation instructions
3. Provide example commands for running the benchmark
4. Document the expected output format
5. Update the analysis scripts to handle the new benchmark

## License

This project is licensed under the MIT License - see the LICENSE file for details. 