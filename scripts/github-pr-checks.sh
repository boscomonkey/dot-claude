#!/usr/bin/env bash
# Fetch CI check statuses for a GitHub PR.
# Usage: github-pr-checks.sh <owner/repo> <pr_number>
# Example: github-pr-checks.sh your-org/your-repo 1399
set -euo pipefail

REPO="$1"
PR_NUMBER="$2"

SHA=$(curl -s \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${REPO}/pulls/${PR_NUMBER}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['head']['sha'])")

echo "PR #${PR_NUMBER} — ${REPO}"
echo "SHA: ${SHA}"
echo ""

curl -s \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${REPO}/commits/${SHA}/check-runs?per_page=100" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
runs = data.get('check_runs', [])
if not runs:
    print('  (no check runs found)')
    sys.exit(0)
width = max(len(r['name']) for r in runs)
for r in runs:
    status     = r['status']
    conclusion = r.get('conclusion') or ''
    icon = {'success': '✅', 'failure': '❌', 'skipped': '⏭️', 'cancelled': '🚫'}.get(conclusion, '🔄')
    print(f'  {icon}  {r[\"name\"]:<{width}}  {status}/{conclusion}')
total = len(runs)
done  = sum(1 for r in runs if r['status'] == 'completed')
ok    = sum(1 for r in runs if r.get('conclusion') == 'success')
fail  = sum(1 for r in runs if r.get('conclusion') in ('failure', 'cancelled'))
print(f'')
print(f'  {done}/{total} completed  |  {ok} passed  |  {fail} failed')
"
