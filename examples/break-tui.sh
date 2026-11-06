#!/usr/bin/env bash
# USAGE: break-tui.sh <osc-title|line-drawing|bracketed-paste|all|recover>
# DESCRIPTION: Print unterminated escape sequences to test how a TUI recovers from them.

declare -A sequences=(
    [osc-title]='unterminated OSC title: \033]0;some-title-no-terminator end\n'
    [line-drawing]='DEC line-drawing charset enter WITHOUT exit: \033(0lqqqk end-no-exit\n'
    [bracketed-paste]='bracketed-paste start no end: \033[200~ end\n'
)

function print_usage() {
    cat 1>&2 <<EOF
Usage: $0 <osc-title|line-drawing|bracketed-paste|all|recover>
  osc-title        OSC window title with no terminator
  line-drawing     DEC line-drawing charset with no switch back to ASCII
  bracketed-paste  bracketed-paste start marker with no end marker
  all              all three, with osc-title last
  recover          reset the terminal (blind-type it if the screen goes dark)
EOF
}

if [[ $# -ne 1 ]]; then
    print_usage
    exit 1
fi

case "$1" in
    osc-title|line-drawing|bracketed-paste)
        printf "${sequences[$1]}"
        ;;
    all)
        # An unterminated OSC swallows any text after it, so it goes last.
        # line-drawing stays active for the rest, so the osc-title label prints as box-drawing glyphs.
        for name in bracketed-paste line-drawing osc-title; do
            printf "${sequences[$name]}"
        done
        ;;
    # ST closes any open OSC first so the full reset (ESC c) is parsed as a command.
    recover)
        printf '\033\\\033c' && reset
        ;;
    *)
        echo "ERROR: unknown case: $1" 1>&2
        print_usage
        exit 1
        ;;
esac
