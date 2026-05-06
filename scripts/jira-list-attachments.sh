#!/usr/bin/env bash
# List attachments on a JIRA issue.
#
# Usage: jira-list-attachments.sh <TICKET_KEY>
# Example: jira-list-attachments.sh PROJ-1234
#
# Prints: <id>: <filename> (<size>b)
#
# Requires env vars:
#   JIRA_USERNAME    - JIRA account email
#   JIRA_API_TOKEN   - JIRA API token
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <TICKET_KEY>" >&2
    echo "Example: $(basename "$0") PROJ-1234" >&2
    exit 2
fi

ticket="$1"

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
    "${base_url}/rest/api/3/issue/${ticket}?fields=attachment" \
    | python3 -c "
import sys, json
r = json.load(sys.stdin)
attachments = (r.get('fields') or {}).get('attachment') or []
if not attachments:
    print('(no attachments)')
else:
    for a in attachments:
        print(f'{a[\"id\"]}: {a[\"filename\"]} ({a[\"size\"]}b)')
"
