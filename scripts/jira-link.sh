#!/usr/bin/env bash
# Create a JIRA issue link between two tickets.
#
# Usage: jira-link.sh <FROM_KEY> <LINK_TYPE> <TO_KEY>
#
# Examples:
#   jira-link.sh PROJ-100 "Relates" PROJ-200
#   jira-link.sh PROJ-100 "Blocks" PROJ-200
#   jira-link.sh PROJ-100 "Duplicate" PROJ-99
#
# FROM_KEY is the inward issue, TO_KEY is the outward issue.
# For symmetric types like "Relates" the direction doesn't matter.
#
# Common link type names (case-sensitive):
#   Relates, Blocks, Duplicate, Dependency, Problem/Incident
#
# Exits 0 on success (HTTP 201), non-zero on failure.
#
# Requires env vars: JIRA_USERNAME, JIRA_API_TOKEN, JIRA_BASE_URL

set -eo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $(basename "$0") <FROM_KEY> <LINK_TYPE> <TO_KEY>" >&2
    echo "Example: $(basename "$0") PROJ-100 Relates PROJ-200" >&2
    exit 2
fi

from_key="$1"
link_type="$2"
to_key="$3"

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

payload=$(jq -n \
    --arg type "$link_type" \
    --arg inward "$from_key" \
    --arg outward "$to_key" \
    '{"type":{"name":$type},"inwardIssue":{"key":$inward},"outwardIssue":{"key":$outward}}')

http_code=$(curl -sS -X POST -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${base_url}/rest/api/3/issueLink" \
    -d "$payload" \
    -o /tmp/jira-link-response.json \
    -w "%{http_code}")

if [[ "$http_code" == "201" ]]; then
    echo "${from_key} -[${link_type}]-> ${to_key}: OK"
else
    echo "Failed (HTTP ${http_code})" >&2
    cat /tmp/jira-link-response.json >&2
    exit 1
fi
