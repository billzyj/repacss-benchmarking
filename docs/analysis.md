# Power-Performance Analysis Documentation

## Overview

This document describes the analysis tools and methodologies used to process and visualize benchmark
results (and, optionally, external power data) collected from HPC runs. The analysis pipeline includes:

1. Data loading and preprocessing
2. Statistical analysis
3. Visualization
4. Report generation

## Data Format

### Power Monitoring Data

If you collect power data (for example, using [`Repacss-power-profiling`](https://github.com/billzyj/Repacss-power-profiling)),
you can adapt the loader functions below to the JSON/CSV format produced by that project.

### Benchmark Results

#### OSU Benchmark Results

OSU benchmark results are stored in text format:

```
# OSU MPI Latency Test v5.6.2
# Size          Latency (us)
4               1.23
8               1.24
16              1.25
...
```

#### HPL Results

HPL results are stored in text format with performance metrics:

```
T/V                N    NB     P     Q               Time                 Gflops
--------------------------------------------------------------------------------
WC00C2R2       1000   128     2     2               0.34              1.958e+00
```

## Analysis Tools

### Data Loading and Preprocessing

```python
import pandas as pd
import json
from pathlib import Path

def load_power_data(file_path):
    """Load power monitoring data from JSON/CSV file.

    This function is a template; adjust column names/structure to match your power data source
    (for example, the outputs of `Repacss-power-profiling`).
    """
    with open(file_path, 'r') as f:
        data = json.load(f)

    # Expect keys like 'cpu_power', 'gpu_power', 'system_power'; adapt as needed.
    cpu_df = pd.DataFrame(data.get('cpu_power', []))
    gpu_df = pd.DataFrame(data.get('gpu_power', []))
    system_df = pd.DataFrame(data.get('system_power', []))

    for df in [cpu_df, gpu_df, system_df]:
        if not df.empty and 'timestamp' in df.columns:
            df['timestamp'] = pd.to_datetime(df['timestamp'])

    return {
        'metadata': {k: v for k, v in data.items() if k not in ['cpu_power', 'gpu_power', 'system_power']},
        'cpu_power': cpu_df,
        'gpu_power': gpu_df,
        'system_power': system_df,
    }

def load_osu_results(file_path):
    """Load OSU benchmark results from text file."""
    df = pd.read_csv(file_path, comment='#', delim_whitespace=True,
                     names=['size', 'latency'])
    return df

def load_hpl_results(file_path):
    """Load HPL benchmark results from text file."""
    # Extract performance data
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # Find the performance data section
    start_idx = 0
    for i, line in enumerate(lines):
        if 'T/V' in line and 'N' in line and 'Gflops' in line:
            start_idx = i + 2
            break
    
    # Parse the data
    data = []
    for line in lines[start_idx:]:
        if line.strip() and not line.startswith('-'):
            parts = line.split()
            if len(parts) >= 7:
                data.append({
                    'variant': parts[0],
                    'n': int(parts[1]),
                    'nb': int(parts[2]),
                    'p': int(parts[3]),
                    'q': int(parts[4]),
                    'time': float(parts[5]),
                    'gflops': float(parts[6])
                })
    
    return pd.DataFrame(data)
```

### Statistical Analysis

```python
import numpy as np
from scipy import stats

def analyze_power_data(power_data):
    """Calculate statistics for power consumption data."""
    stats = {}
    
    for component in ['cpu_power', 'gpu_power', 'system_power']:
        df = power_data[component]
        stats[component] = {
            'mean': df['power'].mean(),
            'std': df['power'].std(),
            'min': df['power'].min(),
            'max': df['power'].max(),
            'median': df['power'].median(),
            'percentile_95': df['power'].quantile(0.95)
        }
    
    return stats

def analyze_osu_performance(osu_data):
    """Calculate statistics for OSU benchmark performance."""
    stats = {
        'min_latency': osu_data['latency'].min(),
        'max_latency': osu_data['latency'].max(),
        'mean_latency': osu_data['latency'].mean(),
        'std_latency': osu_data['latency'].std()
    }
    
    # Calculate bandwidth if available
    if 'bandwidth' in osu_data.columns:
        stats.update({
            'min_bandwidth': osu_data['bandwidth'].min(),
            'max_bandwidth': osu_data['bandwidth'].max(),
            'mean_bandwidth': osu_data['bandwidth'].mean(),
            'std_bandwidth': osu_data['bandwidth'].std()
        })
    
    return stats

def analyze_hpl_performance(hpl_data):
    """Calculate statistics for HPL benchmark performance."""
    stats = {
        'mean_gflops': hpl_data['gflops'].mean(),
        'max_gflops': hpl_data['gflops'].max(),
        'min_gflops': hpl_data['gflops'].min(),
        'std_gflops': hpl_data['gflops'].std(),
        'mean_time': hpl_data['time'].mean(),
        'total_time': hpl_data['time'].sum()
    }
    
    return stats
```

### Visualization

```python
import matplotlib.pyplot as plt
import seaborn as sns

def plot_power_consumption(power_data, output_file=None):
    """Create power consumption plots."""
    plt.figure(figsize=(12, 6))
    
    # Plot power consumption over time
    for component, df in power_data.items():
        if isinstance(df, pd.DataFrame) and 'power' in df.columns:
            plt.plot(df['timestamp'], df['power'], label=component.replace('_power', '').upper())
    
    plt.xlabel('Time')
    plt.ylabel('Power (W)')
    plt.title('Power Consumption Over Time')
    plt.legend()
    plt.grid(True)
    
    if output_file:
        plt.savefig(output_file)
    else:
        plt.show()

def plot_osu_results(osu_data, output_file=None):
    """Create OSU benchmark result plots."""
    plt.figure(figsize=(10, 6))
    
    # Plot latency vs message size
    plt.semilogx(osu_data['size'], osu_data['latency'], 'o-')
    plt.xlabel('Message Size (bytes)')
    plt.ylabel('Latency (μs)')
    plt.title('OSU Latency Test Results')
    plt.grid(True)
    
    if output_file:
        plt.savefig(output_file)
    else:
        plt.show()

def plot_hpl_results(hpl_data, output_file=None):
    """Create HPL benchmark result plots."""
    plt.figure(figsize=(10, 6))
    
    # Plot performance vs problem size
    plt.plot(hpl_data['n'], hpl_data['gflops'], 'o-')
    plt.xlabel('Problem Size (N)')
    plt.ylabel('Performance (Gflops)')
    plt.title('HPL Performance Results')
    plt.grid(True)
    
    if output_file:
        plt.savefig(output_file)
    else:
        plt.show()

def plot_power_performance_correlation(power_data, performance_data, output_file=None):
    """Create power-performance correlation plots."""
    plt.figure(figsize=(10, 6))
    
    # Calculate average power consumption
    avg_power = power_data['system_power']['power'].mean()
    
    # Plot power vs performance
    plt.scatter(performance_data['gflops'], [avg_power] * len(performance_data))
    plt.xlabel('Performance (Gflops)')
    plt.ylabel('Average Power (W)')
    plt.title('Power-Performance Correlation')
    plt.grid(True)
    
    if output_file:
        plt.savefig(output_file)
    else:
        plt.show()
```

### Report Generation

```python
from jinja2 import Template
import os

def generate_report(power_data, benchmark_data, output_file):
    """Generate an HTML report with analysis results."""
    # Calculate statistics
    power_stats = analyze_power_data(power_data)
    if 'osu' in benchmark_data:
        benchmark_stats = analyze_osu_performance(benchmark_data['osu'])
    else:
        benchmark_stats = analyze_hpl_performance(benchmark_data['hpl'])
    
    # Create plots
    plot_files = {}
    plot_power_consumption(power_data, 'power_consumption.png')
    plot_files['power'] = 'power_consumption.png'
    
    if 'osu' in benchmark_data:
        plot_osu_results(benchmark_data['osu'], 'osu_results.png')
        plot_files['benchmark'] = 'osu_results.png'
    else:
        plot_hpl_results(benchmark_data['hpl'], 'hpl_results.png')
        plot_files['benchmark'] = 'hpl_results.png'
    
    plot_power_performance_correlation(power_data, benchmark_data['hpl' if 'hpl' in benchmark_data else 'osu'],
                                     'correlation.png')
    plot_files['correlation'] = 'correlation.png'
    
    # Generate HTML report
    template = Template('''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Power-Performance Analysis Report</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .section { margin-bottom: 30px; }
            .plot { margin: 20px 0; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
        </style>
    </head>
    <body>
        <h1>Power-Performance Analysis Report</h1>
        
        <div class="section">
            <h2>Power Consumption Statistics</h2>
            <table>
                <tr>
                    <th>Component</th>
                    <th>Mean (W)</th>
                    <th>Std (W)</th>
                    <th>Min (W)</th>
                    <th>Max (W)</th>
                </tr>
                {% for component, stats in power_stats.items() %}
                <tr>
                    <td>{{ component }}</td>
                    <td>{{ "%.2f"|format(stats.mean) }}</td>
                    <td>{{ "%.2f"|format(stats.std) }}</td>
                    <td>{{ "%.2f"|format(stats.min) }}</td>
                    <td>{{ "%.2f"|format(stats.max) }}</td>
                </tr>
                {% endfor %}
            </table>
        </div>
        
        <div class="section">
            <h2>Benchmark Performance Statistics</h2>
            <table>
                {% for key, value in benchmark_stats.items() %}
                <tr>
                    <td>{{ key }}</td>
                    <td>{{ "%.2f"|format(value) }}</td>
                </tr>
                {% endfor %}
            </table>
        </div>
        
        <div class="section">
            <h2>Power Consumption Over Time</h2>
            <div class="plot">
                <img src="{{ plot_files.power }}" alt="Power Consumption">
            </div>
        </div>
        
        <div class="section">
            <h2>Benchmark Results</h2>
            <div class="plot">
                <img src="{{ plot_files.benchmark }}" alt="Benchmark Results">
            </div>
        </div>
        
        <div class="section">
            <h2>Power-Performance Correlation</h2>
            <div class="plot">
                <img src="{{ plot_files.correlation }}" alt="Power-Performance Correlation">
            </div>
        </div>
    </body>
    </html>
    ''')
    
    # Render the template
    html = template.render(
        power_stats=power_stats,
        benchmark_stats=benchmark_stats,
        plot_files=plot_files
    )
    
    # Write the report
    with open(output_file, 'w') as f:
        f.write(html)
```

## Usage Examples

### Basic Analysis

```python
from pathlib import Path
import json

# Load data
power_data = load_power_data('data/raw/power_data_osu_latency_20240321_123456.json')
osu_data = load_osu_results('data/raw/osu_latency_20240321_123456.txt')

# Calculate statistics
power_stats = analyze_power_data(power_data)
osu_stats = analyze_osu_performance(osu_data)

# Create visualizations
plot_power_consumption(power_data, 'power_consumption.png')
plot_osu_results(osu_data, 'osu_results.png')
```

### Complete Analysis Pipeline

```python
def run_analysis_pipeline(data_dir, output_dir):
    """Run the complete analysis pipeline."""
    # Create output directory
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Find all data files
    power_files = list(Path(data_dir).glob('power_data_*.json'))
    benchmark_files = list(Path(data_dir).glob('*.txt'))
    
    # Process each benchmark run
    for power_file in power_files:
        # Load power data
        power_data = load_power_data(power_file)
        
        # Find corresponding benchmark file
        benchmark_type = power_data['metadata']['benchmark']
        timestamp = power_data['metadata']['timestamp']
        benchmark_file = next(f for f in benchmark_files if timestamp in f.name)
        
        # Load benchmark data
        if 'osu' in benchmark_type:
            benchmark_data = load_osu_results(benchmark_file)
        else:
            benchmark_data = load_hpl_results(benchmark_file)
        
        # Generate report
        report_file = output_dir / f'report_{timestamp}.html'
        generate_report(power_data, {benchmark_type: benchmark_data}, report_file)
        
        print(f"Generated report: {report_file}")

# Run the pipeline
run_analysis_pipeline('data/raw', 'data/processed')
```

## Best Practices

1. **Data Collection**
   - Use consistent sampling intervals
   - Collect sufficient data points
   - Include system information
   - Record all relevant parameters

2. **Analysis**
   - Use appropriate statistical methods
   - Consider both average and peak values
   - Account for system variability
   - Validate results

3. **Visualization**
   - Use clear and informative plots
   - Include error bars where appropriate
   - Use consistent scales
   - Add proper labels and titles

4. **Reporting**
   - Include all relevant statistics
   - Provide context for results
   - Use clear and concise language
   - Include visualizations

## Contributing

When adding new analysis features:

1. Follow the existing code structure
2. Include documentation
3. Add unit tests
4. Update the report template
5. Consider performance implications

## License

This project is licensed under the MIT License - see the LICENSE file for details. 