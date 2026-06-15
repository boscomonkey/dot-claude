#!/usr/bin/env bash
# Rename a Linear label (issueLabelUpdate). The label's id is unchanged, so every
# issue already carrying it keeps the label under the new name.
#
# Usage: linear-rename-label.sh <LABEL> <NEW_NAME> [TEAM_KEY]
#
# Examples:
#   linear-rename-label.sh ticket-type:producer-migration change:producer-migration
#   linear-rename-label.sh ticket-type:tooling change:tooling SEP
#   linear-rename-label.sh fee73e55-4a61-42eb-9f12-6e97bfb8046e change:tooling
#
#   <LABEL>     current label UUID, or current label name
#   <NEW_NAME>  the new label name
#   [TEAM_KEY]  optional team key (e.g. SEP) to disambiguate a current name that
#               exists on more than one team
#
# Resolves the label UUID (when a name is given) via the Linear GraphQL API,
# then runs issueLabelUpdate. Exits 0 on success.
#
# Requires env var: LINEAR_API_KEY

set -eo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $(basename "$0") <LABEL> <NEW_NAME> [TEAM_KEY]" >&2
    echo "Example: $(basename "$0") ticket-type:tooling change:tooling" >&2
    exit 2
fi

label="$1"
new_name="$2"
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

# --- rename -----------------------------------------------------------------
update_payload=$(jq -n --arg id "$label_uuid" --arg name "$new_name" \
    '{"query":"mutation U($id:String!,$name:String!){ issueLabelUpdate(id:$id, input:{name:$name}){ success issueLabel{ id name team{ key } } } }","variables":{"id":$id,"name":$name}}')
update_response=$(gql "$update_payload")
if echo "$update_response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error renaming label:" >&2
    echo "$update_response" | jq '.errors' >&2
    exit 1
fi

success=$(echo "$update_response" | jq -r '.data.issueLabelUpdate.success')
if [[ "$success" != "true" ]]; then
    echo "Failed to rename label" >&2
    echo "$update_response" >&2
    exit 1
fi

team=$(echo "$update_response" | jq -r '.data.issueLabelUpdate.issueLabel.team.key')
echo "renamed label ${label_uuid} -> '${new_name}' (team ${team}): OK"
