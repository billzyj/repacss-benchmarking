#!/bin/bash
#SBATCH --job-name=lmp_zen4_scaling
#SBATCH --partition=zen4          # zen4 partition
#SBATCH --nodes=1                 # 1 node
#SBATCH --ntasks-per-node=256     # 256 MPI ranks available
#SBATCH --time=48:00:00
#SBATCH --exclusive
#SBATCH --output=slurm-lmp-scaling.%j.out
#SBATCH --error=slurm-lmp-scaling.%j.err

##############################################
# 0. Load Spack + LAMMPS
##############################################

# source /path/to/spack/share/spack/setup-env.sh   # if needed
spack load lammps
cd ~/data

echo "Running on host: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "LAMMPS: $(which lmp)"
echo "MPI: $(which mpirun)"
echo

##############################################
# 1. Create per-job output directory
##############################################

OUTDIR="${HOME}/data/slurm${SLURM_JOB_ID}"
mkdir -p "${OUTDIR}"

echo "Output directory: ${OUTDIR}"
echo

# ---------------------------
# 2. Scaling loop: 1,2,4,...,256 ranks
# ---------------------------

# List of MPI task counts
ranks_list="256 224 192 160 128 96 64 48 32 24 16 12 8 4 2 1"

for nt in $ranks_list; do
    echo "============================================"
    echo " Running LAMMPS with ${nt} MPI ranks"
    echo "============================================"

    logfile="${OUTDIR}/log${nt}"

 # --- Record START time ---
    start_ts=$(date "+%Y-%m-%d %H:%M:%S")
    start_epoch=$(date +%s)
    echo "Start time (human): $start_ts"
    echo "Start epoch seconds: $start_epoch"

    ##############################################
    #  Actual LAMMPS Run
    ##############################################

    # OpenMPI-style mapping (as requested)
    mpirun --bind-to core --map-by core -np ${nt} \
        lmp -in in.lj -l ${logfile}

    # --- Record END time ---
    end_ts=$(date "+%Y-%m-%d %H:%M:%S")
    end_epoch=$(date +%s)
    echo "End time (human): $end_ts"
    echo "End epoch seconds: $end_epoch"

    echo
    echo " Finished run with ${nt} ranks, log saved to ${logfile}"
    echo
done

echo "All runs completed."