---
name: reference-linear-team-move-drops-project
description: "Linear's `issueUpdate(teamId: ...)` silently clears `projectId` if the new team isn't a member of the project. Re-attaching the issue then fails with \"Discrepancy between issue team and state, cycle or project\" until the team is added to the project."
metadata: 
  node_type: memory
  type: reference
  originSessionId: fd665bcd-83bc-430b-9943-1ff6fd173557
---

When using Linear's GraphQL API to move an issue between teams (`issueUpdate(input: { teamId: NEW_TEAM_ID })`), if the new team is NOT already a member team of the issue's current project, Linear silently sets `projectId` to `null`. The team move succeeds, but the project association is lost - no warning, no error.

Attempting to re-attach the issue via `issueUpdate(input: { projectId: ... })` then fails with:

```
Discrepancy between issue team and state, cycle or project
```

**To fix:** add the new team as a member of the project first, via `projectUpdate(input: { teamIds: [...existing, newTeamId] })`. Linear projects can span multiple teams. Then `issueUpdate(input: { projectId: ... })` succeeds.

**How to apply:** When batch-moving issues between teams while preserving project assignment, always check `project { teams { nodes { id } } }` first. If the target team isn't already a member, either:

- add it to the project before moving the issues (preserves project association), or
- accept that the issues will be orphaned from the project and re-attach them manually after.

Same trap likely applies to cycles - cycles are team-scoped, so a team move will drop the cycle assignment.

Discovered while moving 6 SRE-NNN issues in the SOX Compliance project to the SEP team (May 2026).
