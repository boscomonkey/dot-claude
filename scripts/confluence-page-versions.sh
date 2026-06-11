#!/usr/bin/env bash
# Fetch a Confluence page's version history (number, author, timestamp, message).
# Accepts a page ID or a full Confluence URL containing the page ID.
#
# Usage: confluence-page-versions.sh <PAGE_ID|URL> [LIMIT]
#   LIMIT defaults to 15.
#
# Prints one tab-separated line per version, newest first:
#   v<number>  by=<author>  when=<ISO timestamp>  msg=<edit message>
#
# Useful for checking whether a page was edited by someone else before you
# overwrite it (e.g. via confluence-update-page.sh), and by whom/when.
#
# Exits non-zero and prints an error on HTTP failure.
#
# Requires env vars: JIRA_USERNAME, JIRA_API_TOKEN, JIRA_BASE_URL

set -eo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <PAGE_ID|URL> [LIMIT]" >&2
    exit 2
fi

input="$1"
limit="${2:-15}"

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

tmp="$(mktemp -t confluence-versions.XXXXXX.json)"
trap 'rm -f "$tmp"' EXIT

http_code="$(
    curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        -H "Accept: application/json" \
        "${base_url}/wiki/rest/api/content/${page_id}/version?limit=${limit}" \
        -o "$tmp" \
        -w "%{http_code}"
)"

if [[ "$http_code" != "200" ]]; then
    echo "Failed to fetch versions for page ${page_id} (HTTP ${http_code})" >&2
    cat "$tmp" >&2
    exit 1
fi

jq -r '.results[] | "v\(.number)\tby=\(.by.displayName // "?")\twhen=\(.when // "?")\tmsg=\(.message // "")"' "$tmp"
