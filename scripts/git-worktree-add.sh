#!/usr/bin/env bash
# Create a new git worktree with a new branch, run from a given repo directory.
# Usage: git-worktree-add.sh <repo_dir> <worktree_path> <new_branch> <base_ref>
# Example:
#   git-worktree-add.sh /path/to/repo /path/to/repo-FEAT-1 FEAT-1-my-branch main
#
# Runs `git -C <repo_dir> worktree add <worktree_path> -b <new_branch> <base_ref>`.
# Any post-checkout hooks/aliases configured in the repo (e.g. copying .env,
# initializing submodules) run as part of the normal worktree-add flow.
set -euo pipefail

REPO_DIR="$1"
WORKTREE_PATH="$2"
NEW_BRANCH="$3"
BASE_REF="$4"

git -C "$REPO_DIR" worktree add "$WORKTREE_PATH" -b "$NEW_BRANCH" "$BASE_REF"
