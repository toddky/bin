#!/usr/bin/env python3

import base64
import sys

text = sys.stdin.read()
encoded_text = base64.b64encode(text.encode("utf-8")).decode("utf-8")
osc52_sequence = f"\033]52;c;{encoded_text}\a"
sys.stdout.write(osc52_sequence)
sys.stdout.flush()

