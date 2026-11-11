#!/bin/bash
# Show what arrived for one job: the delivered report files and the in-band summary status.
#   parse.sh <OUT_ROOT> <job_id>
set -euo pipefail
out_root="${1:?OUT_ROOT}"; job="${2:?job id}"
reports="$out_root/power_reports/$job"
for kind in oob ib; do
  if [[ -d "$reports/$kind" ]]; then
    echo "$kind: $(ls "$reports/$kind" | tr '\n' ' ')"
  else
    echo "$kind: not delivered (yet)"
  fi
done
if [[ -f "$reports/ib/summary.json" ]]; then
  python3 - "$reports/ib/summary.json" <<'PY'
import json, sys
s = json.load(open(sys.argv[1]))
print("ib status:", s.get("status"), "| missing nodes:", s.get("nodes", {}).get("missing"))
for node, n in s.get("per_node", {}).items():
    print(f"  {node}: coverage {n.get('coverage')}")
print("  average power (W):", s.get("average_power_w"))
PY
fi
