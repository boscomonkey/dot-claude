#!/usr/bin/env bash
# Delete a JIRA attachment by attachment ID.
#
# Usage: jira-delete-attachment.sh <ATTACHMENT_ID>
# Example: jira-delete-attachment.sh 251379
#
# The attachment ID is returned by jira-attach.sh in the "id" field,
# or can be found via the JIRA issue attachments API.
#
# Requires env vars:
#   JIRA_USERNAME    - JIRA account email
#   JIRA_API_TOKEN   - JIRA API token
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <ATTACHMENT_ID>" >&2
    echo "Example: $(basename "$0") 251379" >&2
    exit 2
fi

attachment_id="$1"

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

http_code=$(curl -sS -o /dev/null -w "%{http_code}" -X DELETE \
    -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
    "${base_url}/rest/api/3/attachment/${attachment_id}")

if [[ "$http_code" == "204" ]]; then
    echo "deleted attachment ${attachment_id}"
else
    echo "Error: DELETE returned HTTP ${http_code}" >&2
    exit 1
fi
