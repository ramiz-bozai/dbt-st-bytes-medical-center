#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 /Volumes/<catalog>/<schema>/<volume>" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage

volume_path="${1#dbfs:}"
volume_path="${volume_path%/}"
[[ "$volume_path" =~ ^/Volumes/[^/]+/[^/]+/[^/]+$ ]] || usage

command -v databricks >/dev/null 2>&1 || {
  echo "Error: Databricks CLI is not installed or not on PATH." >&2
  exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/seeds/st_bytes_medical_center"

expected_files=(
  allergies.csv
  careplans.csv
  claims.csv
  claims_transactions.csv
  conditions.csv
  devices.csv
  encounters.csv
  imaging_studies.csv
  immunizations.csv
  medications.csv
  observations.csv
  organizations.csv
  patients.csv
  payer_transitions.csv
  payers.csv
  procedures.csv
  providers.csv
  supplies.csv
)

for filename in "${expected_files[@]}"; do
  file_path="$source_dir/$filename"
  [[ -s "$file_path" ]] || {
    echo "Error: missing or empty mock data file: $file_path" >&2
    exit 1
  }
done

actual_count="$(find "$source_dir" -maxdepth 1 -type f -name '*.csv' | wc -l | tr -d ' ')"
[[ "$actual_count" -eq "${#expected_files[@]}" ]] || {
  echo "Error: expected ${#expected_files[@]} CSV files, found $actual_count in $source_dir." >&2
  exit 1
}

echo "Uploading ${#expected_files[@]} synthetic CSV files to $volume_path"
for filename in "${expected_files[@]}"; do
  databricks fs cp \
    "$source_dir/$filename" \
    "dbfs:$volume_path/$filename" \
    --overwrite
done

echo "Upload complete."
