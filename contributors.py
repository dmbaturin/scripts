#!/usr/bin/env python3
# Copyright (C) 2019 Daniil Baturin <daniil at baturin dot org>
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
#
# Synopsis: like "git shortlog", but works across multiple repos
# For counting contributors to a project that has more than one repo
#
# Clone all the repos into one dir, then run
# contributors.py --since $DATE /path/to/repos/dir

import re
import os
import sys
import operator
import argparse
import subprocess

GIT_LOG_CMD = "git shortlog --summary --numbered --email"

parser = argparse.ArgumentParser()
parser.add_argument('--pull', action='store_true', help='Force git pull')
parser.add_argument('--since', type=str, help='Earliest date to count from')
parser.add_argument('source_path', type=str, help='Path to the directory with git repos')

args = parser.parse_args()

if args.since:
    GIT_LOG_CMD += " --since {0}".format(args.since)

repos = filter(lambda x: os.path.isdir(os.path.join(args.source_path, x)), os.listdir(args.source_path))

contributors = {}

def update_contributors(contributors):
    cmd = GIT_LOG_CMD

    p = subprocess.Popen([cmd], stdout=subprocess.PIPE, shell=True)
    out = p.stdout.readlines()

    for l in out:
        commits, name, email = re.match(r'^\s*(\d+)\s+(.*)\s+<(.*)>\s*$', l.decode()).groups()
        if email in contributors:
            contributors[email]['commits'] += int(commits)
        else:
            contributors[email] = {}
            contributors[email]['commits'] = int(commits)
            contributors[email]['name'] = name

for r in repos:
    repo_path = os.path.join(args.source_path, r)
    print("Processing {0}".format(repo_path), file=sys.stderr)
    os.chdir(repo_path)
    if args.pull:
        os.system("git pull")
    update_contributors(contributors)

contributors = sorted(contributors.items(), key=lambda x: operator.itemgetter(1)(x)['commits'], reverse=True)

for k in contributors:
    email, data = k
    print("{0} {1} {2}".format(data['commits'], data['name'], email))
