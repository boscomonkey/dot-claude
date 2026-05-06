#!/usr/bin/env bash
# Fetch the title and body (description) of a GitHub PR.
#
# Usage: github-pr-description.sh <OWNER/REPO> <PR_NUMBER>
# Example: github-pr-description.sh your-org/your-repo 1440
#
# Prints: PR title, URL, then the body text.
#
# Requires env var:
#   GITHUB_ACCESS_TOKEN - GitHub personal access token

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <OWNER/REPO> <PR_NUMBER>" >&2
    echo "Example: $(basename "$0") your-org/your-repo 1440" >&2
    exit 2
fi

REPO="$1"
PR_NUMBER="$2"

: "${GITHUB_ACCESS_TOKEN:?GITHUB_ACCESS_TOKEN must be set}"

curl -s \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${REPO}/pulls/${PR_NUMBER}" \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
if 'message' in r:
    print(f'Error: {r[\"message\"]}', file=sys.stderr)
    sys.exit(1)
print(f'PR #{r[\"number\"]}: {r[\"title\"]}')
print(f'URL: {r[\"html_url\"]}')
print()
print(r['body'] or '(no description)')
"
