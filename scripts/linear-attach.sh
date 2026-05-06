#!/usr/bin/env bash
# Upload a file as an attachment on a Linear issue.
#
# Usage: linear-attach.sh <ISSUE_ID> <FILE_PATH>
# Example: linear-attach.sh ENG-123 tmp/screenshot.png
#
# Three-step process: get a presigned upload URL from Linear, PUT the file
# there, then create the attachment record on the issue.
# Prints {id, title, url} on success.
#
# Requires env var: LINEAR_API_KEY

set -eo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <ISSUE_ID> <FILE_PATH>" >&2
    echo "Example: $(basename "$0") ENG-123 tmp/screenshot.png" >&2
    exit 2
fi

issue_id="$1"
file="$2"

if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file" >&2
    exit 1
fi

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

abs_file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
filename="$(basename "$abs_file")"
file_size=$(wc -c < "$abs_file" | tr -d ' ')
content_type=$(file --mime-type -b "$abs_file")

gql() {
    curl -sS -X POST \
        -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$1" \
        https://api.linear.app/graphql
}

# Step 1: resolve issue UUID
resolve_payload=$(jq -n --arg id "$issue_id" \
    '{"query": "query($id: String!) { issue(id: $id) { id } }", "variables": {"id": $id}}')
resolve_response=$(gql "$resolve_payload")
issue_uuid=$(echo "$resolve_response" | jq -r '.data.issue.id')
if [[ "$issue_uuid" == "null" || -z "$issue_uuid" ]]; then
    echo "Error: issue $issue_id not found" >&2
    exit 1
fi

# Step 2: get presigned upload URL from Linear
upload_payload=$(jq -n \
    --arg filename "$filename" \
    --arg contentType "$content_type" \
    --argjson size "$file_size" \
    '{
        "query": "mutation FileUpload($size: Int!, $filename: String!, $contentType: String!) { fileUpload(size: $size, filename: $filename, contentType: $contentType) { success uploadFile { uploadUrl assetUrl headers { key value } } } }",
        "variables": {"size": $size, "filename": $filename, "contentType": $contentType}
    }')

upload_response=$(gql "$upload_payload")
if echo "$upload_response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error getting upload URL:" >&2
    echo "$upload_response" | jq '.errors' >&2
    exit 1
fi

upload_url=$(echo "$upload_response" | jq -r '.data.fileUpload.uploadFile.uploadUrl')
asset_url=$(echo "$upload_response" | jq -r '.data.fileUpload.uploadFile.assetUrl')

# Step 3: PUT the file to the presigned URL with the required signed headers
header_args=()
while IFS= read -r header_line; do
    header_args+=(-H "$header_line")
done < <(echo "$upload_response" | jq -r '.data.fileUpload.uploadFile.headers[] | "\(.key): \(.value)"')

put_code=$(curl -sS -o /dev/null -w "%{http_code}" \
    -X PUT \
    "${header_args[@]}" \
    -H "Content-Type: $content_type" \
    --data-binary "@$abs_file" \
    "$upload_url")

if [[ "$put_code" != "200" && "$put_code" != "201" ]]; then
    echo "Error: file upload PUT returned HTTP $put_code" >&2
    exit 1
fi

# Step 4: create the attachment record on the issue
attach_payload=$(jq -n \
    --arg issueId "$issue_uuid" \
    --arg url "$asset_url" \
    --arg title "$filename" \
    '{
        "query": "mutation AttachmentCreate($input: AttachmentCreateInput!) { attachmentCreate(input: $input) { success attachment { id title url } } }",
        "variables": {"input": {"issueId": $issueId, "url": $url, "title": $title}}
    }')

attach_response=$(gql "$attach_payload")
if echo "$attach_response" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error creating attachment record:" >&2
    echo "$attach_response" | jq '.errors' >&2
    exit 1
fi

echo "$attach_response" | jq '.data.attachmentCreate.attachment'
