# Shared helpers for the profiling-overhead jobs (sourced by the sbatch scripts).
now() { date +%s.%N | cut -c1-14; }

# Record the in-band runner units that exist on this node for this job, with their CPU time.
# Called at the end of the job, before the Epilog stops the runner.
record_runner() {
  local out="$1"
  {
    echo "unit,active_state,cpu_usage_nsec,memory_peak_bytes,active_enter_monotonic_us"
    for unit in $(systemctl list-units --all --plain --no-legend 'repacss-power-ib@*' 2>/dev/null | awk '{print $1}'); do
      case "$unit" in *"${SLURM_JOB_ID}"*) ;; *) continue ;; esac
      systemctl show "$unit" -p ActiveState,CPUUsageNSec,MemoryPeak,ActiveEnterTimestampMonotonic 2>/dev/null \
        | awk -F= -v u="$unit" '{v[$1]=$2} END {print u "," v["ActiveState"] "," v["CPUUsageNSec"] "," v["MemoryPeak"] "," v["ActiveEnterTimestampMonotonic"]}'
    done
  } > "$out"
}

job_header() {
  echo "job_id=$SLURM_JOB_ID node=$(hostname) mode=$MODE comment=$(scontrol show job "$SLURM_JOB_ID" 2>/dev/null | sed -n 's/.*Comment=\(.*\)$/\1/p')"
  echo "job_start_unix=$(now) job_start_local=$(date +%Y-%m-%dT%H:%M:%S%z)"
}
