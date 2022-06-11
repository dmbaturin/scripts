#!/usr/bin/env python3

# Retrieves release notes from phabricator.vyos.net
#
# NOTE: this script heavily relies on custom fields that we created in the VyOS project
# Phabricator, and is not going to work with _every_ Phabricator instance,
# unless you create the same fields.
# If you want to adopt this script for your project, you'll need to create fields with exact
# those values, or adjust the script for your fields.
#
# Usage:
#  1. Go to https://phabricator.vyos.net/maniphest/
#  2. Fill the search form and run "Search". You will be redirected to a URL like
#     https://phabricator.vyos.net/maniphest/query/<queryKey>/#R
#     Copy the <queryKey> part. That will be your -q/--query-key argument
#  3. Take the query key part out of that URL
#  4. Go to https://phabricator.vyos.net/settings/user/<user>/page/apitokens/
#     and generate yourself a token. It goes to -t/--api-token
#  5. Now run vyos-release-notes.py -t <API key> -q <queryKey>

import re
import sys
import json
import copy
import urllib
import argparse

import urllib3

parser = argparse.ArgumentParser()
parser.add_argument("-q", "--query-key", type=str, help="Query key", required=True)
parser.add_argument("-t", "--api-token", type=str, help="API token", required=True)

args = parser.parse_args()

## Templates
template = """
  <li><a href="{base_url}/T{id}">T{id}</a>: {title}</li>
"""

phabricator_url = "https://phabricator.vyos.net"

def print_tasks(data):
    for t in data:
        if t["fields"]["status"]["value"] in ["invalid", "wontfix"]:
           continue

        print(template.format(id=t["id"], title=t["fields"]["name"], base_url=phabricator_url))

def copy_tasks(ts, l, field, func):
    for t in ts:
        if func(t["fields"][field]):
            l.append(copy.copy(t))

# Retrieve the data
http = urllib3.PoolManager()
resp = http.request(
    "POST",
    f"{phabricator_url}/api/maniphest.search",
    body=urllib.parse.urlencode({'api.token': args.api_token, 'queryKey': args.query_key}).encode('ascii'),
    headers={"Content-Type": "application/x-www-form-urlencoded"})
resp = json.loads(resp.data)
data = resp["result"]["data"]

changelog = {
  "vulnerabilities": [], "breaking": [], "syntax": [], "features": [], "fixes": [], "misc": []
}

copy_tasks(data, changelog["vulnerabilities"], "custom.issue-type", lambda x: x == "vulnerability")
copy_tasks(data, changelog["breaking"], "custom.breaking-change", lambda x: x == "syntax-incomp")
copy_tasks(data, changelog["syntax"], "custom.breaking-change", lambda x: x == "syntax")
copy_tasks(data, changelog["features"], "custom.issue-type", lambda x: x in ["feature", "improvement"])
copy_tasks(data, changelog["fixes"], "custom.issue-type", lambda x: x == "bug")
copy_tasks(data, changelog["misc"], "custom.issue-type", lambda x: x not in ["feature", "improvement", "bug", "vulnerability"])

changelog["features"].sort(key=lambda x: x["id"])
changelog["fixes"].sort(key=lambda x: x["id"])
data.sort(key=lambda x: x["id"])

if changelog["vulnerabilities"]:
    print("<h3>Security</h3>")
    print("<ul>")
    print_tasks(changelog["vulnerabilities"])
    print("</ul>")

if changelog["breaking"]:
    print("<h3>Breaking changes</h3>")
    print("<ul>")
    print_tasks(changelog["breaking"])
    print("</ul>")

if changelog["syntax"]:
    print("<h3>Configuration syntax changes (automatically migrated)</h3>")
    print("<ul>")
    print_tasks(changelog["syntax"])
    print("</ul>")

if changelog["features"]:
    print("<h3>New features and improvements")
    print("<ul>")
    print_tasks(changelog["features"])
    print("</ul>")

if changelog["fixes"]:
    print("<h3>Bug fixes</h3>")
    print("<ul>")
    print_tasks(changelog["fixes"])
    print("</ul>")

if changelog["misc"]:
    print("<h3>Other resolved issues</h3>")
    print("<ul>")
    print_tasks(changelog["misc"])
    print("</ul>")
