#!/usr/bin/env bash
# Create a DRAFT GitHub PR and assign it to the authenticated user (@me).
#
# Usage:
#   gh-draft-pr.sh --repo <OWNER/REPO> --base <BASE_BRANCH> --head <HEAD_BRANCH> \
#                  --title <TITLE> --body-file <PATH>
#
# All flags are required except --repo (defaults to the repo of the cwd).
# On success prints the PR URL, then assigns it to @me.
#
# Requires env var: GITHUB_TOKEN (used by the gh CLI).

set -eo pipefail

repo=""
base=""
head=""
title=""
body_file=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)      repo="$2"; shift 2 ;;
        --base)      base="$2"; shift 2 ;;
        --head)      head="$2"; shift 2 ;;
        --title)     title="$2"; shift 2 ;;
        --body-file) body_file="$2"; shift 2 ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

if [[ -z "$base" || -z "$head" || -z "$title" || -z "$body_file" ]]; then
    echo "Usage: $(basename "$0") [--repo OWNER/REPO] --base BASE --head HEAD --title TITLE --body-file PATH" >&2
    exit 2
fi

if [[ ! -f "$body_file" ]]; then
    echo "Error: body file not found: $body_file" >&2
    exit 1
fi

: "${GITHUB_TOKEN:?GITHUB_TOKEN must be set}"

repo_args=()
[[ -n "$repo" ]] && repo_args=(--repo "$repo")

url=$(gh pr create "${repo_args[@]}" \
    --draft \
    --base "$base" \
    --head "$head" \
    --title "$title" \
    --body-file "$body_file")

echo "$url"

# Resolve the PR number from the URL and assign to the authenticated user.
pr_number="${url##*/}"
gh pr edit "$pr_number" "${repo_args[@]}" --add-assignee @me >/dev/null

echo "Assigned PR #$pr_number to @me"
