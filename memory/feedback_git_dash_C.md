---
name: Use git -C for other directories
description: Use git -C /path instead of cd /path && git when running git commands in another folder
type: feedback
---

Use `git -C /path/to/repo <command>` instead of `cd /path/to/repo && git <command>` when running git commands in a different directory.

**Why:** Avoids changing the working directory, keeps commands self-contained, and is cleaner in Bash tool calls.

**How to apply:** Any time you need to run git in a worktree or sibling folder, use `-C`. Example: `git -C /Users/bosco.so/projects/my-service-PROJ-1234 rebase origin/main`
