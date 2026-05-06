#!/usr/bin/env bash
# List the direct children (pages and subfolders) of a Confluence page or folder.
#
# Usage: confluence-list-children.sh <PAGE_OR_FOLDER_ID>
#
# Prints a JSON object with two arrays:
#   { "pages": [{id, title}, ...], "folders": [{id, title}, ...] }
#
# Requires env vars:
#   JIRA_USERNAME    - Atlassian account email
#   JIRA_API_TOKEN   - Atlassian API token (Confluence shares JIRA tokens)
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -eo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <PAGE_OR_FOLDER_ID>" >&2
    exit 2
fi

parent_id="$1"

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

response="$(
    curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
         -H "Accept: application/json" \
         "${base_url}/wiki/rest/api/content/${parent_id}/child?expand=folder.results,page.results"
)"

echo "$response" | jq '{
  pages:   [.page.results[]?   | {id, title}],
  folders: [.folder.results[]? | {id, title}]
}'
