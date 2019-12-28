#!/usr/bin/env python3

# Retrieves release notes from Phabricator
# Usage:
#  1. Go to https://phabricator.example.com/maniphest/
#  2. Fill the search form and run "Search". You will be redirected to a URL like
#     https://phabricator.example.com/maniphest/query/<queryKey>/#R
#     Copy the <queryKey> part. That will be your -q/--query-key argument
#  3. Take the query key part out of that URL
#  4. Go to https://phabricator.example.com/settings/user/<user>/page/apitokens/
#     and generate yourself a token. It goes to -t/--api-token
#  5. Now run phabricator-relnotes.py -t <API key> -q queryKey https://phabricator.example.com

import sys
import json
import argparse
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument("-q", "--query-key", type=str, help="Query key", required=True)
parser.add_argument("-t", "--api-token", type=str, help="API token", required=True)
parser.add_argument("-f", "--format", type=str, default="html", help="Output format (html, rst, md, or plain)")
parser.add_argument("phabricator_url", type=str, help="Phabricator URL")

args = parser.parse_args()

## Templates
template_html = """<tr>
  <td><a href="{base_url}/T{id}">{id}</a></td>
  <td>{title}</td>
</tr>"""

template_plain = "T{id}\t{title}"

template_rst = "* `T{id} <{base_url}/T{id}>`_ {title}"

template_md = "* [T{id}]({base_url}/T{id}) {title}"

if args.format == 'html':
    template = template_html
elif args.format == 'rst':
    template = template_rst
elif args.format == 'md':
    template = template_md
else:
    template = template_plain

# Do the deed
query_url = "{0}/api/maniphest.search".format(args.phabricator_url)
request_data = urllib.parse.urlencode({'api.token': args.api_token, 'queryKey': args.query_key}).encode('ascii')
with urllib.request.urlopen(query_url, request_data) as f:
    resp = json.load(f)
    data = resp["result"]["data"]

for t in data:
  print(template.format(id=t["id"], title=t["fields"]["name"], base_url=args.phabricator_url))
