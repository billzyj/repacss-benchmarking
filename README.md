# Power-aware HPC Benchmarking

This project provides standard HPC benchmarks and experiment data for power-aware analysis. It focuses on running and organizing benchmarks and their results; power monitoring and detailed power analysis are handled in a separate repository, [`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling).

## Table of Contents
- [Prerequisites](#prerequisites)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Power Monitoring Details](#power-monitoring-details)
- [Contributing](#contributing)
- [License](#license)
- [Documentation](#documentation)
- [Contact](#contact)

## Prerequisites

### Hardware Requirements
- CPU: Intel CPU with RAPL support or AMD CPU with K10Temp support
- GPU (optional): NVIDIA GPU with NVML support or AMD GPU with appropriate drivers
- System (optional): IPMI-capable system or Dell server with iDRAC

### Software Requirements
- Linux operating system
- Python 3.8 or higher
- Root access (for power monitoring)
- MPI implementation (OpenMPI, MPICH, or MVAPICH2)
- CUDA toolkit (for GPU monitoring)

### Version Compatibility
| Component | Minimum Version | Recommended Version |
|-----------|----------------|-------------------|
| Python | 3.8 | 3.10 |
| CUDA | 11.0 | 11.7 |
| OpenMPI | 4.0 | 4.1 |
| IPMI | 2.0 | 2.0 |

## Features

- HPC benchmark runners for OSU micro-benchmarks and HPL
- Structured storage of raw and processed benchmark results
- Simple scripts for orchestrating benchmark runs (`scripts/run_benchmark.py`)
- Companion power-profiling and TimescaleDB-based analysis available via [`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling)

## Requirements

### Core Requirements
- Python 3.8+
- numpy>=1.19.0
- pandas>=1.2.0
- matplotlib>=3.3.0
- seaborn>=0.11.0
- jupyter>=1.0.0

### Monitoring Requirements

Live power monitoring and TimescaleDB-based analysis are no longer implemented in this repository.
If you need CPU/GPU/system power monitoring or rack-level analysis on REPACSS, use
[`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling) and follow its
installation instructions.

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

### Verification Steps

After installation, verify your setup:

1. **Check Python Environment**
   ```bash
   python --version  # Should be 3.8 or higher
   pip list  # Verify all required packages are installed
   ```

2. **Verify Hardware Access for Benchmarks**
   Ensure MPI, CUDA (if applicable), and your batch environment are configured correctly (see `docs/benchmarks.md`).

3. **Run Basic Tests**
   ```bash
   # Run the test suite:
   pytest tests/
   
   # Run a simple benchmark:
   python scripts/run_benchmark.py --benchmark osu --test latency --duration 10
   ```

For more detailed troubleshooting information, please refer to the [Troubleshooting Guide](docs/troubleshooting.md).

## Quick Start

### Running Benchmarks

This project focuses on running standard HPC benchmarks and recording their outputs. To run benchmarks:

1. Install the benchmarks following the instructions in [Benchmarks Documentation](docs/benchmarks.md)
2. Use the provided scripts to run benchmarks:

```bash
# Run OSU latency test
python scripts/run_benchmark.py --benchmark osu --test latency --duration 60

# Run HPL on Zen4 partition
python scripts/run_benchmark.py --benchmark hpl --size 4000 --duration 300 --partition zen4

# Run HPL on H100 partition
python scripts/run_benchmark.py --benchmark hpl --size 2000 --duration 300 --partition h100
```

For detailed information on available benchmarks, configuration options, and interpreting results, please refer to the [Benchmarks Documentation](docs/benchmarks.md).

### Interactive Examples

The project includes Jupyter notebooks with comprehensive examples, located in `docs/examples/`:

1. Basic Power Monitoring (`docs/examples/basic_power_monitoring.ipynb`):
   - Setting up power monitors
   - Basic CPU and GPU monitoring
   - Collecting and visualizing power data
   - Basic statistics and analysis

2. Advanced Usage (`docs/examples/advanced_usage.ipynb`):
   - Custom power monitor implementation
   - Integration with HPC workloads
   - Advanced data analysis
   - Power-aware optimization
   - Report generation

3. Power Monitoring Example (`docs/examples/power_monitoring_example.ipynb`):
   - Additional demonstration of power monitoring features

To run the examples:

```bash
jupyter notebook docs/examples/
```

## Project Structure

```
.
├── benchmarks/
│   ├── osu/
│   │   ├── install_osu.sh        # Install OSU via module / Spack / from source
│   │   └── run_osu_repacss.sh    # Run OSU on REPACSS (mpirun wrapper)
│   ├── hpl/
│   │   ├── install_hpl.sh        # Install HPL via module / Spack / from source
│   │   └── run_hpl_repacss.sh    # Run HPL on REPACSS (mpirun wrapper)
│   └── templates/
│       ├── zen4_batch.sh         # Example Slurm template for Zen4 I/O/CPU benchmarks
│       └── h100_batch.sh         # Example Slurm template for H100 GPU benchmarks
├── docs/
│   ├── benchmarks.md
│   ├── analysis.md
│   ├── power_profiling.md        # Points to external power-profiling repo
│   └── ...
├── external/
│   └── Repacss-power-profiling/  # Git submodule with power monitoring/analysis stack
├── requirements/
│   ├── base.txt
│   ├── dev.txt
│   └── test.txt
├── setup.py                      # Package setup (for editable installs)
└── LICENSE
```

## Power Monitoring Details

Power monitoring implementations (CPU/GPU/system, IPMI, iDRAC, rack-level aggregation) have been
moved out of this repository. For power measurement on the REPACSS cluster, including TimescaleDB
queries and Excel report generation, use [`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling).

