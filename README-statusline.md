# Claude Code Status Line Configuration

This directory contains the configuration for Claude Code's
custom status line display.

## Files Created

### `statusline-command.sh`
A bash script that generates the status line content. This
script:

- Receives JSON input from Claude Code containing workspace
  information
- Extracts the current working directory
- Displays the directory basename
- If in a git repository, displays:

    - Git branch name in brackets `[branch-name]`
    - Git commit hash (7 characters) in parentheses `(1234567)`
    - Uses dimmed ANSI colors for git information

- Displays session cost metrics:

    - Total cost in USD (rounded to 2 decimal places)
    - Total duration and API duration in seconds (format:
      `total / api`)
    - Lines added/removed (only shown if non-zero)
    - Warning if session exceeds 200k tokens
- Uses `-c core.useBuiltinFSMonitor=false` for performance
  (skips optional git locks)

The script was made executable with `chmod +x`.

### `settings.json`
Claude Code settings file that configures the status line to
use the custom command script. The configuration specifies:

- `type: "command"` - Uses a shell command for status line
  generation
- `command` - Points to the `statusline-command.sh` script

## Status Line Display Format

When working in a git repository with cost metrics, the status
line displays:

```
directory-name [branch-name] (commit-hash) [$cost |
total_duration / api_duration | +lines_added/-lines_removed]
```

Example:
```
my-project [PROJ-1234-my-feature] (bad5202) [$0.05 | 385.0s /
25.7s | +42/-18]
```

When not in a git repository:
```
directory-name [$cost | total_duration / api_duration]
```

Note: Line changes (+/-) are only displayed when non-zero. If
the session exceeds 200k tokens, `| >200k tokens` will be
appended to the metrics.

## Design Rationale

The configuration was designed to mirror your Starship prompt
setup, which shows git branch and commit information. The
status line provides at-a-glance context about your current
working directory and git state while using Claude Code.

## Customization

To modify the status line display:

1. Edit `statusline-command.sh` to change what information is
   displayed
1. The script can access workspace information via JSON input
   from Claude Code
1. Use ANSI escape codes for colors/formatting if desired

## Created

2025-10-02 by Claude Code statusline-setup agent
