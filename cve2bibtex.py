#!/usr/bin/env python3
#
# This script converts CVE 5.0 JSON format to BibTeX
# to make it easy to cite CVEs in LaTeX documents.
#
# It uses the BibLaTeX "@online" macro,
# although it's trivial to adjust to the classic @MISC of BibTeX, of course.
#
# Typical usage: curl https://cveawg.mitre.org/api/cve/CVE-2023-38408 | cve2bibtex
#
# Copyright (c) 2023 Daniil Baturin <daniil@baturin.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


import re
import sys
import json
import dateutil.parser

data = json.load(sys.stdin)

cve_id = data["cveMetadata"]["cveId"]

cve_date = dateutil.parser.isoparse(data["cveMetadata"]["datePublished"])
cve_year = cve_date.year
cve_month = cve_date.month

cve_url = f"https://www.cve.org/CVERecord?id={cve_id}"

# Find any English description
# The descriptions field is an array of {"lang": $code, "value": $desc} objects.
#
# In practice, all CVEs have one with {"lang": "en"},
# but the schema demands support for regional variants:
# https://github.com/CVEProject/cve-schema/blob/8994b0ac23f89d7b2c8d750500bc88400e4336d7/schema/v5.0/CVE_JSON_5.0_schema.json#L1027-L1031
for d in data["containers"]["cna"]["descriptions"]:
    if re.match(r'^en([_-][A-Za-z]{4})?([_-]([A-Za-z]{2}|[0-9]{3}))?$', d["lang"]):
        cve_desc = d["value"]

bibtex_tmpl = f"""
@online{{{cve_id},
  author = {{MITRE}},
  title = {{{cve_id}: {cve_desc}}},
  month = {cve_month}
  year = {cve_year},
  url = {{{cve_url}}},
}}
"""

print(bibtex_tmpl)
