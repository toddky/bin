#!/usr/bin/env bash
# USAGE: source raw.sh
# DESCRIPTION: Enter raw mode, restore settings on exit

# Example
# https://viewsourcecode.org/snaptoken/kilo/02.enteringRawMode.html

# Restore settings on exit
_stty_orig="$(stty -g)"
function atexit {
	stty "$_stty_orig"
}
trap atexit EXIT

# Raw mode
stty raw
#stty -echo -icanon time 0 min 1
stty -echo -icanon time 0 min 0

