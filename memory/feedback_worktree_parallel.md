---
name: Use git worktrees for parallel branch work
description: When creating multiple independent branches, use Agent with isolation:"worktree" to parallelize instead of sequential checkout
type: feedback
---

When creating multiple independent branches (e.g., migration PRs, parallel feature work), use the Agent tool with `isolation: "worktree"` to run them in parallel rather than sequentially cycling through `git checkout`.

**Why:** Sequential checkout is slow (each agent waits for the previous) and risks uncommitted changes leaking between branches. Worktrees give each agent an isolated repo copy.

**How to apply:** When 2+ branches need independent single-file changes, launch one Agent per branch with `isolation: "worktree"`, all in a single message for maximum parallelism.
