#!/usr/bin/env bash
# USAGE: ./main.bash
# DESCRIPTION: Main function

function main() {
	echo "This is main() called with args $(printf '%q ' "$@")"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi

