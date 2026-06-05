#!/usr/bin/env bash
#
# git-commit-push.sh - stage all changes in a worktree, commit from a message
# file, and push the current branch to origin (setting upstream).
#
# usage: git-commit-push.sh <WORKTREE_DIR> <COMMIT_MSG_FILE>
#
# One allowlisted call for the repeatable "commit + push" step (avoids per-PR
# approval prompts for raw git). Uses GITHUB_TOKEN via the repo's git remote.
set -euo pipefail

DIR="${1:?usage: git-commit-push.sh <WORKTREE_DIR> <COMMIT_MSG_FILE>}"
MSG="${2:?commit message file required}"
[ -f "$MSG" ] || { echo "commit message file not found: $MSG" >&2; exit 1; }

git -C "$DIR" add -A
git -C "$DIR" commit -F "$MSG"
branch="$(git -C "$DIR" rev-parse --abbrev-ref HEAD)"
git -C "$DIR" push -u origin "$branch"
echo "committed + pushed '$branch' from $DIR"
