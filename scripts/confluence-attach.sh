#!/usr/bin/env bash
# Attach a file to a Confluence page, or update it if one with the same name exists.
#
# Usage: confluence-attach.sh <PAGE_ID> <FILE_PATH>
# Example: confluence-attach.sh 2524315774 tmp/discovery-foo.md
#
# Uses the Confluence v1 attachment API (the v2 attachments endpoint returns
# METHOD_NOT_ALLOWED for uploads). Prints {id, title, fileSize} on success.
#
# Requires env vars:
#   JIRA_USERNAME    - JIRA / Confluence account email
#   JIRA_API_TOKEN   - JIRA / Confluence API token (https://id.atlassian.com/manage-profile/security/api-tokens)
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <PAGE_ID> <FILE_PATH>" >&2
    echo "Example: $(basename "$0") 2524315774 tmp/discovery-foo.md" >&2
    exit 2
fi

page_id="$1"
file="$2"

if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file" >&2
    exit 1
fi

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

# Resolve to absolute path so curl's file=@ works regardless of cwd.
abs_file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
filename="$(basename "$file")"

# Check whether an attachment with this filename already exists on the page.
existing_id=$(curl -sS \
    -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
    "${base_url}/wiki/rest/api/content/${page_id}/child/attachment?filename=${filename}" \
    | jq -r '.results[0].id // empty')

if [[ -n "$existing_id" ]]; then
    # Update the existing attachment in place.
    curl -sS -X POST \
        -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        -H "X-Atlassian-Token: nocheck" \
        -F "file=@${abs_file}" \
        "${base_url}/wiki/rest/api/content/${page_id}/child/attachment/${existing_id}/data" \
        | jq '{id, title, fileSize: .extensions.fileSize}'
else
    # Create a new attachment.
    curl -sS -X POST \
        -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        -H "X-Atlassian-Token: nocheck" \
        -F "file=@${abs_file}" \
        "${base_url}/wiki/rest/api/content/${page_id}/child/attachment" \
        | jq '.results[] | {id, title, fileSize: .extensions.fileSize}'
fi
