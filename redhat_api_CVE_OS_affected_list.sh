#!/usr/bin/bash
############
# Authour: Jack Collins (jackcollins.me.uk)
# Purpose: Takes a list of CVEs in a text file, one on each line, and uses them
#          and Red Hat's API URLs (JSON files) to look up whether RHEL8 and RHEL9
#          are affected, creating a CSV that confirms this info, for later comparison.
#          Easy enough to update to compare different distributions if needed in future.
# Usage: ./classify-cves.sh [input_file] [output_csv]
# Last update (DD-MM-YY): 03/09/2025
############

set -euo pipefail

infile="${1:-cves.txt}"
outfile="${2:-rhel-affected.csv}"
api="https://access.redhat.com/hydra/rest/securitydata/cve"

echo "cve,rhel8_affected,rhel9_affected" > "$outfile"

while IFS= read -r cve; do
  [[ -z "${cve// }" ]] && continue
  j="$(curl -fsS "$api/$cve.json" || true)"

  # If Red Hat has no record for this CVE, assume not affecting RHEL.
  if [[ -z "$j" || "$j" = "[]" || "$j" = "null" ]]; then
    printf '%s,%s,%s\n' "$cve" "no" "no" >> "$outfile"
    continue
  fi

  jq -r '
    def affected_for(prefix):
      # Prefer package_state (current status per product)
      ( .package_state // [] | map(select(.product_name|startswith(prefix))) ) as $ps
      | if ($ps|length) > 0 then
          if any($ps[]; (.fix_state // "unknown") != "Not affected") then "yes" else "no" end
        else
          # Fallback: if there is a fixed advisory for this product, it was affected
          if ( .affected_release // [] | any(.product_name|startswith(prefix)) ) then "yes" else "no" end
        end;

    [$cve,
     (affected_for("Red Hat Enterprise Linux 8")),
     (affected_for("Red Hat Enterprise Linux 9"))
    ] | @csv
  ' --arg cve "$cve" <<<"$j" >> "$outfile"
done < "$infile"

echo "Wrote $outfile" >&2
