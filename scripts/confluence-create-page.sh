#!/usr/bin/env bash
# Create a new Confluence page under a given parent (folder or page).
#
# Usage: confluence-create-page.sh <PARENT_ID> <TITLE> <STORAGE_XHTML_FILE>
# Example: confluence-create-page.sh 2485420082 "My new page" tmp/page.storage.xhtml
#
# The parent can be a folder OR a page; the script auto-detects which and
# resolves the parent's spaceId.
#
# Prints {id, title, webui} as JSON on success (HTTP 200).
#
# Requires env vars:
#   JIRA_USERNAME    - Atlassian account email
#   JIRA_API_TOKEN   - Atlassian API token (Confluence shares JIRA tokens)
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -eo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $(basename "$0") <PARENT_ID> <TITLE> <STORAGE_XHTML_FILE>" >&2
    exit 2
fi

parent_id="$1"
title="$2"
storage_file="$3"

if [[ ! -f "$storage_file" ]]; then
    echo "Error: storage file not found: $storage_file" >&2
    exit 1
fi

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

# Resolve spaceId from parent. Try folder first, fall back to page.
space_id="$(
    curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
         -H "Accept: application/json" \
         "${base_url}/wiki/api/v2/folders/${parent_id}" 2>/dev/null \
    | jq -r '.spaceId // empty'
)"

if [[ -z "$space_id" ]]; then
    space_id="$(
        curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
             -H "Accept: application/json" \
             "${base_url}/wiki/api/v2/pages/${parent_id}" 2>/dev/null \
        | jq -r '.spaceId // empty'
    )"
fi

if [[ -z "$space_id" ]]; then
    echo "Error: could not resolve spaceId for parent ${parent_id}" >&2
    echo "Parent must be an existing folder or page; check the ID and your auth." >&2
    exit 1
fi

# Build the request body via jq so the storage XHTML is JSON-encoded safely.
payload_file="$(mktemp -t confluence-create.XXXXXX.json)"
response_file="$(mktemp -t confluence-create-resp.XXXXXX.json)"
trap 'rm -f "$payload_file" "$response_file"' EXIT

jq -n \
    --arg spaceId "$space_id" \
    --arg parentId "$parent_id" \
    --arg title "$title" \
    --rawfile body "$storage_file" \
    '{spaceId: $spaceId, status: "current", title: $title, parentId: $parentId, body: {representation: "storage", value: $body}}' \
    > "$payload_file"

http_code="$(
    curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -X POST "${base_url}/wiki/api/v2/pages" \
        --data @"$payload_file" \
        -o "$response_file" \
        -w "%{http_code}"
)"

if [[ "$http_code" != "200" ]]; then
    echo "Failed to create page (HTTP ${http_code})" >&2
    cat "$response_file" >&2
    exit 1
fi

jq '{id, title, status, spaceId, parentId, parentType, webui: (._links.base + ._links.webui)}' "$response_file"
