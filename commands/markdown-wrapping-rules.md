# Markdown Wrapping Rules

## When to Wrap Text

**ONLY wrap to 80 columns for:**
- Git commit messages (body text only, not the subject line)
- GitHub Pull Request descriptions (body text only, not the title)

## When NOT to Wrap Text

**DO NOT wrap text for:**
- Skills files in `~/.claude/skills/`
- Command files in `~/.claude/commands/`
- JIRA ticket descriptions
- JIRA ticket comments
- Slack messages
- Code comments
- README files (unless explicitly for commit/PR)
- Any other markdown documentation
- Markdown tables (never wrap these - they break)

## Why This Rule Exists

Git commit messages and PR descriptions are viewed in terminal windows and standard Git tools, which benefit from 80-column wrapping for readability. All other content is viewed in tools that handle text wrapping automatically (web browsers, IDEs, Slack, JIRA), so manual wrapping is unnecessary and can actually make editing harder.

## Line Length Limits

- **Commit message subject**: No wrapping, but keep under ~50 characters when possible
- **PR title**: No wrapping
- **Commit/PR body text**: Wrap to 80 columns
- **Everything else**: No wrapping, let the viewing tool handle it

## Examples

### ✅ Correct: Wrapped commit message body
```
PROJ-123 Fix authentication bug in login flow

${JIRA_BASE_URL}/browse/PROJ-123

### Purpose

This change resolves an issue where users were unable to log in after
password reset due to incorrect token validation logic in the
authentication middleware.
```


### ✅ Correct: Unwrapped JIRA ticket description
```
### Purpose

This change resolves an issue where users were unable to log in after password reset due to incorrect token validation logic in the authentication middleware.
```

### ❌ Incorrect: Wrapping a skills file
```
# Bad - don't do this
This is a skill file and should not be wrapped to 80 columns like this
because it makes editing difficult and provides no benefit.
```

### ✅ Correct: Unwrapped skills file
```
# Good - natural line breaks
This is a skill file and should not be wrapped to 80 columns like this because it makes editing difficult and provides no benefit.
```
