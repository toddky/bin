#!/usr/bin/env python3
# USAGE: static.py
# DESCRIPTION: Static variables

def static(i, prev=[]):
    if prev:
        print(f'current:{i} prev:{prev[0]}')
    else:
        print(f'current:{i}')
    prev.clear()
    prev.append(i)

static(1)
static(2)

