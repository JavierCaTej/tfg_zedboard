#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Uso: $0 <csv1> [csv2 ...]" >&2
  exit 1
fi

printf '%-28s %-14s %-14s %-14s %-14s %-12s\n' \
  "archivo" "avg_ns" "elapsed_ns" "iters" "warmup" "mismatches"

for csv in "$@"; do
  if [ ! -f "$csv" ]; then
    echo "No existe: $csv" >&2
    exit 1
  fi

  line="$(tail -n 1 "$csv")"

  avg_ns="$(printf '%s\n' "$line" | awk -F',' '{print $9}')"
  elapsed_ns="$(printf '%s\n' "$line" | awk -F',' '{print $8}')"
  iters="$(printf '%s\n' "$line" | awk -F',' '{print $6}')"
  warmup="$(printf '%s\n' "$line" | awk -F',' '{print $7}')"
  mismatches="$(printf '%s\n' "$line" | awk -F',' '{print $10}')"

  printf '%-28s %-14s %-14s %-14s %-14s %-12s\n' \
    "$(basename "$csv")" \
    "$avg_ns" \
    "$elapsed_ns" \
    "$iters" \
    "$warmup" \
    "$mismatches"
done
