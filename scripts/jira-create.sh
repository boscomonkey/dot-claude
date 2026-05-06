#!/usr/bin/env bash
# Create a JIRA issue from a JSON file.
#
# Usage: jira-create.sh <JSON_FILE>
# Example: jira-create.sh tmp/jira-create-PROJ-1234.json
#
# The JSON file must contain the full request body, e.g.:
#   {
#     "fields": {
#       "project": {"key": "PROJ"},
#       "summary": "...",
#       "issuetype": {"name": "Task"},
#       "parent": {"key": "PROJ-100"},
#       "description": { ADF... }
#     }
#   }
#
# On success, prints the created issue key (e.g. PROJ-1234) to stdout.
#
# This is a thin wrapper around:
#   POST /rest/api/3/issue   (JIRA Cloud REST v3)
#
# Requires env vars:
#   JIRA_USERNAME    - JIRA account email
#   JIRA_API_TOKEN   - JIRA API token
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -eo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <JSON_FILE>" >&2
    echo "Example: $(basename "$0") tmp/jira-create-my-ticket.json" >&2
    exit 2
fi

json_file="$1"

if [[ ! -f "$json_file" ]]; then
    echo "Error: JSON file not found: $json_file" >&2
    exit 1
fi

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

response="$(
    curl -sS -X POST \
        -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "@${json_file}" \
        -w "\n%{http_code}" \
        "${base_url}/rest/api/3/issue"
)"

http_code="${response##*$'\n'}"
body="${response%$'\n'*}"

if [[ "$http_code" == "201" ]]; then
    echo "$body" | jq '{id, key, self}'
    exit 0
fi

echo "Failed to create issue (HTTP ${http_code})" >&2
if [[ -n "$body" ]]; then
    echo "$body" >&2
fi
exit 1
