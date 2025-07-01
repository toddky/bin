#!/usr/bin/env bash
# vim: ft=python ts=4 sw=4 et
_='''
'
PATH="/path/to/python3/3.11.3/bin:$PATH" exec python3 $0 ${1+"$@"}
'
'''
#!/usr/bin/env python3
# USAGE: bootstrap.py
# DESCRIPTION: Call bash script to set up environment then run as Python script

