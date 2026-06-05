#!/usr/bin/env bash
#
# gh-pr-automerge.sh <PR_NUMBER> [OWNER/REPO] - enable GitHub auto-merge
# (the "Merge when ready" button) on a PR using squash merge. The PR merges
# automatically once all required checks pass (e.g. after a merge-freeze lifts).
# OWNER/REPO defaults to the cwd's repo. Uses GITHUB_TOKEN.
#
# Squash is the repo's merge method (PR title becomes the squash commit msg).
set -eo pipefail
PR="${1:?usage: gh-pr-automerge.sh <PR_NUMBER> [OWNER/REPO]}"
REPO="${2:-}"

ARGS=(pr merge "$PR" --auto --squash)
if [ -n "$REPO" ]; then
  ARGS+=(--repo "$REPO")
fi

gh "${ARGS[@]}"
