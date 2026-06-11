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
# Usage: confluence-sync-md.sh [--strip-doc-meta] <PARENT_ID> <TITLE> <INPUT_MD> [VERSION_COMMENT]
#
#   --strip-doc-meta  Strip the local tmp/-doc scaffolding that is redundant on
#                     Confluence (which versions pages natively and shows the
#                     title itself): the leading version-summary table, the
#                     leading H1 title, and the trailing "## Version History"
#                     section. Lets a tmp/ working doc publish unmodified.
#   VERSION_COMMENT   Recorded as the edit message when updating an existing
#                     page (ignored on first creation, which is version 1).
#
# Matches an existing page by EXACT title among PARENT_ID's direct children.
#
# Prints the create/update JSON result on success.
#
# Requires env vars: JIRA_USERNAME, JIRA_API_TOKEN, JIRA_BASE_URL
# Requires: pandoc, python3, jq; mmdc only if the doc has Mermaid diagrams.

set -eo pipefail

strip_meta=0
if [[ "${1:-}" == "--strip-doc-meta" ]]; then
    strip_meta=1
    shift
fi

if [[ $# -lt 3 || $# -gt 4 ]]; then
    echo "Usage: $(basename "$0") [--strip-doc-meta] <PARENT_ID> <TITLE> <INPUT_MD> [VERSION_COMMENT]" >&2
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
stripped_md=""
trap 'rm -rf "$storage_file" "$img_dir" "$img_list" "$stripped_md"' EXIT

# 0. Optionally strip local tmp/-doc scaffolding (version tables, H1, history).
src_md="$input_md"
if [[ "$strip_meta" == "1" ]]; then
    stripped_md="$(mktemp -t confluence-sync-src.XXXXXX.md)"
    python3 - "$input_md" "$stripped_md" <<'PYEOF'
import sys
from pathlib import Path
lines = Path(sys.argv[1]).read_text().split("\n")
# Drop everything up to and including the first H1 (the title) - in our tmp/
# docs the version-summary table sits just above the H1, so this removes both.
h1 = next((i for i, l in enumerate(lines) if l.startswith("# ")), None)
if h1 is not None:
    lines = lines[h1 + 1:]
# Drop the trailing "## Version History" section to EOF.
vh = next((i for i, l in enumerate(lines) if l.strip() == "## Version History"), None)
if vh is not None:
    lines = lines[:vh]
while lines and lines[0].strip() == "":
    lines.pop(0)
while lines and lines[-1].strip() == "":
    lines.pop()
Path(sys.argv[2]).write_text("\n".join(lines) + "\n")
PYEOF
    src_md="$stripped_md"
fi

# 1. Markdown -> Confluence storage XHTML (converter logs to stderr).
"$scripts_dir/confluence-md-to-storage.sh" "$src_md" "$storage_file" >&2

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
