#!/usr/bin/env python3
# USAGE: ./tee.py
# DESCRIPTION: Example tee-ing stdout/stderr to a file

import sys
from pathlib import Path

class Tee:
    """
    Duplicate stdout/stderr to console and file

    Example Usage:
    with Tee("a.txt"):
        print("stdout goes to a.txt and stdout")
        print("stderr also goes to a.txt and stdout", file=sys.stderr)
    """
    def __init__(self, filename, mode='w'):
        self.filename = Path(filename)
        self.mode = mode
        self.file = None
        self.orig_stdout = None
        self.orig_stderr = None

    def __enter__(self):
        self.file = open(self.filename, self.mode)
        self.orig_stdout = sys.stdout
        self.orig_stderr = sys.stderr

        # Create a proper tee writer instance
        self.writer = self.writer()
        sys.stdout = sys.stderr = self.writer
        return self

    def writer(self):
        file = self.file
        stdout = self.orig_stdout

        class TeeWriter:
            def write(self, data):
                stdout.write(data)
                file.write(data)
                return len(data)

            def flush(self):
                stdout.flush()
                file.flush()

            def isatty(self):
                return stdout.isatty()

        return TeeWriter()

    def __exit__(self, *args):
        sys.stdout = self.orig_stdout
        sys.stderr = self.orig_stderr
        self.file.close()


with Tee("a.txt"):
    print("stdout goes to a.txt and stdout")
    print("stderr also goes to a.txt and stdout", file=sys.stderr)

