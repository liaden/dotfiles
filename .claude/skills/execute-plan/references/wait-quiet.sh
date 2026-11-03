#!/usr/bin/env bash
# Only non-shell processes count, so no waiting shell (this one, another waiter, the
# tool wrapper around it) can match its own command line. Stop it by pid, never pkill -f.
set -euo pipefail

pattern=${1:?usage: wait-quiet.sh '<pgrep -f pattern>' [max-seconds] [load-ceiling]}
limit=${2:-1800}
ceiling=${3:-$(nproc)}

busy_count() {
  local n=0 pid comm
  for pid in $(pgrep -f -- "$pattern" || true); do
    comm=$(cat "/proc/$pid/comm" 2>/dev/null) || continue
    case $comm in
      bash|zsh|sh|dash|fish|flock|timeout|sudo) ;;
      *) n=$((n + 1)) ;;
    esac
  done
  echo "$n"
}

load1() { cut -d' ' -f1 /proc/loadavg; }

load_ok() { awk -v l="$(load1)" -v c="$ceiling" 'BEGIN { exit !(l < c) }'; }

start=$SECONDS
quiet=0
while (( SECONDS - start < limit )); do
  if (( $(busy_count) == 0 )) && load_ok; then
    quiet=$((quiet + 1))
    # a run that just ended still shows in load; 2 readings 5 s apart confirm the box is idle
    (( quiet >= 2 )) && exit 0
  else
    quiet=0
  fi
  sleep 5
done

echo "wait-quiet: not quiet after ${limit}s: $(busy_count) matching processes, load $(load1), ceiling $ceiling" >&2
exit 1
