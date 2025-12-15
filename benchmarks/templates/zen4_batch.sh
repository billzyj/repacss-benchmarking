#!/bin/bash
#
# ===== Slurm Job Info =====
#SBATCH --job-name=CPU_IO_bench
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

# ===== Slurm Resource Requests =====
#SBATCH --partition=zen4              # CPU partition (AMD EPYC 9754) 256 cores/node
#SBATCH --nodes=1
#SBATCH --ntasks=256
#SBATCH --cpus-per-task=1
#SBATCH --mem=0                       # Full node memory (1.5 TB)
#SBATCH --time=24:00:00

# ===== Optional =====
## #SBATCH --nodelist=rpc-91-9        # Pin to a specific Zen4 node

echo "===== Job $SLURM_JOB_ID on $SLURM_NODELIST ====="
echo "CPUs/task: $SLURM_CPUS_PER_TASK | Tasks: $SLURM_NTASKS"
echo "Working directory: $(pwd)"
echo

# ===== Environment =====
source ~/.bashrc
ml load mpich/4.1.2 pmix/5.0.3
export PMIX_MCA_psec=none    # preferred over PMIX_SECURITY_MODE=none
spack load ior /cc || true
LOGDIR="ior_logs_${SLURM_JOB_ID}"
mkdir -p "$LOGDIR"

# ===== Benchmark Parameters =====
IOR_BIN=$(which ior)
TARGETS=("MEM_IO" "LOCAL_IO" "NFS_IO")
XFERSIZES=("16k" "1m" "16m")       # transfer size per I/O call
NUM_PROCS=("1" "64" "256")         # number of MPI ranks
BLOCKSIZES=("64g" "1g" "256m")     # per-rank size so total=64G
SEGMENTS=16                         # number of segments per file
NUM_RUNS=3                         # repetitions per configuration

for target_var in "${TARGETS[@]}"; do
  TARGET_DIR=${!target_var}
  mkdir -p "$TARGET_DIR"

  for XFERSIZE in "${XFERSIZES[@]}"; do
    for idx in "${!NUM_PROCS[@]}"; do
      NP=${NUM_PROCS[$idx]}
      BLOCKSIZE=${BLOCKSIZES[$idx]}

      FILE_WARM="$TARGET_DIR/iorfile_${SLURM_JOB_ID}_warm_${BLOCKSIZE}_${XFERSIZE}_${NP}p"
      FILE_COLD="$TARGET_DIR/iorfile_${SLURM_JOB_ID}_cold_${BLOCKSIZE}_${XFERSIZE}_${NP}p"

      echo "[$(date)] Warm run: $target_var | XS=$XFERSIZE | NP=$NP | BS=$BLOCKSIZE | Iter=$NUM_RUNS"
      mpirun -np $NP $IOR_BIN -a POSIX -C -w -r -e\
             -t $XFERSIZE -b $BLOCKSIZE -i $NUM_RUNS \
             -o "$FILE_WARM" \
             > "$LOGDIR/warm_${target_var,,}_${BLOCKSIZE}_${XFERSIZE}_${NP}p.log" 2>&1

      # Skip O_DIRECT for tmpfs
      if [[ "$target_var" != "MEM_IO" ]]; then
        echo "[$(date)] Cold run: $target_var | XS=$XFERSIZE | NP=$NP | BS=$BLOCKSIZE | Iter=$NUM_RUNS"
        mpirun -np $NP $IOR_BIN -a POSIX -C -w -r -e\
               -t $XFERSIZE -b $BLOCKSIZE -i $NUM_RUNS -O useO_DIRECT=1 \
               -o "$FILE_COLD" \
               > "$LOGDIR/cold_${target_var,,}_${BLOCKSIZE}_${XFERSIZE}_${NP}p.log" 2>&1
      else
        echo "[$(date)] Skipped cold run for $target_var (O_DIRECT not supported)"
      fi

      rm -f "$FILE_WARM" "$FILE_COLD"
    done
  done
done

echo "===== Job $SLURM_JOB_ID completed at $(date) ====="