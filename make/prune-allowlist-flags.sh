#!/usr/bin/env bash
# Prints --prune-allowlist flags for the kinds in the allowlist file that the cluster serves.
set -euo pipefail

file="${1:-prune-allowlist}"
[[ -f "$file" ]] || exit 0

# api-resources exits non-zero when an aggregated API is down but still lists the rest
resources="$(kubectl api-resources --no-headers 2>/dev/null | awk '{print $(NF-2)"/"$NF}' || true)"

flags=()
for gvk in $(sed 's/#.*//' "$file"); do
  if grep -qxF "${gvk#core/}" <<<"$resources"; then
    flags+=("--prune-allowlist=$gvk")
  else
    >&2 echo "skipping $gvk: not served by this cluster"
  fi
done

if [[ ${#flags[@]} -eq 0 ]]; then
  >&2 echo "$file has no kinds served by this cluster"
  exit 1
fi

echo "${flags[*]}"
