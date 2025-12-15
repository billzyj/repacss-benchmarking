#!/bin/bash
#
# ===== Slurm Job Info =====
#SBATCH --job-name=gpu_bench
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

# ===== Slurm Resource Requests =====
#SBATCH --partition=h100              # GPU partition (NVIDIA H100 NVL)
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:4                  # Request all 4 GPUs
#SBATCH --mem=0                       # Full node memory (512 GB)
#SBATCH --time=01:00:00

# ===== Optional =====
## #SBATCH --partition=h100-build     # Use build node (rpg-93-9)
## #SBATCH --nodelist=rpg-93-5        # Pin to a specific GPU node

# ===== Job Body =====
echo "Job $SLURM_JOB_ID running on: $SLURM_NODELIST"
echo "Allocated CPUs: $SLURM_CPUS_PER_TASK"
echo "GPUs allocated: $CUDA_VISIBLE_DEVICES"

# ---- Checkpoint 1: Job start (allocation granted) ----
T0=$(date +%s)
echo "T0 Job start: $(date)"

# Environment setup
source ~/.bashrc
module load cuda/12.9.0 || true

# ---- Checkpoint 2: After environment setup ----
T1=$(date +%s)
echo "T1 Env ready: $(date)"

# Benchmark workload
echo "Running GPU workload..."
srun nvidia-smi

# ---- Checkpoint 3: Benchmark end ----
T2=$(date +%s)
echo "T2 Benchmark end: $(date)"

# (Optional post-processing)
sleep 2

# ---- Checkpoint 4: Job end ----
T3=$(date +%s)
echo "T3 Job end: $(date)"

# Print durations
echo "Durations (seconds):"
echo "  Env setup time   = $((T1 - T0))"
echo "  Benchmark time   = $((T2 - T1))"
echo "  Post-bench slack = $((T3 - T2))"
echo "  Total job time   = $((T3 - T0))"