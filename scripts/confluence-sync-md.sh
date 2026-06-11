#!/usr/bin/env bash
# Publish a Markdown file to Confluence: create the page if no child page with
# the given title exists under PARENT_ID, otherwise update it in place.
# One-command "publish this working doc" for the local-scratch -> Confluence
# milestone-publish (hybrid) workflow.
#
# Mermaid: any ```mermaid fences are pre-rendered to PNGs (via mmdc) and embedded
# as page attachments, since Confluence has no native Mermaid renderer (Option B;
# no external render service / data egress).
#
# Usage: confluence-sync-md.sh <PARENT_ID> <TITLE> <INPUT_MD> [VERSION_COMMENT]
#   VERSION_COMMENT is recorded as the edit message when updating an existing
#   page (ignored on first creation, which is version 1).
#
# Matches an existing page by EXACT title among PARENT_ID's direct children.
# Composes confluence-md-to-storage.sh + confluence-render-mermaid.sh +
# confluence-list-children.sh + (confluence-create-page.sh |
# confluence-update-page.sh) + confluence-attach.sh.
#
# Prints the create/update JSON result on success.
#
# Requires env vars: JIRA_USERNAME, JIRA_API_TOKEN, JIRA_BASE_URL
# Requires: pandoc, python3, jq; mmdc only if the doc has Mermaid diagrams.

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
img_dir="$(mktemp -d -t confluence-sync-imgs.XXXXXX)"
img_list="$(mktemp -t confluence-sync-imgs.XXXXXX.txt)"
trap 'rm -rf "$storage_file" "$img_dir" "$img_list"' EXIT

# 1. Markdown -> Confluence storage XHTML (converter logs to stderr).
"$scripts_dir/confluence-md-to-storage.sh" "$input_md" "$storage_file" >&2

# 2. Pre-render any Mermaid diagrams: rewrites storage in place to <ac:image>
#    refs and lists the generated PNGs to attach (empty if none).
"$scripts_dir/confluence-render-mermaid.sh" "$storage_file" "$img_dir" > "$img_list"

# 3. Find an existing child page with this exact title under the parent.
existing_id="$(
    "$scripts_dir/confluence-list-children.sh" "$parent_id" \
    | jq -r --arg t "$title" '.pages[]? | select(.title == $t) | .id' | head -n1
)"

# 4. Update if found, else create. Capture the result JSON and the page id.
if [[ -n "$existing_id" ]]; then
    echo "Found existing page ${existing_id} (\"${title}\") - updating." >&2
    page_id="$existing_id"
    if [[ -n "$version_comment" ]]; then
        result="$("$scripts_dir/confluence-update-page.sh" "$existing_id" "$title" "$storage_file" "$version_comment")"
    else
        result="$("$scripts_dir/confluence-update-page.sh" "$existing_id" "$title" "$storage_file")"
    fi
else
    echo "No existing page titled \"${title}\" under ${parent_id} - creating." >&2
    result="$("$scripts_dir/confluence-create-page.sh" "$parent_id" "$title" "$storage_file")"
    page_id="$(printf '%s' "$result" | jq -r '.id')"
fi

# 5. Attach rendered Mermaid images so the <ac:image> refs resolve (attach
#    updates in place when the filename already exists, so re-syncs are clean).
if [[ -s "$img_list" ]]; then
    while IFS= read -r img; do
        [[ -n "$img" ]] || continue
        echo "Attaching $(basename "$img") to page ${page_id}." >&2
        "$scripts_dir/confluence-attach.sh" "$page_id" "$img" >&2
    done < "$img_list"
fi

# 6. Emit the create/update result.
printf '%s\n' "$result"
