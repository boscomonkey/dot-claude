#!/usr/bin/env bash
# Fetch GitHub Actions job logs by job ID.
# Usage: github-job-logs.sh <OWNER/REPO> <JOB_ID> [--out <FILE>]
#
# Writes logs to stdout or to FILE if --out is specified.
# JOB_ID is the numeric job ID from the GitHub Actions UI URL
# (e.g., the number after /jobs/ in the Actions URL).

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <OWNER/REPO> <JOB_ID> [--out <FILE>]" >&2
    exit 1
fi

REPO="$1"
JOB_ID="$2"
OUT_FILE=""

shift 2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --out)
            OUT_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

URL="https://api.github.com/repos/${REPO}/actions/jobs/${JOB_ID}/logs"

if [[ -n "$OUT_FILE" ]]; then
    curl -sL \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "$URL" -o "$OUT_FILE"
    echo "Logs written to $OUT_FILE ($(wc -l < "$OUT_FILE") lines)" >&2
else
    curl -sL \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "$URL"
fi
