#!/usr/bin/env bash
# Publish a Markdown file to Confluence: create the page if no child page with
# the given title exists under PARENT_ID, otherwise update it in place.
# One-command "publish this working doc" for the local-scratch -> Confluence
# milestone-publish (hybrid) workflow.
#
# Usage: confluence-sync-md.sh <PARENT_ID> <TITLE> <INPUT_MD> [VERSION_COMMENT]
#   VERSION_COMMENT is recorded as the edit message when updating an existing
#   page (ignored on first creation, which is version 1).
#
# Matches an existing page by EXACT title among PARENT_ID's direct children.
# Composes confluence-md-to-storage.sh + confluence-list-children.sh +
# (confluence-create-page.sh | confluence-update-page.sh).
#
# Prints the create/update JSON result on success.
#
# Requires env vars: JIRA_USERNAME, JIRA_API_TOKEN, JIRA_BASE_URL
# Requires: pandoc, python3, jq

set -eo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
    echo "Usage: $(basename "$0") <PARENT_ID> <TITLE> <INPUT_MD> [VERSION_COMMENT]" >&2
    exit 2
fi

parent_id="$1"
title="$2"
input_md="$3"
version_comment="${4:-}"

scripts_dir="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$input_md" ]]; then
    echo "Error: input markdown not found: $input_md" >&2
    exit 1
fi

storage_file="$(mktemp -t confluence-sync.XXXXXX.xhtml)"
trap 'rm -f "$storage_file"' EXIT

# 1. Markdown -> Confluence storage XHTML (converter logs to stderr).
"$scripts_dir/confluence-md-to-storage.sh" "$input_md" "$storage_file" >&2

# 2. Find an existing child page with this exact title under the parent.
existing_id="$(
    "$scripts_dir/confluence-list-children.sh" "$parent_id" \
    | jq -r --arg t "$title" '.pages[]? | select(.title == $t) | .id' | head -n1
)"

# 3. Update if found, else create.
if [[ -n "$existing_id" ]]; then
    echo "Found existing page ${existing_id} (\"${title}\") - updating." >&2
    if [[ -n "$version_comment" ]]; then
        "$scripts_dir/confluence-update-page.sh" "$existing_id" "$title" "$storage_file" "$version_comment"
    else
        "$scripts_dir/confluence-update-page.sh" "$existing_id" "$title" "$storage_file"
    fi
else
    echo "No existing page titled \"${title}\" under ${parent_id} - creating." >&2
    "$scripts_dir/confluence-create-page.sh" "$parent_id" "$title" "$storage_file"
fi
