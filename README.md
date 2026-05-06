# Claude Code Configuration

Personal configuration for [Claude Code](https://claude.ai/code), Anthropic's CLI for Claude.

## Setup

1. Clone this repo to `~/.claude/`
2. Append the env var template to your private profile and fill in your values:
   ```bash
   cat ~/.claude/.nocommit_profile.example >> ~/.nocommit_profile
   # Edit ~/.nocommit_profile and replace the placeholder values with your real credentials
   ```
3. Source it from your shell profile (`~/.zshrc` or `~/.bashrc`):
   ```bash
   [ -f ~/.nocommit_profile ] && source ~/.nocommit_profile
   ```

`~/.nocommit_profile` is listed in `.gitignore` so your credentials stay local and are never committed.

## Directory Structure

```
~/.claude/
├── CLAUDE.md                 # Global instructions for Claude
├── settings.json             # Claude Code settings
├── statusline-command.sh     # Custom status line script
├── commands/                 # Custom slash commands (skills)
└── skills/                   # Additional skill definitions
```

## Key Files

### CLAUDE.md

Global instructions that apply to all Claude Code sessions:

- API integrations (JIRA, Linear, GitHub via environment variables)
- Formatting preferences (80-column wrapping for commits/PRs)
- Commit message and PR description conventions
- Policy: org-specific values live in `~/.nocommit_profile`, not hardcoded here

### settings.json

Claude Code settings:

- Default model: `opus`
- Custom status line via shell command

### statusline-command.sh

Custom status line that displays:

- Current directory name
- Git branch and short commit hash
- Session cost, duration, and API time
- Lines added/removed
- Context window usage percentage

Example output:
```
my-project [main] (abc1234) [$0.42 | 120.5s / 45.2s | +15/-3] [ctx: 12%]
```

See [README-statusline.md](README-statusline.md) for details.

## Commands

Custom slash commands in `commands/`:

| File | Purpose |
| ---- | ------- |
| `format-commit-pr-message.md` | Template for first commit/PR messages |
| `format-subsequent-messages.md` | Template for follow-up commits |
| `github-api-access.md` | GitHub API via `gh` CLI with PAT |
| `organization-cultural-values.md` | Display org cultural values (reads from `$CULTURAL_VALUES`) |
| `markdown-wrapping-rules.md` | Markdown formatting conventions |
| `retrieve-jira-ticket.md` | JIRA API access via curl |

## Skills

Custom skills in `skills/`:

| File | Purpose |
| ---- | ------- |
| `add-cultural-values-to-ticket.md` | Add cultural values alignment to tickets (reads values from `$CULTURAL_VALUES`) |
| `create-discovery-article.md` | Discovery article creation workflow |

## Ignored Files

The `.gitignore` excludes ephemeral data:

- `cache/`, `debug/`, `todos/` - Runtime data
- `history.jsonl` - Conversation history
- `projects/`, `plugins/` - Per-project config
- `statsig/` - Analytics

## Environment Variables

All required env vars are documented in `.nocommit_profile.example` with descriptions and placeholder values. See the Setup section above.

**Policy:** Never hardcode org-specific values directly in `~/.claude` files. Define them as env vars in `~/.nocommit_profile` and reference them by `$VAR_NAME`. When adding a new var, also add it to `.nocommit_profile.example` so other users know it's required.
