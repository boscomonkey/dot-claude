#!/usr/bin/env bash
#
# gh-pr-update-branch.sh <PR_NUMBER> [OWNER/REPO] - press the "Update branch"
# button on a PR: merge the latest base branch into the PR branch via
# `gh pr update-branch` (PUT /repos/{repo}/pulls/{n}/update-branch). Pass a
# repo as the 2nd arg; defaults to the cwd's repo. Tolerates an
# already-up-to-date branch as success (no-op). Uses GITHUB_TOKEN.
set -eo pipefail
PR="${1:?usage: gh-pr-update-branch.sh <PR_NUMBER> [OWNER/REPO]}"
REPO="${2:-}"

ARGS=(pr update-branch "$PR")
if [ -n "$REPO" ]; then
  ARGS+=(--repo "$REPO")
fi

set +e
OUT=$(gh "${ARGS[@]}" 2>&1)
RC=$?
set -e

if [ "$RC" -eq 0 ]; then
  echo "PR #$PR: ${OUT:-branch updated}"
  exit 0
fi
if echo "$OUT" | grep -qiE 'not behind|already up.?to.?date|up to date|no new commits'; then
  echo "PR #$PR: already up to date (no-op)"
  exit 0
fi
echo "PR #$PR FAILED: $OUT" >&2
exit 1
