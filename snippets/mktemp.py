#!/usr/bin/env python3
# USAGE: mktemp.py
# DESCRIPTION: Temp file context manager

import tempfile
import os
from contextlib import contextmanager

@contextmanager
def temp(mode='w', suffix='', prefix='tmp', dir=None):
    '''
    Temporary file context manager.
    '''
    fd, path = tempfile.mkstemp(suffix=suffix, prefix=prefix, dir=dir)
    try:
        with os.fdopen(fd, mode) as file_obj:
            yield file_obj, path
    finally:
        try:
            os.unlink(path)
        except OSError:
            pass

with temp() as (f, path):
    f.write("Temp info\n")
    f.flush()
    print(path)

