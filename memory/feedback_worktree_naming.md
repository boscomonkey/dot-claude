---
name: Git worktree folder naming convention
description: Worktree folders go as sibling directories named {service}-{ticket}, e.g. ~/projects/my-service-PROJ-1234
type: feedback
---

When creating git worktree folders for a project, place them as sibling folders to the main service folder with the ticket key appended.

Example: for `~/projects/my-service`, worktree folders are `~/projects/my-service-PROJ-xxxx`.

**Why:** Keeps worktrees discoverable and consistently named across projects and laptops.

**How to apply:** When using `git worktree add` or the Agent tool with `isolation: "worktree"`, use this naming pattern instead of the default `.claude/worktrees/` path.
