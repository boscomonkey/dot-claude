#!/usr/bin/env bash
# Execute an arbitrary Linear GraphQL query or mutation against
# https://api.linear.app/graphql.
#
# Usage:
#   linear-graphql.sh <GRAPHQL_QUERY> [<VARIABLES_JSON>]
#
# Examples:
#   linear-graphql.sh '{ viewer { id name email } }'
#
#   linear-graphql.sh '{ projects(filter: {slugId: {eq: "abc123"}}) { nodes { id name } } }'
#
#   linear-graphql.sh \
#     'query($id: String!) { issue(id: $id) { identifier title } }' \
#     '{"id":"ENG-123"}'
#
# The query is taken verbatim as a string; jq safely embeds it into the
# JSON request body, so the caller does not need to escape quotes.
#
# Output: raw JSON response from Linear (pipe through jq for formatting).
#
# Requires env var:
#   LINEAR_API_KEY - personal API key from Linear settings
#                    (Authorization header is sent verbatim, no Bearer prefix)

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $(basename "$0") <GRAPHQL_QUERY> [<VARIABLES_JSON>]" >&2
    echo "Example: $(basename "$0") '{ viewer { id name } }'" >&2
    exit 2
fi

query="$1"
variables="${2:-}"

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

if [[ -n "$variables" ]]; then
    body=$(jq -n --arg q "$query" --argjson v "$variables" '{query: $q, variables: $v}')
else
    body=$(jq -n --arg q "$query" '{query: $q}')
fi

curl -sS -X POST \
    -H "Authorization: ${LINEAR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    https://api.linear.app/graphql
