#!/usr/bin/env bash
# Create a Linear issue from a JSON file.
#
# Usage: linear-create.sh <JSON_FILE>
# Example: linear-create.sh tmp/linear-create-my-issue.json
#
# The JSON file must contain IssueCreateInput fields, e.g.:
#   {
#     "teamId": "...",
#     "title": "...",
#     "description": "markdown text",
#     "stateId": "...",
#     "assigneeId": "...",
#     "priority": 2
#   }
#
# On success, prints {id, identifier, url}.
#
# Requires env var: LINEAR_API_KEY

set -eo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <JSON_FILE>" >&2
    echo "Example: $(basename "$0") tmp/linear-create-my-issue.json" >&2
    exit 2
fi

json_file="$1"

if [[ ! -f "$json_file" ]]; then
    echo "Error: JSON file not found: $json_file" >&2
    exit 1
fi

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

input=$(cat "$json_file")

payload=$(jq -n \
    --argjson input "$input" \
    '{
        "query": "mutation IssueCreate($input: IssueCreateInput!) { issueCreate(input: $input) { success issue { id identifier url } } }",
        "variables": {"input": $input}
    }')

response=$(curl -sS -X POST \
    -H "Authorization: $LINEAR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    https://api.linear.app/graphql)

if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error creating issue:" >&2
    echo "$response" | jq '.errors' >&2
    exit 1
fi

success=$(echo "$response" | jq -r '.data.issueCreate.success')
if [[ "$success" != "true" ]]; then
    echo "Failed to create issue" >&2
    echo "$response" >&2
    exit 1
fi

echo "$response" | jq '.data.issueCreate.issue'
