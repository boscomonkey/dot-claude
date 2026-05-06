Evaluate an AI code review and produce a structured evaluation document.

## Input

The argument `$ARGUMENTS` is either:

- A file path to a review `.md` file (e.g., `tmp/review-PROJ-1234.md`)
- A GitHub PR URL (e.g., `https://github.com/org/repo/pull/123`)
- A GitHub comment URL (e.g., `https://github.com/org/repo/pull/123#issuecomment-456`)

If a URL is provided, fetch comment bodies using `gh api`. Check both inline
review comments (`pulls/{n}/comments`) and issue-level comments
(`issues/{n}/comments`) since AI reviewers may post in either location.

## Process

For each finding in the review:

1. **Assess validity** - Is the finding technically correct? Does it apply to this code?
2. **Check for prior art** - Was this already addressed in a previous review round, a different PR in the stack, or an existing TODO/comment?
3. **Determine verdict:**
   - **Fix** - Valid finding, worth addressing. Classify as code change or comment-only.
   - **No-fix** - Push back with a clear rationale (already addressed, pre-existing issue, speculative, over-defensive, etc.)
4. **For fixes:** describe what will change concisely.
5. **For no-fixes:** write supporting analysis with evidence. No separate "Response" field - the analysis itself is the response.

## Output

Write the evaluation to a `.md` file in `tmp/`. Use the naming convention
`evaluate-{reviewer}-{ticket}-round{N}.md` (e.g., `evaluate-ai-PROJ-1234-round6.md`).

Use this exact structure:

```markdown
# {Reviewer} Round {N} Review Feedback - {Ticket}

**Version:** 1.0.0
**Timestamp:** {YYYY-MM-DDThh:mm}

**PR:** #{number} ({PR title})
**Reviewer:** {reviewer username}
**Review date:** {YYYY-MM-DD}
**Source:** {where the findings came from, e.g., "Summary comment (#issuecomment-NNN) + 2 inline comments"}

| # | Finding | Severity | Verdict | Action |
| -- | -- | -- | -- | -- |
| 1 | Short description | Critical/Warning/Minor | Fix/No-fix | One-line action or rationale |
| 2 | ... | ... | ... | ... |

---

## Fix ({count} findings)

### {N}. {Finding title}

**Severity:** {as reported by reviewer}
**Verdict:** Fix

{One sentence summarizing why this is valid and what to change.}

{Optional 1-2 sentences of supporting detail if the fix is non-obvious.}

**Fix:** {Concise description of the change.}

---

## No-fix ({count} findings)

### {N}. {Finding title}

**Severity:** {as reported by reviewer}
**Verdict:** Push back - {brief reason}

{One sentence summarizing why this should not be fixed.}

{1-3 sentences of supporting evidence: existing tests, prior round fixes,
pre-existing code, architectural constraints. Reference specific line numbers,
commit SHAs, or comment IDs where applicable.}

{If this is a repeat from a prior round, state so on its own line:
"Repeat of {prior round reference}."}
```

## Finding structure

Each finding subsection follows this order:

1. **Severity** and **Verdict** on their own bold lines
2. A standalone summary sentence (the "at a glance" takeaway)
3. Supporting detail paragraphs with evidence
4. For repeats: a final line citing the prior round/comment
5. For fixes: a **Fix:** line describing the change

Do NOT add a separate **Response:** or **TL;DR:** field. The summary sentence
after the verdict serves as the at-a-glance takeaway; the supporting detail
is the full response. Avoid redundancy between the summary and detail.

## Rules

- The summary table at the top is the quick-scan overview - a reviewer should
  be able to decide whether to read further based on the table alone.
- Lead each verdict with evidence, not opinion. "The test already calls
  `json.loads(payload)` and succeeds" is better than "I don't think this
  is a real issue."
- When a finding repeats from a prior round, say so explicitly:
  "Repeat of pre-rebase comment ID `NNN`" or
  "Same as round N, finding M. Already addressed with {commit/comment}."
- Severity labels come from the reviewer's classification, not yours.
  Your job is the verdict and action, not re-grading severity.
- Keep fix descriptions to one sentence when possible.
- Group test suggestions under whichever section (Fix or No-fix) applies.
- Bump the major version when the evaluation is rewritten to cover additional
  findings (e.g., from a different comment source). Bump the minor version
  for editorial updates to existing content.
- After writing the evaluation, tell the user it's ready for review and
  wait for approval before implementing any fixes.
