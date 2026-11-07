#!/usr/bin/env bash
# Usage: watchdog.sh <shell pid> <log dir>
# SIGABRT after ~30 s without IPC replies makes Quickshell's crash handler save a stack trace and restart.

pid=$1
dir=$2
runlog="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-pid/$pid/log.log"

mkdir -p "$dir"
ls -1t "$dir"/*.log 2>/dev/null | tail -n +20 | xargs -r rm --
out="$dir/$(date +%F_%H-%M-%S)_$pid.log"

note() {
    echo "$(date '+%F %T.%3N') WATCHDOG: $*" >> "$out"
}

tail -n +1 -F --pid=$$ "$runlog" >> "$out" 2>/dev/null &

misses=0
while kill -0 "$pid" 2>/dev/null; do
    sleep 10
    if timeout 5 qs ipc --pid "$pid" show > /dev/null 2>&1; then
        misses=0
        continue
    fi
    kill -0 "$pid" 2>/dev/null || break
    misses=$((misses + 1))
    note "No IPC reply from $pid ($misses/3)"
    for task in /proc/"$pid"/task/*; do
        note "  $(< "$task/comm"): $(grep -m1 '^State' "$task/status" | cut -f2) wchan=$(< "$task/wchan")"
    done
    if ((misses >= 3)); then
        note "Sending SIGABRT, crash report goes to ~/.cache/quickshell/crashes"
        kill -ABRT "$pid"
        exit
    fi
done
note "Shell process $pid is gone"
