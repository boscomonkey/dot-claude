# Commit Message and PR Description Format

## Commit Message Format

```
TICKET-ID Brief description of changes

<ticket-url>

### Purpose

Clear explanation of what the change accomplishes and why it's needed.
Wrap text to 80 columns for readability.

### Validating

* Bullet point list of steps to verify the changes work correctly
* Include testing instructions, build verification, or functionality
  checks
* Each bullet should be actionable and specific

### Background context

Additional context about the problem being solved, technical decisions
made, or historical information that helps reviewers understand the
change. Explain the "why" behind the implementation approach.

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Pull Request Format

### Title
- **Format**: Same as first line of commit message
- **Important**: PR titles should NOT be wrapped (keep on single line)
- **Example**: `PROJ-123 Update base image to use Debian bookworm instead of bullseye`

### Description
- **First line**: Direct link to the ticket (Jira, Linear, or other tracker)
- **Content**: Everything after the ticket URL from the commit message
- **Wrapping**: No wrapping - GitHub wraps merge message lines automatically
- **Structure**: Same three sections (Purpose, Validating, Background context)

### Example PR Description

```
https://linear.app/example/issue/PROJ-123

### Purpose

Switch the app's Docker base image from deprecated Debian bullseye to bookworm to ensure compatibility with current Ruby 3.4.6 image availability and maintain security support.

### Validating

* Verify Docker image builds successfully with `ruby:3.4.6-slim-bookworm` base image
* Test that all package dependencies install correctly on bookworm
* Confirm development and production containers function as expected

### Background context

While waiting for `ruby:3.4.6-slim-bullseye` to become available, we discovered that Debian bullseye has been deprecated in favor of bookworm. This update ensures the app uses a supported base image with active security updates and package availability.

🤖 Generated with [Claude Code](https://claude.ai/code)
```

## Key Guidelines

1. **Ticket Reference**: Always include ticket ID and URL
2. **80-Column Wrapping**: Wrap commit message body text to 80 columns; PR description body text does not need wrapping (GitHub wraps automatically)
3. **Clear Structure**: Use the three-section format consistently
4. **Actionable Validation**: Provide specific testing steps
5. **Context**: Explain the "why" behind changes
6. **Claude Attribution**: Include the standard Claude Code footer