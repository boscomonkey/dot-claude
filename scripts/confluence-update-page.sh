#!/usr/bin/env bash
# Update an existing Confluence page with new content.
#
# Usage: confluence-update-page.sh <PAGE_ID> <TITLE> <STORAGE_XHTML_FILE> [VERSION_COMMENT]
# Example: confluence-update-page.sh 2501705773 "My page title" tmp/page.storage.xhtml "Update SEP statuses"
#
# Auto-fetches the current version number and increments it. The optional
# VERSION_COMMENT is recorded as the edit message on the new version, so
# Confluence's native page history is self-describing (preferred over an
# in-doc version-history table for Confluence-hosted docs).
#
# Prints {id, title, status, version} as JSON on success (HTTP 200).
#
# Requires env vars:
#   JIRA_USERNAME    - Atlassian account email
#   JIRA_API_TOKEN   - Atlassian API token (Confluence shares JIRA tokens)
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -eo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
    echo "Usage: $(basename "$0") <PAGE_ID> <TITLE> <STORAGE_XHTML_FILE> [VERSION_COMMENT]" >&2
    exit 2
fi

page_id="$1"
title="$2"
storage_file="$3"
version_comment="${4:-}"

if [[ ! -f "$storage_file" ]]; then
    echo "Error: storage file not found: $storage_file" >&2
    exit 1
fi

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

# Fetch current version number.
current_version="$(
    curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
         -H "Accept: application/json" \
         "${base_url}/wiki/api/v2/pages/${page_id}" \
    | jq -r '.version.number // empty'
)"

if [[ -z "$current_version" ]]; then
    echo "Error: could not fetch page ${page_id} — check the ID and your auth." >&2
    exit 1
fi

next_version=$(( current_version + 1 ))

payload_file="$(mktemp -t confluence-update.XXXXXX.json)"
response_file="$(mktemp -t confluence-update-resp.XXXXXX.json)"
trap 'rm -f "$payload_file" "$response_file"' EXIT

jq -n \
    --arg id "$page_id" \
    --arg title "$title" \
    --argjson version "$next_version" \
    --arg msg "$version_comment" \
    --rawfile body "$storage_file" \
    '{
      id: $id,
      status: "current",
      title: $title,
      version: ({ number: $version } + (if $msg == "" then {} else { message: $msg } end)),
      body: { representation: "storage", value: $body }
    }' \
    > "$payload_file"

http_code="$(
    curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -X PUT "${base_url}/wiki/api/v2/pages/${page_id}" \
        --data @"$payload_file" \
        -o "$response_file" \
        -w "%{http_code}"
)"

if [[ "$http_code" != "200" ]]; then
    echo "Failed to update page (HTTP ${http_code})" >&2
    cat "$response_file" >&2
    exit 1
fi

jq '{id, title, status, version: .version.number, webui: (._links.base + ._links.webui)}' "$response_file"
