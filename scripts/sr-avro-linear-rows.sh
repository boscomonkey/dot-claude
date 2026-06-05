#!/usr/bin/env bash
#
# sr-avro-linear-rows.sh <LINEAR_PROJECT_ID> - emit a 2D JSON values array
# (header + rows) for the "Automated Overview" sheet tab, generated live from a
# Linear project's issues. Pure Linear -> rows (no Google creds); the caller
# writes the array to the sheet (gworkspace MCP) or via the Sheets API.
#
# Columns: Ticket(link), Title, Topic, Role, Format, Status, PR(link), Assignee, Updated
# Topic/Role/Format are read from `topic:`/`role:`/`format:` key:value labels;
# PR is the issue's linked GitHub pull-request attachment.
set -eo pipefail
PID="${1:?usage: sr-avro-linear-rows.sh <LINEAR_PROJECT_ID>}"

~/.claude/scripts/linear-graphql.sh "query { project(id: \"$PID\") { issues(first: 250) { nodes { identifier title url state { name } assignee { displayName } updatedAt labels { nodes { name } } attachments { nodes { url } } } } } }" \
| python3 -c '
import sys, json
nodes = json.load(sys.stdin)["data"]["project"]["issues"]["nodes"]
def lab(labels, pfx):
    for l in labels:
        if l["name"].startswith(pfx):
            return l["name"][len(pfx):]
    return ""
def hl(url, text):
    return "=HYPERLINK(\"%s\",\"%s\")" % (url, str(text).replace(chr(34), chr(39)))
recs = []
for n in nodes:
    labels = n.get("labels", {}).get("nodes", [])
    topic, role, fmt = lab(labels, "topic:"), lab(labels, "role:"), lab(labels, "format:")
    pr = ""
    for a in n.get("attachments", {}).get("nodes", []):
        u = a.get("url", "")
        if "github.com" in u and "/pull/" in u:
            pr = u; break
    recs.append((topic, n["identifier"], n, role, fmt, pr))
recs.sort(key=lambda r: (r[0], r[1]))
rows = [["Ticket","Title","Topic","Role","Format","Status","PR","Assignee","Updated"]]
for topic, ident, n, role, fmt, pr in recs:
    rows.append([
        hl(n["url"], ident),
        n.get("title",""),
        topic, role, fmt,
        (n.get("state") or {}).get("name",""),
        hl(pr, "PR") if pr else "",
        (n.get("assignee") or {}).get("displayName",""),
        (n.get("updatedAt") or "")[:10],
    ])
print(json.dumps(rows))
'
