#!/usr/bin/env bash

# Read JSON input from Claude Code
input=$(cat)

# Save input for debugging
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
if [ -n "$project_dir" ]; then
    id=$(basename "$project_dir")
else
    id="no-project-dir"
fi
echo "$input" | jq . > "/tmp/claude-statusline-input.$id".json

# Get current directory from JSON input
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Change to the directory
cd "$cwd" 2>/dev/null || exit 0

# Initialize output
output=""

# Add current directory (basename)
output+="$(basename "$cwd")"

# Check if we're in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Get git branch
    branch=$(git -c core.useBuiltinFSMonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ -n "$branch" ]; then
        # Add git branch with symbol (using dimmed colors)
        output+=" $(printf '\033[2m')" # dim
        output+="[$branch]"

        # Get short commit hash (7 chars like your Starship config)
        hash=$(git -c core.useBuiltinFSMonitor=false rev-parse --short=7 HEAD 2>/dev/null)
        if [ -n "$hash" ]; then
            output+=" ($hash)"
        fi
        output+="$(printf '\033[0m')" # reset
    fi
fi

# Add model, cost, and context info (dimmed, separated by pipes)
model_name=$(echo "$input" | jq -r '.model.id // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

parts=()

if [ -n "$used_pct" ]; then
    parts+=("ctx: ${used_pct}%")
fi

# if [ -n "$remaining_pct" ]; then
#     parts+=("${remaining_pct}% free")
# fi

if [ -n "$total_cost" ]; then
    cost_formatted=$(awk "BEGIN {printf \"%.2f\", $total_cost}")
    parts+=("\$${cost_formatted}")
fi

if [ -n "$model_name" ]; then
    parts+=("${model_name}")
fi

if [ ${#parts[@]} -gt 0 ]; then
    output+=" $(printf '\033[2m')" # dim
    first=true
    for part in "${parts[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            output+=" | "
        fi
        output+="$part"
    done
    output+="$(printf '\033[0m')" # reset
fi

echo "$output"
echo

