#!/usr/bin/env python3
# USAGE: handle_signal.py
# DESCRIPTION: Handle signal

import atexit
import signal
import sys

from time import sleep

RETVAL = 0

def cleanup():
    print(f"Exit code: {RETVAL}")

def handle_signal(signum, frame):
    global RETVAL
    RETVAL = signum
    sys.exit(128 + signum)

atexit.register(cleanup)
signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGINT, handle_signal)

print('Sleeping for 5 seconds... kill with Ctrl-C')
sleep(5)

RETVAL = 42
sys.exit(RETVAL)

