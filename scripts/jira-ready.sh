#!/usr/bin/env bash
# Mark a JIRA ticket as ready for review: assign to the current user
# and transition to "In Review".
#
# Usage: jira-ready.sh <TICKET_KEY> [ACCOUNT_ID] [TRANSITION_ID]
#
# Defaults (read from env; see ~/.nocommit_profile):
#   ACCOUNT_ID     = $JIRA_ACCOUNT_ID
#   TRANSITION_ID  = $JIRA_IN_REVIEW_TRANSITION_ID (default: 51)
#
# To find the right TRANSITION_ID for a different project/issue type:
#   curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
#     "${JIRA_BASE_URL}/rest/api/3/issue/<key>/transitions" | jq '.transitions'
#
# Requires env vars:
#   JIRA_USERNAME    - JIRA account email
#   JIRA_API_TOKEN   - JIRA API token
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -eo pipefail

if [[ $# -lt 1 || $# -gt 3 ]]; then
    echo "Usage: $(basename "$0") <TICKET_KEY> [ACCOUNT_ID] [TRANSITION_ID]" >&2
    exit 2
fi

ticket="$1"
account_id="${2:-${JIRA_ACCOUNT_ID:?JIRA_ACCOUNT_ID must be set (see ~/.nocommit_profile)}}"
transition_id="${3:-${JIRA_IN_REVIEW_TRANSITION_ID:-51}}"

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

auth="${JIRA_USERNAME}:${JIRA_API_TOKEN}"

# Assignee: PUT /issue/<key>/assignee returns 204 on success.
assign_code="$(
    curl -sS -o /dev/null -w "%{http_code}" \
        -X PUT -u "$auth" \
        -H "Content-Type: application/json" \
        -d "{\"accountId\": \"${account_id}\"}" \
        "${base_url}/rest/api/3/issue/${ticket}/assignee"
)"
if [[ "$assign_code" != "204" ]]; then
    echo "Failed to assign ${ticket} (HTTP ${assign_code})" >&2
    exit 1
fi

# Transition: POST /issue/<key>/transitions returns 204 on success.
transition_code="$(
    curl -sS -o /dev/null -w "%{http_code}" \
        -X POST -u "$auth" \
        -H "Content-Type: application/json" \
        -d "{\"transition\": {\"id\": \"${transition_id}\"}}" \
        "${base_url}/rest/api/3/issue/${ticket}/transitions"
)"
if [[ "$transition_code" != "204" ]]; then
    echo "Failed to transition ${ticket} (HTTP ${transition_code})" >&2
    exit 1
fi

# Verify + print.
curl -sS -u "$auth" "${base_url}/rest/api/3/issue/${ticket}?fields=status,assignee" \
    | jq --arg t "$ticket" '{ticket: $t, status: .fields.status.name, assignee: .fields.assignee.displayName}'
