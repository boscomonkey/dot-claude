#!/usr/bin/env bash
# Fetch PR metadata via `gh pr view --json`, with selectable fields.
#
# Usage: github-pr-view.sh <OWNER/REPO> <PR_NUMBER> [FIELDS]
#   FIELDS - comma-separated gh JSON fields (default covers the common set:
#            number,title,body,state,isDraft,baseRefName,headRefName,
#            author,url,files,additions,deletions,labels,reviewDecision)
#
# Examples:
#   github-pr-view.sh hinge-health/basilisk 15590
#   github-pr-view.sh hinge-health/basilisk 15590 title,body,files,baseRefName,headRefName
#
# Prints the raw JSON gh returns (pipe through jq as needed).
# GITHUB_TOKEN is read by gh from the environment automatically.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $(basename "$0") <OWNER/REPO> <PR_NUMBER> [FIELDS]" >&2
    echo "Example: $(basename "$0") hinge-health/basilisk 15590" >&2
    exit 2
fi

REPO="$1"
PR_NUMBER="$2"
FIELDS="${3:-number,title,body,state,isDraft,baseRefName,headRefName,author,url,files,additions,deletions,labels,reviewDecision}"

gh pr view "${PR_NUMBER}" --repo "${REPO}" --json "${FIELDS}"
