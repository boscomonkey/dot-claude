#!/usr/bin/env bash
#
# gh-pr-ready-review.sh - flip a draft PR to "ready for review" and request reviewers.
#
# usage: gh-pr-ready-review.sh <PR_NUMBER> <reviewers-comma-separated> [OWNER/REPO]
#   <reviewers> are GitHub user logins and/or org/team slugs, comma-separated
#     (e.g. "alice,bob,hinge-health/some-team").
#   [OWNER/REPO] defaults to the cwd's repo.
#
# Idempotent: re-running on an already-ready PR or with already-requested
# reviewers is harmless. Uses GITHUB_TOKEN.
set -euo pipefail

PR="${1:?usage: gh-pr-ready-review.sh <PR_NUMBER> <reviewers-csv> [OWNER/REPO]}"
REVIEWERS="${2:?reviewers (comma-separated) required}"
REPO="${3:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"

gh pr ready "$PR" --repo "$REPO"
gh pr edit "$PR" --repo "$REPO" --add-reviewer "$REVIEWERS"
echo "PR #$PR ($REPO): ready-for-review + reviewers requested -> $REVIEWERS"
