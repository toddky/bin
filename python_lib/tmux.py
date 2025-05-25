#!/usr/bin/env python3
# USAGE: tmux.py
# DESCRIPTION: tmux stuff

import re
import subprocess

def get_cmd_output():
    cmd = ['tmux', 'capture-pane', '-p', '-S', '-']
    result = subprocess.run(cmd, capture_output=True)
    stdout = result.stdout.decode('utf-8') 

    prompt_re = r'^todd.*»\s*(.*)$'
    timestamp_re = '\[\d{2}:\d{2}:\d{2}\] (Started|Finished)'
    exited_re = r'\(exited \d+\)'

    in_command = False
    output = ''
    cmd_output = []

    for line in stdout.splitlines():

        if re.search(exited_re, line): continue
        if re.search(timestamp_re, line): continue

        if match := re.match(prompt_re, line):
            if in_command:
                cmd_output.append((command, output.strip()))
                output = ''

            command = match.group(1).strip()
            in_command = True
            continue

        if in_command:
            output += f'{line}\n'

    return cmd_output


if __name__ == '__main__':
    cmd_output = get_cmd_output()
    for command, output in cmd_output:
        print(f'$ {command}')
        print(output.strip())

