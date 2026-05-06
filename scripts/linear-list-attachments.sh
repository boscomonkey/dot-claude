#!/usr/bin/env bash
# List attachments on a Linear issue.
#
# Usage: linear-list-attachments.sh <ISSUE_ID>
# Example: linear-list-attachments.sh ENG-123
#
# Prints: <id>: <title>  <url>
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
        "query": "query IssueAttachments($id: String!) { issue(id: $id) { attachments { nodes { id title url createdAt } } } }",
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

echo "$response" | python3 -c "
import sys, json
r = json.load(sys.stdin)
nodes = ((r.get('data') or {}).get('issue') or {}).get('attachments', {}).get('nodes') or []
if not nodes:
    print('(no attachments)')
else:
    for a in nodes:
        print(f'{a[\"id\"]}: {a[\"title\"]}  {a[\"url\"]}')
"
