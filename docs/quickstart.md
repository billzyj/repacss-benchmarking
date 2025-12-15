# Quick Start Guide

This guide will help you get started with the Power-aware HPC Benchmarking project, focusing on
running benchmarks and organizing their outputs. Power monitoring itself is handled in a separate
project, [`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling).

## Prerequisites

- Python 3.8 or higher
- Linux operating system
- Root access (for power monitoring)
- Intel CPU with RAPL support or AMD CPU with K10Temp support
- NVIDIA GPU (optional, for GPU power monitoring)
- Dell server with iDRAC (optional, for system power monitoring)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Power-aware-HPC-benchmarking.git
   cd Power-aware-HPC-benchmarking
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. Install dependencies (all requirements files are in the `requirements/` folder):

   - **For users:**
     ```bash
     pip install -r requirements/base.txt
     ```
   - **For developers:**
     ```bash
     pip install -r requirements/base.txt
     pip install -r requirements/dev.txt
     ```
   - **For testers:**
     ```bash
     pip install -r requirements/base.txt
     pip install -r requirements/test.txt
     ```

   > **Tip:** If you want a full development and testing environment, install all three in sequence.

   The requirements files are structured as follows:
   - `requirements/base.txt` - Core dependencies for running the project
   - `requirements/dev.txt` - Additional tools for development (requires base)
   - `requirements/test.txt` - Dependencies for running tests (requires base)

## Basic Usage

### 1. Run an OSU benchmark

```bash
python scripts/run_benchmark.py --benchmark osu --test latency --duration 60
```

### 2. Run HPL

```bash
python scripts/run_benchmark.py --benchmark hpl --size 4000 --duration 300 --partition zen4
```

## Interactive Examples

For more detailed examples, check out the Jupyter notebooks in the `docs/examples` directory:

1. Basic monitoring: `docs/examples/basic_power_monitoring.ipynb`
2. Advanced usage: `docs/examples/advanced_power_monitoring.ipynb`

To run the notebooks:
```bash
jupyter notebook docs/examples/
```

## Next Steps

- Use [`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling) to collect and analyze power data for your runs
- Check the [Analysis Guide](analysis.md) for information about analyzing benchmark data (and external power data)
- See [Troubleshooting](troubleshooting.md) if you encounter any issues
- Explore the example notebooks for more advanced usage scenarios

## Getting Help

- Check the [FAQ](faq.md) for common questions
- Visit the [Troubleshooting Guide](troubleshooting.md) for solutions to common issues
- Contact the [support team](contact.md) for additional assistance 