#!/usr/bin/env bash
# RAM used percent = (wired + active + compressed) pages / total memory,
# the same figure Activity Monitor reports as "Memory Used".
total="$(sysctl -n hw.memsize)"
pct="$(vm_stat | awk -v total="$total" '
  /page size of/            {ps=$8}
  /Pages wired down/        {w=$4}
  /Pages active/            {a=$3}
  /Pages occupied by compressor/ {c=$5}
  END {gsub("\\.","",w); gsub("\\.","",a); gsub("\\.","",c);
       if (ps && total) printf "%d", (w+a+c)*ps*100/total}')"
if [ -n "$pct" ]; then
  sketchybar --set "$NAME" label="RAM ${pct}%"
else
  sketchybar --set "$NAME" label="RAM ?"
fi
