#!/usr/bin/env bash
# Add a label to a Linear issue, additively (does NOT touch the issue's other
# labels - uses the issueAddLabel mutation, not a full labelIds replace).
#
# Usage: linear-add-label.sh <ISSUE_ID> <LABEL> [TEAM_KEY]
#
# Examples:
#   linear-add-label.sh SEP-653 ticket-type:producer-migration
#   linear-add-label.sh SEP-653 ticket-type:producer-migration SEP
#   linear-add-label.sh SEP-653 17e37408-1b07-41a7-911c-5ed94564607a
#
#   <ISSUE_ID>  issue identifier (e.g. SEP-653) or UUID
#   <LABEL>     label UUID, or label name (e.g. "ticket-type:producer-migration")
#   [TEAM_KEY]  optional team key (e.g. SEP) to disambiguate a label name that
#               exists on more than one team
#
# Resolves the issue UUID and (when a name is given) the label UUID via the
# Linear GraphQL API, then runs issueAddLabel. Exits 0 on success.
#
# Requires env var: LINEAR_API_KEY

set -eo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $(basename "$0") <ISSUE_ID> <LABEL> [TEAM_KEY]" >&2
    echo "Example: $(basename "$0") SEP-653 ticket-type:producer-migration" >&2
    exit 2
fi

issue_id="$1"
label="$2"
team_key="${3:-}"

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

gql() {
    curl -sS -X POST \
        -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$1" \
        https://api.linear.app/graphql
}

uuid_re='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

# --- resolve the label UUID -------------------------------------------------
if [[ "$label" =~ $uuid_re ]]; then
    label_uuid="$label"
else
    label_payload=$(jq -n --arg n "$label" \
        '{"query":"query L($n:String!){ issueLabels(filter:{name:{eq:$n}}, first:50){ nodes{ id name team{ key } } } }","variables":{"n":$n}}')
    label_response=$(gql "$label_payload")
    if echo "$label_response" | jq -e '.errors' > /dev/null 2>&1; then
        echo "Error looking up label '$label':" >&2
        echo "$label_response" | jq '.errors' >&2
        exit 1
    fi

    if [[ -n "$team_key" ]]; then
        nodes=$(echo "$label_response" | jq --arg t "$team_key" '[.data.issueLabels.nodes[] | select(.team.key == $t)]')
    else
        nodes=$(echo "$label_response" | jq '.data.issueLabels.nodes')
    fi

    count=$(echo "$nodes" | jq 'length')
    if [[ "$count" -eq 0 ]]; then
        echo "Error: no label named '$label'${team_key:+ on team $team_key}" >&2
        exit 1
    elif [[ "$count" -gt 1 ]]; then
        echo "Error: label name '$label' is ambiguous - matches multiple teams; pass a TEAM_KEY:" >&2
        echo "$nodes" | jq -r '.[] | "  \(.team.key): \(.id)"' >&2
        exit 1
    fi
    label_uuid=$(echo "$nodes" | jq -r '.[0].id')
fi

# --- resolve the issue UUID -------------------------------------------------
issue_payload=$(jq -n --arg id "$issue_id" \
    '{"query":"query I($id:String!){ issue(id:$id){ id identifier } }","variables":{"id":$id}}')
issue_response=$(gql "$issue_payload")
issue_uuid=$(echo "$issue_response" | jq -r '.data.issue.id // empty')
if [[ -z "$issue_uuid" ]]; then
    echo "Error: could not find issue $issue_id" >&2
    echo "$issue_response" | jq '.errors // .' >&2
    exit 1
fi

# --- add the label (additive) ----------------------------------------------
add_payload=$(jq -n --arg id "$issue_uuid" --arg labelId "$label_uuid" \
    '{"query":"mutation A($id:String!,$labelId:String!){ issueAddLabel(id:$id, labelId:$labelId){ success } }","variables":{"id":$id,"labelId":$labelId}}')
add_response=$(gql "$add_payload")
if echo "$add_response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error adding label:" >&2
    echo "$add_response" | jq '.errors' >&2
    exit 1
fi

success=$(echo "$add_response" | jq -r '.data.issueAddLabel.success')
if [[ "$success" != "true" ]]; then
    echo "Failed to add label" >&2
    echo "$add_response" >&2
    exit 1
fi

echo "${issue_id} += label '${label}' (${label_uuid}): OK"
