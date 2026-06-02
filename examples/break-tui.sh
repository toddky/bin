#!/usr/bin/env bash
# Emits raw unterminated ANSI/OSC/charset escape sequences to wedge the TUI.
# Run one at a time; use `reset` or the recovery command below to recover.
#
# Recovery (blind-type if screen goes dark):
#   printf '\x1b\\\x1bc\x1b[!p\x1b(B\x1b[m\x1b[H\x1b[2J' && reset

set -euo pipefail

run_b6() { printf 'B6 unterminated OSC: \033]0;some-title-no-terminator end\n'; }
run_b4() { printf 'B4 DEC alt charset enter WITHOUT exit: \033(0lqqqk end-no-exit\n'; }
run_b8() { printf 'B8 bracketed-paste start no end: \033[200~ end\n'; }

if [[ $# -eq 0 ]]; then
	run_b6
	run_b4
	run_b8
	exit 0
fi

case "$1" in
	b6)      run_b6 ;;
	b4)      run_b4 ;;
	b8)      run_b8 ;;
	recover) printf '\x1b\\\x1bc\x1b[!p\x1b(B\x1b[m\x1b[H\x1b[2J' && reset ;;
	*)
		echo "Usage: $0 [b4|b6|b8|recover]"
		echo "  (no args runs b6, b4, b8 in sequence)"
		exit 1
		;;
esac
