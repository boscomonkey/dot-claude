#!/usr/bin/env bash
# Fetch a Linear issue and print its details.
#
# Usage: linear-get.sh <ISSUE_ID>
# Example: linear-get.sh ENG-123
#
# ISSUE_ID can be a UUID or a team-prefixed identifier (e.g. ENG-123).
# Prints title, state, assignee, labels, description, and relations.
#
# Requires env var: LINEAR_API_KEY

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <ISSUE_ID>" >&2
    echo "Example: $(basename "$0") ENG-123" >&2
    exit 2
fi

issue_id="$1"

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

payload=$(jq -n \
    --arg id "$issue_id" \
    '{
        "query": "query GetIssue($id: String!) { issue(id: $id) { id identifier title description priority state { name } assignee { name email } team { name key } labels { nodes { name } } parent { identifier title } relations { nodes { type relatedIssue { identifier title } } } createdAt updatedAt url } }",
        "variables": {"id": $id}
    }')

response=$(curl -sS -X POST \
    -H "Authorization: $LINEAR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    https://api.linear.app/graphql)

if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error:" >&2
    echo "$response" | jq '.errors' >&2
    exit 1
fi

if [[ "$(echo "$response" | jq -r '.data.issue')" == "null" ]]; then
    echo "Error: issue $issue_id not found" >&2
    exit 1
fi

_LINEAR_DATA="$response" python3 << 'PYEOF'
import json, os
r = json.loads(os.environ["_LINEAR_DATA"])
i = r["data"]["issue"]

print(f'=== {i["identifier"]}: {i["title"]} ===')
print(f'URL:      {i["url"]}')
print(f'State:    {i["state"]["name"]}')
assignee = (i["assignee"] or {}).get("name", "(unassigned)")
print(f'Assignee: {assignee}')
labels = [l["name"] for l in i["labels"]["nodes"]]
labels_str = ", ".join(labels) if labels else "(none)"
print(f'Labels:   {labels_str}')
if i.get("parent"):
    p = i["parent"]
    print(f'Parent:   {p["identifier"]}: {p["title"]}')
relations = (i.get("relations") or {}).get("nodes") or []
if relations:
    print("Relations:")
    for rel in relations:
        ri = rel["relatedIssue"]
        print(f'  [{rel["type"]}] {ri["identifier"]}: {ri["title"]}')
print()
print("--- Description ---")
print(i.get("description") or "(no description)")
PYEOF
