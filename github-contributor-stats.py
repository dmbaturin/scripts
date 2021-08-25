#!/usr/bin/env python3
# Copyright (C) 2021 Daniil Baturin <daniil at baturin dot org>
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
# Synopsis: expors repository contributor data from GitHub over its REST API
#
# Usage: GITHUB_TOKEN=... github-contributors.py user/repo

import os
import sys
import json
import urllib.request

def make_request(query_url):
    req = urllib.request.Request(query_url)
    token = os.getenv("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", "token {0}".format(token))

    with urllib.request.urlopen(req) as f:
        data = json.load(f)

    return data

def fetch_contributors(repo):
    contributors = []
    page = 0
    while True:
        query_url = "https://api.github.com/repos/{0}/contributors?page={1}".format(repo, page)
        data = make_request(query_url)
        if data:
            contributors += data
            page += 1
        else:
            break

    return contributors

if __name__ == '__main__':
    contributors = fetch_contributors(sys.argv[1])
    for c in contributors:
        # Get user's stats
        query_url = "https://api.github.com/users/{0}".format(c["login"])
        user_data = make_request(query_url)

        # Screw datetime parsing. ;)
        user_registration_year = user_data['created_at'][:4]

        print("{0},{1},{2}".format(c['login'], c['contributions'], user_registration_year))

