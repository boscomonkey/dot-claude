#!/usr/bin/env bash
# Assign a Linear issue to yourself and move it to "In Review".
#
# Usage: linear-ready.sh <ISSUE_ID> [STATE_ID]
#
# If STATE_ID is omitted, the script looks up the team's workflow states
# and finds one whose name matches "in review" (case-insensitive).
# If that lookup fails, it prints available started-type states and exits
# so you can re-run with an explicit STATE_ID.
#
# Prints {ticket, status, assignee} JSON on success.
#
# Requires env var: LINEAR_API_KEY

set -eo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $(basename "$0") <ISSUE_ID> [STATE_ID]" >&2
    exit 2
fi

issue_id="$1"
explicit_state_id="${2:-}"

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

gql() {
    curl -sS -X POST \
        -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$1" \
        https://api.linear.app/graphql
}

# Step 1: get viewer (current user) ID
viewer_response=$(gql '{"query":"query { viewer { id name } }"}')
if echo "$viewer_response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error fetching viewer:" >&2
    echo "$viewer_response" | jq '.errors' >&2
    exit 1
fi
viewer_id=$(echo "$viewer_response" | jq -r '.data.viewer.id')

# Step 2: get issue UUID and its team's workflow states
states_payload=$(jq -n \
    --arg id "$issue_id" \
    '{
        "query": "query IssueTeamStates($id: String!) { issue(id: $id) { id team { states { nodes { id name type } } } } }",
        "variables": {"id": $id}
    }')

states_response=$(gql "$states_payload")
if echo "$states_response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error fetching issue states:" >&2
    echo "$states_response" | jq '.errors' >&2
    exit 1
fi

issue_uuid=$(echo "$states_response" | jq -r '.data.issue.id')
if [[ "$issue_uuid" == "null" || -z "$issue_uuid" ]]; then
    echo "Error: issue $issue_id not found" >&2
    exit 1
fi

# Step 3: resolve state ID
if [[ -n "$explicit_state_id" ]]; then
    state_id="$explicit_state_id"
else
    state_id=$(echo "$states_response" | \
        jq -r '.data.issue.team.states.nodes[] | select(.name | ascii_downcase | contains("in review")) | .id' \
        | head -1)

    if [[ -z "$state_id" ]]; then
        echo "Error: no state matching 'in review' found for this issue's team." >&2
        echo "Available started-type states:" >&2
        echo "$states_response" | \
            jq -r '.data.issue.team.states.nodes[] | select(.type == "started") | "  \(.id)  \(.name)"' >&2
        echo "" >&2
        echo "Re-run with: $(basename "$0") $issue_id <STATE_ID>" >&2
        exit 1
    fi
fi

# Step 4: assign to self and move to the target state
update_payload=$(jq -n \
    --arg id "$issue_uuid" \
    --arg assigneeId "$viewer_id" \
    --arg stateId "$state_id" \
    '{
        "query": "mutation IssueUpdate($id: String!, $input: IssueUpdateInput!) { issueUpdate(id: $id, input: $input) { success issue { identifier state { name } assignee { name } } } }",
        "variables": {"id": $id, "input": {"assigneeId": $assigneeId, "stateId": $stateId}}
    }')

update_response=$(gql "$update_payload")
if echo "$update_response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error updating issue:" >&2
    echo "$update_response" | jq '.errors' >&2
    exit 1
fi

success=$(echo "$update_response" | jq -r '.data.issueUpdate.success')
if [[ "$success" != "true" ]]; then
    echo "Failed to update issue $issue_id" >&2
    echo "$update_response" >&2
    exit 1
fi

echo "$update_response" | jq --arg t "$issue_id" \
    '{ticket: $t, status: .data.issueUpdate.issue.state.name, assignee: .data.issueUpdate.issue.assignee.name}'
