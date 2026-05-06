#!/usr/bin/env bash
# Fetch a Confluence page body in storage (XHTML) format.
# Accepts a page ID or a full Confluence URL containing the page ID.
#
# Usage: confluence-get.sh <PAGE_ID|URL> [--out <FILE>]
#
# Examples:
#   confluence-get.sh 2442330211
#   confluence-get.sh 2442330211 --out /tmp/page.html
#   confluence-get.sh "https://YOUR_ORG.atlassian.net/wiki/spaces/SE/pages/2442330211/..."
#
# With --out <FILE>: writes raw storage XHTML to <FILE> (silent on stdout).
# Without --out:     prints raw storage XHTML to stdout.
#
# Exits non-zero and prints an error on HTTP failure.
#
# Requires env vars: JIRA_USERNAME, JIRA_API_TOKEN, JIRA_BASE_URL

set -eo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <PAGE_ID|URL> [--out <FILE>]" >&2
    exit 2
fi

input="$1"
out_file=""

if [[ $# -eq 3 && "$2" == "--out" ]]; then
    out_file="$3"
elif [[ $# -eq 2 ]]; then
    echo "Usage: $(basename "$0") <PAGE_ID|URL> [--out <FILE>]" >&2
    exit 2
fi

# Extract numeric page ID from a full URL if needed
if [[ "$input" =~ /pages/([0-9]+) ]]; then
    page_id="${BASH_REMATCH[1]}"
elif [[ "$input" =~ ^[0-9]+$ ]]; then
    page_id="$input"
else
    echo "Error: could not extract a numeric page ID from: $input" >&2
    exit 2
fi

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

tmp="$(mktemp -t confluence-get.XXXXXX.json)"
trap 'rm -f "$tmp"' EXIT

http_code="$(
    curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        -H "Accept: application/json" \
        "${base_url}/wiki/rest/api/content/${page_id}?expand=body.storage,version" \
        -o "$tmp" \
        -w "%{http_code}"
)"

if [[ "$http_code" != "200" ]]; then
    echo "Failed to fetch page ${page_id} (HTTP ${http_code})" >&2
    cat "$tmp" >&2
    exit 1
fi

if [[ -n "$out_file" ]]; then
    jq -r '.body.storage.value' "$tmp" > "$out_file"
    jq -r '"Fetched page \(.id): \(.title) (version \(.version.number)) -> '"$out_file"'"' "$tmp" >&2
else
    jq -r '.body.storage.value' "$tmp"
fi
