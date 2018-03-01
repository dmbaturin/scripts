#!/usr/bin/env python
#
# Copyright (C) 2018 Daniil Baturin <daniil at baturin dot org>
#
# Permission is hereby granted, free of charge,
# to any person obtaining a copy of this software
# and associated documentation files (the "Software"),
# to deal in the Software without restriction,
# including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject
# to the following conditions:
#
# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import sys
import re
import json
import subprocess


def split_path(p):
    return re.split(r"\s*", p)

def dict_insert(d, key_list, value):
    last_key = key_list[-1]
    all_but_last_keys = key_list[:-1]
    innermost_dict = d
    for k in all_but_last_keys:
        if not innermost_dict.has_key(k):
            innermost_dict[k] = {}
        innermost_dict = innermost_dict[k]
    innermost_dict[last_key] = value

def dict_get(d, key_list):
    v = d
    for k in key_list:
        v = v[k]
    return v


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: {0} <config paths>".format(sys.argv[0]))
        print("Example: {0} \'service dhcp-server\' \'system login\'".format(sys.argv[0]))
        sys.exit(1)

try:
    p = subprocess.Popen("mca-ctrl -t dump-cfg", stdout=subprocess.PIPE, shell=True)
    full_config = json.load(p.stdout)
    p.wait()
    if p.returncode != 0:
        raise Exception("Error executing command")
except Exception as e:
    print(e)
    sys.exit(1)

config = {}

paths = map(split_path, sys.argv[1:])

for p in paths:
    try:
        v = dict_get(full_config, p)
        dict_insert(config, p, v)
    except KeyError:
        print("Config path {0} does not exist".format(p))
        sys.exit(1)

print(json.dumps(config, indent=4))
