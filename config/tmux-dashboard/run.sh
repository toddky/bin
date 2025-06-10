#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

index="$(tmux display-message -p '#{pane_index}')"

# REVISIT: Unhardcode this
yaml="$SCRIPT_DIR/uptime.yaml"

select=".[][$index]"
info="$(cat uptime.yaml | jc --yaml | jq "$select")"

cmd="$(jq -r '.command' <<< "$info")"
refresh="$(jq '.refresh' <<< "$info")"

if [[ "$cmd" == 'null' ]]; then
	exit
fi

while true; do
	eval $cmd
	sleep "$refresh"
done


