#!/usr/bin/env bash
# Update a Linear issue's fields from a JSON file.
#
# Usage: linear-update.sh <ISSUE_ID> <JSON_FILE>
# Example: linear-update.sh ENG-123 tmp/linear-update-ENG-123.json
#
# ISSUE_ID can be a UUID or a team-prefixed identifier (e.g. ENG-123).
#
# The JSON file must contain IssueUpdateInput fields, e.g.:
#   { "title": "New title", "description": "markdown" }
#
# Requires env var: LINEAR_API_KEY

set -eo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <ISSUE_ID> <JSON_FILE>" >&2
    echo "Example: $(basename "$0") ENG-123 tmp/linear-update-ENG-123.json" >&2
    exit 2
fi

issue_id="$1"
json_file="$2"

if [[ ! -f "$json_file" ]]; then
    echo "Error: JSON file not found: $json_file" >&2
    exit 1
fi

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

input=$(cat "$json_file")

payload=$(jq -n \
    --arg id "$issue_id" \
    --argjson input "$input" \
    '{
        "query": "mutation IssueUpdate($id: String!, $input: IssueUpdateInput!) { issueUpdate(id: $id, input: $input) { success issue { id identifier url } } }",
        "variables": {"id": $id, "input": $input}
    }')

response=$(curl -sS -X POST \
    -H "Authorization: $LINEAR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    https://api.linear.app/graphql)

if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error updating issue:" >&2
    echo "$response" | jq '.errors' >&2
    exit 1
fi

success=$(echo "$response" | jq -r '.data.issueUpdate.success')
if [[ "$success" != "true" ]]; then
    echo "Failed to update issue $issue_id" >&2
    echo "$response" >&2
    exit 1
fi

echo "$response" | jq '.data.issueUpdate.issue'
