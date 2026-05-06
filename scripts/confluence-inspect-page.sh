#!/usr/bin/env bash
# Fetch a Confluence page in storage format and print structural stats.
# Useful for verifying a publish/update rendered as expected, or for
# diagnosing why a page renders strangely.
#
# Usage: confluence-inspect-page.sh <PAGE_ID> [--dump <FILE>]
# Example: confluence-inspect-page.sh 2486763645
#          confluence-inspect-page.sh 2486763645 --dump /tmp/page.xhtml
#
# Prints (as a single JSON object):
#   title, status, version, parentId, parentType, spaceId, webui
#   bytes (length of body.storage.value)
#   code_macros, info_macros, warning_macros, note_macros, expand_macros
#   structured_macros (total)
#   tables, headings (h1..h6), bullet_lists, ordered_lists, links, blockquotes
#
# With --dump <FILE>, also writes the raw storage XHTML to <FILE>.
#
# Requires env vars:
#   JIRA_USERNAME, JIRA_API_TOKEN, JIRA_BASE_URL

set -eo pipefail

if [[ $# -lt 1 || $# -gt 3 ]]; then
    echo "Usage: $(basename "$0") <PAGE_ID> [--dump <FILE>]" >&2
    exit 2
fi

page_id="$1"
dump_file=""

if [[ $# -eq 3 ]]; then
    if [[ "$2" != "--dump" ]]; then
        echo "Usage: $(basename "$0") <PAGE_ID> [--dump <FILE>]" >&2
        exit 2
    fi
    dump_file="$3"
elif [[ $# -eq 2 ]]; then
    echo "Usage: $(basename "$0") <PAGE_ID> [--dump <FILE>]" >&2
    exit 2
fi

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

response_file="$(mktemp -t confluence-inspect.XXXXXX.json)"
trap 'rm -f "$response_file"' EXIT

http_code="$(
    curl -sS -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        -H "Accept: application/json" \
        "${base_url}/wiki/api/v2/pages/${page_id}?body-format=storage" \
        -o "$response_file" \
        -w "%{http_code}"
)"

if [[ "$http_code" != "200" ]]; then
    echo "Failed to fetch page ${page_id} (HTTP ${http_code})" >&2
    cat "$response_file" >&2
    exit 1
fi

if [[ -n "$dump_file" ]]; then
    jq -r '.body.storage.value' "$response_file" > "$dump_file"
    echo "wrote $dump_file ($(wc -c < "$dump_file" | tr -d ' ') bytes)" >&2
fi

jq '{
    title,
    status,
    version: .version.number,
    parentId,
    parentType,
    spaceId,
    webui: (._links.base + ._links.webui),
    bytes: (.body.storage.value | length),
    structured_macros: ([.body.storage.value | scan("<ac:structured-macro ")] | length),
    code_macros: ([.body.storage.value | scan("ac:name=\"code\"")] | length),
    info_macros: ([.body.storage.value | scan("ac:name=\"info\"")] | length),
    warning_macros: ([.body.storage.value | scan("ac:name=\"warning\"")] | length),
    note_macros: ([.body.storage.value | scan("ac:name=\"note\"")] | length),
    expand_macros: ([.body.storage.value | scan("ac:name=\"expand\"")] | length),
    tables: ([.body.storage.value | scan("<table[ >]")] | length),
    h1: ([.body.storage.value | scan("<h1[ >]")] | length),
    h2: ([.body.storage.value | scan("<h2[ >]")] | length),
    h3: ([.body.storage.value | scan("<h3[ >]")] | length),
    h4: ([.body.storage.value | scan("<h4[ >]")] | length),
    bullet_lists: ([.body.storage.value | scan("<ul[ >]")] | length),
    ordered_lists: ([.body.storage.value | scan("<ol[ >]")] | length),
    links: ([.body.storage.value | scan("<a [^>]*href=")] | length),
    blockquotes: ([.body.storage.value | scan("<blockquote[ >]")] | length)
}' "$response_file"
