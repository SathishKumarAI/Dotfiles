#!/usr/bin/env bash
# drain-swap.sh — force pages stuck in swap back into RAM, ending thrash.
# Safe only when free RAM > used swap. Script checks that before acting.
set -euo pipefail

used_swap_kb=$(awk '/SwapTotal/{t=$2} /SwapFree/{f=$2} END{print t-f}' /proc/meminfo)
avail_kb=$(awk '/MemAvailable/{print $2}' /proc/meminfo)

printf 'Swap in use: %d MB | RAM available: %d MB\n' "$((used_swap_kb/1024))" "$((avail_kb/1024))"

if (( used_swap_kb > avail_kb )); then
  echo "ABORT: not enough free RAM to absorb swap safely. Free memory first."
  exit 1
fi

echo "Draining swap (swapoff then swapon)…"
sudo swapoff -a
sudo swapon -a
echo "Done. New state:"
free -h
