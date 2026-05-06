#!/usr/bin/env bash
# Look up open PR(s) for a branch on GitHub.
# Usage: github-pr-for-branch.sh <owner/repo> <branch>
# Example: github-pr-for-branch.sh your-org/your-repo PROJ-1234-my-feature-branch
set -euo pipefail

REPO="$1"
BRANCH="$2"

OWNER="${REPO%%/*}"

curl -s \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${REPO}/pulls?state=open&head=${OWNER}:${BRANCH}" \
  | python3 -c "
import sys, json
prs = json.load(sys.stdin)
if not prs:
    print('(no open PRs found for branch)')
    sys.exit(0)
for p in prs:
    print(f'#{p[\"number\"]}: {p[\"title\"]}')
    print(f'  URL:    {p[\"html_url\"]}')
    print(f'  State:  {p[\"state\"]}  Draft: {p[\"draft\"]}')
    print(f'  Base:   {p[\"base\"][\"ref\"]}  <-  {p[\"head\"][\"ref\"]}')
    print()
"
