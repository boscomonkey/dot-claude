#!/usr/bin/env bash
# Delete a Linear attachment by ID.
#
# Usage: linear-delete-attachment.sh <ATTACHMENT_ID>
# Example: linear-delete-attachment.sh att_abc123
#
# The attachment ID is returned by linear-attach.sh or linear-list-attachments.sh.
#
# Requires env var: LINEAR_API_KEY

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <ATTACHMENT_ID>" >&2
    echo "Example: $(basename "$0") att_abc123" >&2
    exit 2
fi

attachment_id="$1"

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

payload=$(jq -n \
    --arg id "$attachment_id" \
    '{
        "query": "mutation AttachmentDelete($id: String!) { attachmentDelete(id: $id) { success } }",
        "variables": {"id": $id}
    }')

response=$(curl -sS -X POST \
    -H "Authorization: $LINEAR_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    https://api.linear.app/graphql)

if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error:" >&2
    echo "$response" | jq '.errors' >&2
    exit 1
fi

success=$(echo "$response" | jq -r '.data.attachmentDelete.success')
if [[ "$success" == "true" ]]; then
    echo "deleted attachment $attachment_id"
else
    echo "Failed to delete attachment $attachment_id" >&2
    echo "$response" >&2
    exit 1
fi
