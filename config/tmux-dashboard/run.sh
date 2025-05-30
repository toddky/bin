#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

index="$(tmux display-message -p '#{pane_index}')"
index="$((index - 1))"

# REVISIT: Unhardcode this
yaml="$SCRIPT_DIR/uptime.yaml"

select=".[][$index]"
info="$(cat uptime.yaml | jc --yaml | jq "$select")"

cmd="$(jq -r '.command' <<< "$info")"
refresh="$(jq '.refresh' <<< "$info")"

while true; do
	eval $cmd
	sleep "$refresh"
done


