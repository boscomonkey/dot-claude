#!/usr/bin/env bash
# Create a Linear issue from a markdown description file plus field flags.
#
# Higher-level convenience over linear-create.sh: handles the common case
# (markdown description + a few fields) without requiring the caller to
# pre-assemble an IssueCreateInput JSON file. Use linear-create.sh directly
# if you need full control (custom labels, state transitions, assignees,
# etc.) or have already built the JSON.
#
# Usage:
#   linear-issue-create.sh \
#     --title "..." \
#     --description-file <path-to-md-file> \
#     [--team-id <uuid>] \
#     [--project-id <uuid>] \
#     [--parent-id <uuid>] \
#     [--priority <0-4>] \
#     [--estimate <number>] \
#     [--out <json-file>]
#
# --team-id defaults to $LINEAR_TEAM_ID when set, so callers working
# inside their primary team rarely need to pass it explicitly. Pass
# --team-id to override, or to create issues on a different team.
#
# Priority: 0=No priority, 1=Urgent, 2=High, 3=Medium, 4=Low.
#
# On success, prints {id, identifier, url} JSON. With --out, also writes
# the assembled IssueCreateInput JSON to the named file (useful for audit
# trails and for reusing as a template).
#
# Requires env var:
#   LINEAR_API_KEY - personal API key from Linear settings
#                    (Authorization header is sent verbatim, no Bearer prefix)
#
# Look up team / project / parent UUIDs via linear-graphql.sh, e.g.:
#   linear-graphql.sh '{ teams { nodes { id name key } } }'
#   linear-graphql.sh '{ projects(filter: {slugId: {eq: "<slug>"}}) { nodes { id name } } }'

set -euo pipefail

team_id="${LINEAR_TEAM_ID:-}"
title=""
description_file=""
project_id=""
parent_id=""
priority=""
estimate=""
out_file=""

usage() {
    cat <<EOF >&2
Usage: $(basename "$0") --title TEXT --description-file FILE [options]

Required:
  --title TEXT             Issue title (single line)
  --description-file FILE  Path to a markdown file holding the issue body
  --team-id UUID           Linear team UUID
                           (defaults to \$LINEAR_TEAM_ID if set)

Optional:
  --project-id UUID        Linear project UUID
  --parent-id UUID         Parent issue UUID (creates a sub-issue)
  --priority N             0=No priority, 1=Urgent, 2=High, 3=Medium, 4=Low
  --estimate N             Story-point estimate
  --out FILE               Also write the IssueCreateInput JSON to FILE

Requires LINEAR_API_KEY env var.
EOF
    exit 2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --team-id)          team_id="$2";          shift 2 ;;
        --title)            title="$2";            shift 2 ;;
        --description-file) description_file="$2"; shift 2 ;;
        --project-id)       project_id="$2";       shift 2 ;;
        --parent-id)        parent_id="$2";        shift 2 ;;
        --priority)         priority="$2";         shift 2 ;;
        --estimate)         estimate="$2";         shift 2 ;;
        --out)              out_file="$2";         shift 2 ;;
        -h|--help)          usage ;;
        *)                  echo "Unknown arg: $1" >&2; usage ;;
    esac
done

if [[ -z "$title" || -z "$description_file" ]]; then
    echo "Error: --title and --description-file are required." >&2
    usage
fi

if [[ -z "$team_id" ]]; then
    echo "Error: --team-id is required (or set \$LINEAR_TEAM_ID)." >&2
    usage
fi

if [[ ! -f "$description_file" ]]; then
    echo "Error: description file not found: $description_file" >&2
    exit 1
fi

: "${LINEAR_API_KEY:?LINEAR_API_KEY must be set}"

# Build the IssueCreateInput. Use jq so embedded quotes/newlines in the
# markdown description are escaped correctly. Optional fields are added
# only when set (jq's `+` merge with conditional empty objects).
description="$(cat "$description_file")"

issue_input=$(jq -n \
    --arg teamId "$team_id" \
    --arg title "$title" \
    --arg description "$description" \
    --arg projectId "$project_id" \
    --arg parentId "$parent_id" \
    --arg priority "$priority" \
    --arg estimate "$estimate" \
    '
    {teamId: $teamId, title: $title, description: $description}
    + (if $projectId != "" then {projectId: $projectId} else {} end)
    + (if $parentId  != "" then {parentId:  $parentId } else {} end)
    + (if $priority  != "" then {priority:  ($priority  | tonumber)} else {} end)
    + (if $estimate  != "" then {estimate:  ($estimate  | tonumber)} else {} end)
    ')

if [[ -n "$out_file" ]]; then
    printf '%s' "$issue_input" > "$out_file"
fi

# POST the issueCreate mutation. Mirrors linear-create.sh's call shape so
# the response format stays consistent.
graphql_body=$(jq -n \
    --arg query 'mutation IssueCreate($input: IssueCreateInput!) { issueCreate(input: $input) { success issue { id identifier url } } }' \
    --argjson input "$issue_input" \
    '{query: $query, variables: {input: $input}}')

# Retry transient failures (network errors, HTTP 429 rate-limit, 5xx) with
# linear backoff. Without this, a single rate-limited call silently drops an
# issue when this script is invoked rapidly in a batch loop - Linear's
# burst/complexity limit can reject one mid-batch, and a no-retry curl would
# just exit 1.
max_attempts=5
attempt=0
response=""
while :; do
    attempt=$((attempt + 1))

    # Capture body and HTTP status together; `-w` appends a final line with
    # the status code so we can split it off regardless of body newlines.
    body_and_code=$(curl -sS -w $'\n%{http_code}' -X POST \
        -H "Authorization: ${LINEAR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$graphql_body" \
        https://api.linear.app/graphql) && curl_rc=0 || curl_rc=$?

    if [[ "$curl_rc" -eq 0 ]]; then
        http_code="${body_and_code##*$'\n'}"
        response="${body_and_code%$'\n'*}"
    else
        http_code="000"   # network/transport failure
        response=""
    fi

    # Stop on a successful transport with a non-retryable status.
    if [[ "$curl_rc" -eq 0 && "$http_code" != "429" && ! "$http_code" =~ ^5[0-9][0-9]$ ]]; then
        break
    fi

    if (( attempt >= max_attempts )); then
        echo "Linear request failed after ${attempt} attempts (curl_rc=${curl_rc}, http=${http_code})." >&2
        [[ -n "$response" ]] && echo "$response" | jq . >&2 2>/dev/null || true
        exit 1
    fi

    sleep_s=$(( attempt * 2 ))
    echo "Transient Linear failure (curl_rc=${curl_rc}, http=${http_code}); retry ${attempt}/${max_attempts} in ${sleep_s}s..." >&2
    sleep "$sleep_s"
done

# Surface GraphQL-level errors (HTTP 200 but `errors` array present).
if echo "$response" | jq -e 'has("errors")' >/dev/null; then
    echo "Linear API returned errors:" >&2
    echo "$response" | jq '.errors' >&2
    exit 1
fi

if ! echo "$response" | jq -e '.data.issueCreate.success' >/dev/null; then
    echo "issueCreate did not report success:" >&2
    echo "$response" | jq >&2
    exit 1
fi

echo "$response" | jq '.data.issueCreate.issue'
