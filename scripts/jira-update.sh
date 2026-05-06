#!/usr/bin/env bash
# Update a JIRA issue's fields from a JSON file.
#
# Usage: jira-update.sh <TICKET_KEY> <JSON_FILE>
# Example: jira-update.sh PROJ-1234 tmp/jira-update-PROJ-1234.json
#
# The JSON file must contain the full request body, e.g.:
#   { "fields": { "summary": "New title", "description": { ADF... } } }
#
# This is a thin wrapper around:
#   PUT /rest/api/3/issue/<key>   (JIRA Cloud REST v3)
#
# Requires env vars:
#   JIRA_USERNAME    - JIRA account email
#   JIRA_API_TOKEN   - JIRA API token
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -eo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <TICKET_KEY> <JSON_FILE>" >&2
    echo "Example: $(basename "$0") PROJ-1234 tmp/jira-update-PROJ-1234.json" >&2
    exit 2
fi

ticket="$1"
json_file="$2"

if [[ ! -f "$json_file" ]]; then
    echo "Error: JSON file not found: $json_file" >&2
    exit 1
fi

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

# JIRA returns an empty body on success, non-empty JSON error body on failure.
# -w "%{http_code}" prints the status to stdout after the body so we can assert.
response="$(
    curl -sS -X PUT \
        -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "@${json_file}" \
        -w "\n%{http_code}" \
        "${base_url}/rest/api/3/issue/${ticket}"
)"

http_code="${response##*$'\n'}"
body="${response%$'\n'*}"

if [[ "$http_code" == "204" ]]; then
    echo "Updated ${ticket} (HTTP 204)"
    exit 0
fi

echo "Failed to update ${ticket} (HTTP ${http_code})" >&2
if [[ -n "$body" ]]; then
    echo "$body" >&2
fi
exit 1
