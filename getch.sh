#!/usr/bin/env bash

# REVISIT: Another way to do this?
# https://github.com/iruzo/pxmenu/blob/2508ee1200b98b68897618bf3c8e60632f29fdb1/pxmenu#L10

# stty -echo -icanon time 0 min 0

# read -r -n1 preserves newlines; dd + $() strips them so Enter never matches
IFS= read -r -n1 key

# Only slurp trailing bytes when the first byte is ESC (escape sequence).
# Otherwise dd blocks waiting for input the user never sent.
if [[ "$key" == $'\e' ]]; then
	next='.'
	while [[ -n "$next" ]]; do
		IFS= read -r -n1 -t 0.05 next || next=''
		key+="$next"
	done
fi

case "$key" in

	$'\e'   ) echo 'esc'     ;;
	$'\e[A' ) echo 'up'      ;;
	$'\e[B' ) echo 'down'    ;;
	$'\e[C' ) echo 'left'    ;;
	$'\e[D' ) echo 'right'   ;;
	$'\e[5~') echo 'pageup'  ;;
	$'\e[6~') echo 'pagedown';;

	$'\n'|'') echo 'enter'   ;;
	$'\r'   ) echo 'enter'   ;;

	' '     ) echo 'space'   ;;
	$'\t'   ) echo 'tab'     ;;

	*       ) echo "$key";;
	#*       ) echo -n "$key"  | xxd -p ;;
esac
