#!/usr/bin/env python3

import re
import sys

if len(sys.argv) < 3:
    print("Usage: {0} <style file> <target file>")
    sys.exit(1)

line_no = 1
# Assume success until proven otherwise
exit_code = 0

# Get the style data
with open(sys.argv[1], 'r') as f:
    abbr_list = f.readlines()
abbr_list = map(lambda s: s.strip(), abbr_list)

abbrs = {}
for a in abbr_list:
    abbrs[a.lower()] = a

with open(sys.argv[2], 'r') as f:
    for line in f:
        words = re.split(r'\s+', line)
        for w in words:
            wl = w.lower()
            if (wl in abbrs) and (w != abbrs[wl]):
                print("Line {0}: Incorrect capitalization of {1} ({2})!".format(line_no, abbrs[wl], w))
                print(line)
                exit_code = 1
        line_no += 1

sys.exit(exit_code)
