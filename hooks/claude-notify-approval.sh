#!/bin/bash
#
# claude-notify-approval.sh
#
# Purpose: Alert the user when Claude Code is waiting on a permission prompt.
#
# When Claude Code is about to run a tool call that isn't auto-allowed by
# the `permissions.allow` rules in settings.json, it emits a Notification
# event (matcher "permission_prompt"). This hook:
#   1. Brings the iTerm2 tab running Claude Code to the foreground so the
#      prompt is visible
#   2. Posts a macOS Notification Center alert with a short summary and
#      the "Ping" sound
#
# Input (stdin, JSON):
#   {
#     "session_id": "...",
#     "message": "Permission needed to run ..."
#   }
# The "message" field is the human-readable prompt text from Claude Code.
# We extract it with Python (jq would also work) and pass it to
# `display notification`.
#
# How it's wired: `~/.claude/settings.json` points a Notification hook with
# matcher "permission_prompt" at this script. Hook configs only live in:
#   - ~/.claude/settings.json                (user-global)
#   - <project>/.claude/settings.json        (checked-in project config)
#   - <project>/.claude/settings.local.json  (gitignored per-dev overrides)
# There is no separate "hooks registry" file - settings.json IS the registry.
#
# Dependencies: macOS (uses osascript / iTerm2 AppleScript), python3 for
# JSON parsing. Not portable to Linux as-is.
#
# To disable temporarily: remove/comment the hook in settings.json, or run
# Claude Code with `--no-hooks` (if available), or rename this file.
#
read -r INPUT
MESSAGE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message','Approval needed'))")

MY_TTY=$(tty < /dev/tty 2>/dev/null) || MY_TTY="/dev/tty$(ps -o tty= -p $$ | tr -d ' ')"

# Bring the correct iTerm tab to foreground
osascript <<EOF
tell application "iTerm2"
    activate
    repeat with w in windows
        repeat with t in tabs of w
            repeat with s in sessions of t
                if tty of s is "$MY_TTY" then
                    select t
                    set index of w to 1
                    return
                end if
            end repeat
        end repeat
    end repeat
end tell
EOF

# Notification Center alert with the request details
osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\" sound name \"Ping\""
