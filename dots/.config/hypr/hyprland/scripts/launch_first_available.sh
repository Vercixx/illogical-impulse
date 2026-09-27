#!/usr/bin/env bash
for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    read -ra words <<< "$cmd"
    for program in "${words[@]}"; do
        [[ "$program" == env || "$program" == *=* ]] || break
    done
    eval "command -v $program" >/dev/null 2>&1 || continue
    eval "$cmd" &
    exit
done
