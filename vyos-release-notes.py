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
#
#     Make sure to set a milestone tag and "Status: any closed status".
#  3. Take the query key part out of that URL
#  4. Go to https://phabricator.vyos.net/settings/user/<user>/page/apitokens/
#     and generate yourself a token. It goes to -t/--api-token
#  5. Now run vyos-release-notes.py -t <API key> -q <queryKey>
#
#  NB: Before you post release notes, check the "Other resolved issues" category.
#      A lot of time those issues tend to be un-categorized.

import re
import sys
import json
import copy
import urllib
import argparse

import jinja2
import urllib3

import ssl


ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

parser = argparse.ArgumentParser()
parser.add_argument("-q", "--query-key", type=str, help="Query key", required=True)
parser.add_argument("-t", "--api-token", type=str, help="API token", required=True)
parser.add_argument("-f", "--format", type=str, help="Output format", required=True)

args = parser.parse_args()

## Templates

# HTML template for blog posts
html_template = """
{% for category in changelog %}
{%- if category.tasks %}
<h3>{{category.name}}</h3>
<ul>
  {%- for t in category.tasks %}
  <li>{{t.fields.name}} (<a href="{{base_url}}/T{{t.id}}">T{{t.id}}</a>).</li>
  {%- endfor %}
</ul>
{%- endif %}
{% endfor %}
"""

# Phriction (Phabricator's wiki) for release notes
phriction_template = """
{% for category in changelog %}
{%- if category.tasks %}
**{{category.name}}**

{% for t in category.tasks %}
* {{t.fields.name}} (T{{t.id}}).
{%- endfor %}

{%- endif %}
{% endfor %}
"""

# reStructuredText for Sphinx docs
rst_template = """
{% for category in changelog %}
{%- if category.tasks %}
**{{category.name}}**

{% for t in category.tasks %}
- {{t.fields.name}} (T{{t.id}}).
{%- endfor %}

{%- endif %}
{% endfor %}
"""

ssl._create_default_https_context = ssl._create_unverified_context

phabricator_url = "https://vyos.dev"

def is_resolved(task):
    if task["fields"]["status"]["value"] in ["invalid", "wontfix"]:
        return False
    else:
        return True

def copy_tasks(ts, l, field, func):
    for t in ts:
        if func(t["fields"][field]):
            l.append(copy.copy(t))

# Retrieve the data
http = urllib3.PoolManager(assert_hostname=False, assert_fingerprint=False)
resp = http.request(
    "POST",
    f"{phabricator_url}/api/maniphest.search",
    body=urllib.parse.urlencode({'api.token': args.api_token, 'queryKey': args.query_key}).encode('ascii'),
    headers={"Content-Type": "application/x-www-form-urlencoded"})
resp = json.loads(resp.data)
data = resp["result"]["data"]

# Filter out tasks that were closed with a status other than "resolved",
# like "invalid" or "wontfix".
data = list(filter(is_resolved, data))

# Now categorize the tasks and prepare a changelog datastructure for rendering
vulnerabilities = []
breaking_changes = []
syntax_changes = []
features = []
fixes = []
misc = []

copy_tasks(data, vulnerabilities, "custom.issue-type", lambda x: x == "vulnerability")
copy_tasks(data, breaking_changes, "custom.breaking-change", lambda x: x == "syntax-incomp")
copy_tasks(data, syntax_changes, "custom.breaking-change", lambda x: x == "syntax")
copy_tasks(data, features, "custom.issue-type", lambda x: x in ["feature", "improvement"])
copy_tasks(data, fixes, "custom.issue-type", lambda x: x == "bug")
copy_tasks(data, misc, "custom.issue-type", lambda x: x not in ["feature", "improvement", "bug", "vulnerability"])

changelog = [
  {"name": "Security", "tasks": vulnerabilities},
  {"name": "Breaking changes", "tasks": breaking_changes},
  {"name": "Configuration syntax changes (automatically migrated)", "tasks": syntax_changes},
  {"name": "New features and improvements", "tasks": features},
  {"name": "Bug fixes", "tasks": fixes},
  {"name": "Other resolved issues", "tasks": misc}
]

for c in changelog:
    c["tasks"].sort(key=lambda x: x["id"])

# Render the changelog

if args.format == "html":
    tmpl = jinja2.Template(html_template)
elif args.format == "phriction":
    tmpl = jinja2.Template(phriction_template)
elif args.format == "rst":
    tmpl = jinja2.Template(rst_template)
else:
    print(f"""Unsupported output format "{args.format}" """)

print(tmpl.render({"changelog": changelog, "base_url": phabricator_url}))
