#!/usr/bin/env bash
# Attach a file to a JIRA issue.
#
# Usage: jira-attach.sh <TICKET_KEY> <FILE_PATH>
# Example: jira-attach.sh PROJ-1234 tmp/session-continuation.md
#
# Requires env vars:
#   JIRA_USERNAME    - JIRA account email
#   JIRA_API_TOKEN   - JIRA API token (https://id.atlassian.com/manage-profile/security/api-tokens)
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <TICKET_KEY> <FILE_PATH>" >&2
    echo "Example: $(basename "$0") PROJ-1234 tmp/session-continuation.md" >&2
    exit 2
fi

ticket="$1"
file="$2"

if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file" >&2
    exit 1
fi

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

# Resolve to absolute path so curl's file=@ works regardless of cwd.
abs_file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"

curl -sS -X POST \
    -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
    -H "X-Atlassian-Token: no-check" \
    -F "file=@${abs_file}" \
    "${base_url}/rest/api/3/issue/${ticket}/attachments" \
    | jq '.[] | {id, filename, size}'
