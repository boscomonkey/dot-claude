# Investigate Issue

Investigate a failure or unexpected behaviour, trace it to the code change
that introduced it, and publish a structured findings report to Confluence.

## Invocation

```
/investigate-issue <evidence> [confluence-folder-id]
```

`<evidence>` is one of:

- **Pasted error output** - one or more error/exception lines copied from a
  terminal, log, or dashboard
- **GitHub Actions URL** - a link to a failed workflow run
  (`https://github.com/<org>/<repo>/actions/runs/<id>`)
- **Local log file path** - an absolute or repo-relative path to a log file
- **Confluence/Jira/Datadog/dashboard URL** - any URL pointing to evidence of
  the failure
- **Free-text description** - a plain English description of what went wrong

`confluence-folder-id` (optional): numeric folder ID from the Confluence URL.
Default: `$CONFLUENCE_INVESTIGATIONS_FOLDER_ID` (set in `~/.nocommit_profile`).

---

## Phase 1 - Understand the failure

Determine what type of evidence was provided and extract the key signal:

**Pasted errors / log file:**
- Parse error class, message, and any file/line references
- Identify the system component (Kafka consumer, Sidekiq job, controller,
  migration, spec, etc.)
- Extract any identifiers that can be searched in git (topic names, class
  names, method names, config keys, SQL table/column names)

**GitHub Actions URL:**
- Use `gh run view <run-id> --log-failed` to fetch the failure output
- Extract the failing step name, error message, and any file references
- Identify the workflow file (`.github/workflows/*.yml`) if relevant

**Other URL:**
- Fetch the page content (WebFetch or `confluence-get.sh` for Confluence)
- Extract the error signal as above

---

## Phase 2 - Trace to the introducing change

Use the identifiers extracted in Phase 1 to find the commit(s) that
introduced the failing code.

**Primary strategy - git log search:**
```bash
git log --all --oneline -S "<identifier>" --
```
Run for each key identifier. The most recent result landing on master is
the change to report.

**Fallback strategies (use as needed):**

- `git log --all --oneline -- <file-path>` when a specific file is implicated
- `git blame <file> -L <start>,<end>` when a specific line range is known
- `gh run view <run-id> --log-failed` + cross-reference workflow YAML for
  CI failures
- Grep the codebase for the symbol/string to locate the relevant file first,
  then blame

Once the introducing commit is identified:

```bash
git show --stat --format="%H%n%an%n%ae%n%ai%n%s" <sha>
```

Extract:
- Full SHA and short SHA (first 10 chars)
- Author name
- Commit date (human-readable, local timezone)
- Subject line - parse PR number `(#NNNNN)` and ticket key `[A-Z]+-[0-9]+`

Also capture the relevant diff section that added the offending code:
```bash
git show <sha> -- <relevant-file>
```

---

## Phase 3 - Build live URLs

Derive the GitHub repo base from `git remote get-url origin`:

- Commit: `https://github.com/<org>/<repo>/commit/<full-sha>`
- PR: `https://github.com/<org>/<repo>/pull/<pr-number>`
- Ticket: `${JIRA_BASE_URL}/browse/<TICKET-KEY>`

For GitHub Actions runs:
- Run: `https://github.com/<org>/<repo>/actions/runs/<run-id>`

---

## Phase 4 - Write the Markdown report

Save to `tmp/investigation-<slug>.md` where `<slug>` is a short kebab-case
description of the issue (e.g. `kafka-acl-domain-care-ops-service`).

Structure:

```markdown
| Version | Timestamp |
|---|---|
| 0.1.0 | <YYYY-MM-DD HH:MM TZ> |

# <Descriptive title>

<One sentence describing what failed and where it was observed, including
a link to the source evidence if a URL was provided.>

## Finding <N>: `<identifier or error name>`

**Error:**
\`\`\`
<error message>
\`\`\`

**Introducing change:** `<short-sha>`

| Field | Value |
|---|---|
| Commit | [<short-sha>](<commit-url>) |
| Author | <name> |
| Date | <date> |
| PR | [#<number>](<pr-url>) |
| Ticket | [<key>](<ticket-url>) |
| PR Title | <subject> |

**What was introduced:**

<Relevant diff excerpt or plain-English description of what the change added.>

**Files changed:** <summary from git show --stat>

---

## Summary

<2-4 sentences: what the findings have in common, why they caused the
failure, and what needs to happen to fix it.>

## Version History

| Version | Updated | Change |
|---|---|---|
| 0.1.0 | <YYYY-MM-DD HH:MM TZ> | Initial findings |
```

Follow all versioning rules from CLAUDE.md (version table at top and
bottom, SemVer, no seconds in timestamps).

---

## Phase 5 - Publish to Confluence

1. Convert the markdown:
   ```bash
   ~/.claude/scripts/confluence-md-to-storage.sh \
     tmp/investigation-<slug>.md /tmp/investigation-<slug>.xhtml
   ```

2. Create or update the page:
   - **New page:** `~/.claude/scripts/confluence-publish-md.sh \
     <folder-id> "<title>" tmp/investigation-<slug>.md`
   - **Existing page (user supplies page ID):**
     `~/.claude/scripts/confluence-update-page.sh \
     <page-id> "<title>" /tmp/investigation-<slug>.xhtml`

3. Print the resulting Confluence page URL to the user.

---

## Notes

- Never use "root cause" language - use "source", "introducing change",
  "what caused it", or "origin" instead. RCA terminology is reserved for
  user-impacting incidents investigated through a formal process.
- If no introducing commit is found for an identifier, say so explicitly.
- If multiple commits are found (feature branch + merge commit), report the
  merge commit that landed on master.
- Quote all identifiers in shell commands - topic names, class names, etc.
  may contain dots, hyphens, or colons.
- For CI failures, always fetch the actual log output with `gh` rather than
  guessing from the workflow YAML alone.
- The Confluence folder ID is visible in the URL:
  `.../wiki/spaces/SE/folder/<ID>?...`
