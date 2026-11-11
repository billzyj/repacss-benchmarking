# LAMMPS environment for zen4_lammps.sbatch (sourced, not executed). Everything comes from site modules.

cpu_modules() {
  [[ -f /etc/profile.d/modules.sh ]] && source /etc/profile.d/modules.sh
  module purge >/dev/null 2>&1
  # The site MPICH 4.3.2 (ch4:ucx, PMIx) and the LAMMPS build on it.
  module load mpich/4.3.2 openblas/0.3.30 lammps/20250722 >/dev/null 2>&1
}

cpu_runtime_env() {
  # The site UCX has no CMA/KNEM/XPMEM transport; a single-node run otherwise sends large intra-node
  # messages through InfiniBand loopback. Restrict UCX to shared memory.
  export UCX_TLS=self,sm
  export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
  ulimit -s unlimited 2>/dev/null || true
}

# One rank per physical core, block placement: ranks 0..NP-1 on cores 0..NP-1 (socket 0 first).
cpu_srun() {
  local np="$1"; shift
  srun --mpi=pmix --ntasks="$np" --cpus-per-task=1 --cpu-bind=cores --distribution=block:block "$@"
}
