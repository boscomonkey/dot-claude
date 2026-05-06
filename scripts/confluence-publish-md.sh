#!/usr/bin/env bash
# One-shot: convert a Markdown file to Confluence storage format and create
# a new page under a given parent.
#
# Usage: confluence-publish-md.sh <PARENT_ID> <TITLE> <INPUT_MD>
# Example: confluence-publish-md.sh 2485420082 "My discovery" tmp/note.md
#
# Composes confluence-md-to-storage.sh + confluence-create-page.sh.
# The intermediate storage XHTML is written to a temp file and cleaned up.
#
# Requires env vars (same as confluence-create-page.sh):
#   JIRA_USERNAME, JIRA_API_TOKEN, [JIRA_BASE_URL]

set -eo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $(basename "$0") <PARENT_ID> <TITLE> <INPUT_MD>" >&2
    exit 2
fi

parent_id="$1"
title="$2"
input_md="$3"

if [[ ! -f "$input_md" ]]; then
    echo "Error: input file not found: $input_md" >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
storage_file="$(mktemp -t confluence-publish.XXXXXX.xhtml)"
trap 'rm -f "$storage_file"' EXIT

"${script_dir}/confluence-md-to-storage.sh" "$input_md" "$storage_file" >/dev/null

"${script_dir}/confluence-create-page.sh" "$parent_id" "$title" "$storage_file"
