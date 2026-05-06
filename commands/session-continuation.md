Create a session continuation document as a `.md` file in `tmp/`.

This document captures enough context for a future conversation to pick up where the current one left off.

## Structure

Add YAML frontmatter with:

- `version` - semver, starting at 1.0.0 for new docs. Bump major when rewriting an existing doc with substantial new findings. Bump minor for incremental updates.
- `timestamp` - current date and time to `hh:mm` granularity
- `repo` - org/repo-name
- `status` - one-line summary of where things stand right now

## Required sections

1. **Problem statement** - what we're trying to solve and why
1. **Relevant commits on main** - table of every commit on `main` related to this topic (SHA, date, description). Include infrastructure setup, fix attempts, and any affected PRs. If there are commits on an unmerged branch, list those in a separate subsection.
1. **Root cause** (if identified) - the actual underlying issue, with evidence. Include why prior fix attempts didn't work if applicable.
1. **Fix** (if implemented) - what the fix does, with a code snippet if helpful
1. **Expected behavior** - what should happen after the fix lands
1. **Diagnostics** - if the problem recurs, what to check. Include specific CLI commands, API calls, or log locations. List possible failure modes.
1. **Key identifiers** - table of IDs, config values, actor IDs, or other magic values that came up during debugging
1. **Prior work chain** - table of tickets/PRs that attempted to fix this, what each did, and whether it worked

Omit sections that don't apply (e.g., no "Fix" section if we're still investigating).

## Rules

- Use a descriptive, ticket-agnostic filename since the topic may span multiple tickets (e.g., `release-please-auto-merge-session.md` not `PROJ-1234-session.md`).
- If a session continuation doc already exists for this topic, update it (bump version) rather than creating a new one.
- No need to wrap body text. This doc is meant to be read by human & AI, and is not a PR description.
- The document should be self-contained - a reader with no prior context should be able to understand the problem, what's been tried, and what to do next.
- After writing the document, ask if it should be attached to a JIRA ticket.

## Argument

$ARGUMENTS - optional: path to an existing session continuation doc to update, or a JIRA ticket key to attach the result to.
