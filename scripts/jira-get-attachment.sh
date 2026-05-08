#!/usr/bin/env bash
# Download a JIRA attachment by ID.
#
# Usage: jira-get-attachment.sh <ATTACHMENT_ID> [--out <FILE>]
# Example:
#   jira-get-attachment.sh 251779 --out tmp/SEP-2408-test-plan.md
#   jira-get-attachment.sh 251779                    # prints to stdout
#
# ATTACHMENT_ID is the numeric id returned by jira-list-attachments.sh
# or jira-attach.sh.
#
# The /rest/api/3/attachment/content/{id} endpoint returns a redirect
# (302) to a presigned object-storage URL holding the actual bytes;
# curl -L follows it.
#
# Requires env vars:
#   JIRA_USERNAME    - JIRA account email
#   JIRA_API_TOKEN   - JIRA API token
#   JIRA_BASE_URL    - Atlassian base URL (e.g. https://your-org.atlassian.net)

set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") <ATTACHMENT_ID> [--out <FILE>]" >&2
    echo "Example: $(basename "$0") 251779 --out tmp/SEP-2408-test-plan.md" >&2
    exit 2
}

if [[ $# -lt 1 ]]; then
    usage
fi

attachment_id="$1"
shift

out_file=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --out)
            shift
            if [[ $# -eq 0 ]]; then
                echo "Error: --out requires a file path" >&2
                usage
            fi
            out_file="$1"
            shift
            ;;
        *)
            echo "Error: unknown argument: $1" >&2
            usage
            ;;
    esac
done

: "${JIRA_USERNAME:?JIRA_USERNAME must be set}"
: "${JIRA_API_TOKEN:?JIRA_API_TOKEN must be set}"
base_url="${JIRA_BASE_URL:?JIRA_BASE_URL must be set}"

if [[ -n "$out_file" ]]; then
    curl -sS -L -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        "${base_url}/rest/api/3/attachment/content/${attachment_id}" \
        -o "$out_file"
    echo "Wrote: $out_file ($(wc -c < "$out_file") bytes)" >&2
else
    curl -sS -L -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
        "${base_url}/rest/api/3/attachment/content/${attachment_id}"
fi
