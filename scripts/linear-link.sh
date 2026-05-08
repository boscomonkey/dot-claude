#!/usr/bin/env bash
# Create a relation between two Linear issues.
#
# Usage: linear-link.sh <FROM_ID> <RELATION_TYPE> <TO_ID>
#
# Examples:
#   linear-link.sh ENG-123 blocks ENG-456
#   linear-link.sh ENG-100 related ENG-200
#   linear-link.sh ENG-100 duplicate ENG-99
#
# Relation types: related, blocks, blocked_by, duplicate
#
# FROM_ID is the source issue; for "blocks", FROM_ID blocks TO_ID.
# Exits 0 on success, non-zero on failure.
#
# Requires env var: LINEAR_API_KEY

set -eo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $(basename "$0") <FROM_ID> <RELATION_TYPE> <TO_ID>" >&2
    echo "Example: $(basename "$0") ENG-123 blocks ENG-456" >&2
    echo "Types: related, blocks, blocked_by, duplicate" >&2
    exit 2
fi

from_id="$1"
relation_type="$2"
to_id="$3"

# Linear's IssueRelationType enum has `blocks` but no `blocked_by`. Convert
# `<A> blocked_by <B>` to the equivalent `<B> blocks <A>` so callers can use
# whichever direction reads naturally for their use case.
if [[ "$relation_type" == "blocked_by" ]]; then
    tmp="$from_id"
    from_id="$to_id"
    to_id="$tmp"
    relation_type="blocks"
fi

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

gql() {
    curl -sS -X POST \
        -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$1" \
        https://api.linear.app/graphql
}

# Resolve both identifiers to UUIDs (issueRelationCreate requires UUIDs)
resolve_payload=$(jq -n \
    --arg from "$from_id" \
    --arg to "$to_id" \
    '{
        "query": "query ResolveIssues($from: String!, $to: String!) { from: issue(id: $from) { id identifier } to: issue(id: $to) { id identifier } }",
        "variables": {"from": $from, "to": $to}
    }')

resolve_response=$(gql "$resolve_payload")
if echo "$resolve_response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error resolving issue IDs:" >&2
    echo "$resolve_response" | jq '.errors' >&2
    exit 1
fi

from_uuid=$(echo "$resolve_response" | jq -r '.data.from.id')
to_uuid=$(echo "$resolve_response" | jq -r '.data.to.id')

if [[ "$from_uuid" == "null" || -z "$from_uuid" ]]; then
    echo "Error: could not find issue $from_id" >&2
    exit 1
fi
if [[ "$to_uuid" == "null" || -z "$to_uuid" ]]; then
    echo "Error: could not find issue $to_id" >&2
    exit 1
fi

payload=$(jq -n \
    --arg issueId "$from_uuid" \
    --arg relatedIssueId "$to_uuid" \
    --arg type "$relation_type" \
    '{
        "query": "mutation RelationCreate($input: IssueRelationCreateInput!) { issueRelationCreate(input: $input) { success issueRelation { id type } } }",
        "variables": {"input": {"issueId": $issueId, "relatedIssueId": $relatedIssueId, "type": $type}}
    }')

response=$(gql "$payload")
if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error creating relation:" >&2
    echo "$response" | jq '.errors' >&2
    exit 1
fi

success=$(echo "$response" | jq -r '.data.issueRelationCreate.success')
if [[ "$success" != "true" ]]; then
    echo "Failed to create relation" >&2
    echo "$response" >&2
    exit 1
fi

echo "${from_id} -[${relation_type}]-> ${to_id}: OK"