## Editable/Development Installation

If you want to work on the source code and have changes reflected immediately (without reinstalling), you can use the provided `setup.py` for an editable install:

```bash
pip install -e .
```

> **Note:** This only installs the package itself. You should still install dependencies using the requirements files as described above:
> - `pip install -r requirements/base.txt` (and dev.txt/test.txt as needed)

This approach is recommended for developers contributing to the project.

## Contributing

We welcome contributions to the Power-aware HPC Benchmarking project! Here's how you can help:

### Development Setup

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Install development dependencies:
   ```bash
   pip install -r requirements/base.txt
   pip install -r requirements/dev.txt
   pip install -r requirements/test.txt
   ```
4. Install the package in editable mode:
   ```bash
   pip install -e .
   ```

### Coding Style

- Follow PEP 8 guidelines
- Use type hints for function arguments and return values
- Write docstrings for all public functions and classes
- Keep functions focused and small
- Use meaningful variable names
- Add comments for complex logic

### Testing

- Write unit tests for new features
- Ensure all tests pass before submitting
- Maintain or improve test coverage
- Run the full test suite:
  ```bash
  pytest tests/
  ```

### Pull Request Process

1. Update documentation if needed
2. Add tests for new features
3. Ensure all tests pass
4. Update the changelog
5. Create a pull request with a clear description

### Issue Reporting

When reporting issues, please include:
- Operating system and version
- Python version
- Hardware configuration
- Error messages and stack traces
- Steps to reproduce
- Expected vs actual behavior

### Pull Request Template

```markdown
## Description
[Describe your changes here]

## Related Issue
[Link to related issue]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] All tests passing
- [ ] Manual testing performed

## Documentation
- [ ] README updated
- [ ] API documentation updated
- [ ] Code comments added/updated
```

### Code of Conduct

- Be respectful and inclusive
- Focus on what is best for the community
- Show empathy towards other community members
- Accept constructive criticism gracefully
- Help maintain a positive and productive environment

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

## Documentation

For more detailed documentation, see:

- [Quick Start Guide](docs/quickstart.md)
- Benchmarks Documentation: `docs/benchmarks.md`
- Analysis Guide for benchmark data: `docs/analysis.md`
- [Troubleshooting](docs/troubleshooting.md)

## Contact

For questions and support, please open an issue on the GitHub repository.

## Data Management

### Data Storage

The project uses a structured approach to store benchmark and power monitoring data:

```
results/
├── raw/                      # Raw data from benchmarks and power monitoring
│   ├── power/               # Power monitoring data
│   │   ├── cpu/            # CPU power data
│   │   ├── gpu/            # GPU power data
│   │   └── system/         # System power data
│   └── benchmarks/         # Benchmark results
│       ├── osu/            # OSU benchmark results
│       └── hpl/            # HPL benchmark results
├── processed/               # Processed and analyzed data
│   ├── power/              # Processed power data
│   ├── benchmarks/         # Processed benchmark results
│   └── reports/            # Generated analysis reports
└── metadata/               # Metadata and configuration files
    ├── system_info.json    # System configuration
    └── benchmark_config.json # Benchmark configurations
```

### Data Formats

1. **Power Monitoring Data (JSON)**
```json
{
    "timestamp": "20240321_123456",
    "benchmark": "osu_latency",
    "parameters": {
        "np": 2,
        "duration": 60
    },
    "cpu_power": [
        {"timestamp": "2024-03-21T12:34:56", "power": 45.2},
        {"timestamp": "2024-03-21T12:34:57", "power": 46.1}
    ]
}
```

2. **Benchmark Results (Text)**
```
# OSU MPI Latency Test v5.6.2
# Size          Latency (us)
4               1.23
8               1.24
16              1.25
```

### Data Analysis

The project includes tools for analyzing power-performance data:

```python
from power_profiling.analysis import PowerAnalyzer

# Load and analyze data
analyzer = PowerAnalyzer()
results = analyzer.analyze_benchmark(
    benchmark_data="results/raw/benchmarks/osu/latency.txt",
    power_data="results/raw/power/cpu/power_data.json"
)

# Generate report
analyzer.generate_report(results, "results/processed/reports/analysis.html")
```

## Logging and Debugging

### Logging Configuration

The project uses Python's logging module with the following configuration:

```python
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('power_benchmark.log'),
        logging.StreamHandler()
    ]
)

# Usage in code
logger = logging.getLogger(__name__)
logger.info("Starting benchmark")
logger.debug("Detailed debug information")
logger.error("Error occurred", exc_info=True)
```

### Debugging Tools

1. **Power Monitor Debug Mode**
```python
from power_profiling.monitors import CPUMonitor

# Enable debug mode
monitor = CPUMonitor(debug=True)
monitor.start()
```

2. **Benchmark Debug Mode**
```bash
# Run benchmark with debug output
python scripts/run_benchmark.py --benchmark osu --test latency --debug
```

3. **System Information**
```bash
# Collect system information
python scripts/collect_system_info.py

# View collected information
cat results/metadata/system_info.json
```

### Common Debugging Steps

1. **Power Monitoring Issues**
   - Check hardware access permissions
   - Verify sensor availability
   - Monitor system logs for errors

2. **Benchmark Issues**
   - Check MPI configuration
   - Verify resource availability
   - Review benchmark logs

3. **Performance Issues**
   - Check system load
   - Monitor thermal throttling
   - Verify network connectivity

### Out-of-band iDRAC (REPACSS) Integration

Out-of-band iDRAC access, TimescaleDB queries, and rack-level power validation are now maintained
exclusively in [`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling). Use
that project’s CLI or Python API to query and analyze power data alongside the benchmark results
generated here.