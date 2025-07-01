#!/usr/bin/env python3
# USAGE: unsafe_yaml.py
# DESCRIPTION: Load unsafe YAML content that executes code during loading

yaml_str = '''
!!python/object/apply:os.system
args: ["echo 'Code executed during YAML load'"]
'''

import yaml
info = yaml.load(yaml_str, Loader=yaml.Loader)
#info = yaml.load(yaml_str, Loader=yaml.SafeLoader)
#info = yaml.safe_load(yaml_str)

