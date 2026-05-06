# GitHub API Access

## Problem

The `gh` CLI tool does NOT work with the `GITHUB_ACCESS_TOKEN`
environment variable. It looks for `GITHUB_TOKEN` or keyring
credentials, which may be invalid or unavailable.

## Solution

**Always use direct GitHub REST API calls via `curl` with the
`GITHUB_ACCESS_TOKEN` environment variable.**

Never attempt to use the `gh` CLI for GitHub operations. Go directly
to the REST API.

## Common Operations

### Create a Pull Request

```bash
curl -s -X POST \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/OWNER/REPO/pulls" \
  -d @- <<'EOF' | python3 -c "import sys, json; r=json.load(sys.stdin); print(f\"PR created: {r.get('html_url', 'Error: ' + r.get('message', 'Unknown error'))}\")"
{
  "title": "PR title here",
  "head": "branch-name",
  "base": "main",
  "body": "PR description here"
}
EOF
```

### Get Pull Request Details

```bash
curl -s \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/OWNER/REPO/pulls/PR_NUMBER" \
  > /tmp/pr.json

python3 -c "
import json
r = json.load(open('/tmp/pr.json'))
print(f\"PR #{r['number']}: {r['title']}\")
print(f\"URL: {r['html_url']}\")
print(f\"State: {r['state']}\")
"
```

### List Pull Requests

```bash
curl -s \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/OWNER/REPO/pulls?state=open" \
  > /tmp/prs.json

python3 -c "
import json
prs = json.load(open('/tmp/prs.json'))
for pr in prs:
    print(f\"#{pr['number']}: {pr['title']}\")
"
```

### Get PR Comments

```bash
curl -s \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/OWNER/REPO/pulls/PR_NUMBER/comments" \
  > /tmp/comments.json
```

### Merge a Pull Request

```bash
curl -s -X PUT \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/OWNER/REPO/pulls/PR_NUMBER/merge" \
  -d '{
    "commit_title": "Merge PR title",
    "merge_method": "squash"
  }' | python3 -c "import sys, json; r=json.load(sys.stdin); print(f\"Merged: {r.get('merged', False)}\")"
```

### Get Repository Information

```bash
curl -s \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/OWNER/REPO" \
  > /tmp/repo.json
```

### List Issues

```bash
curl -s \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/OWNER/REPO/issues?state=open" \
  > /tmp/issues.json
```

## Key Points

1. **Never use `gh` CLI** - It doesn't work with GITHUB_ACCESS_TOKEN
2. **Always use curl** - Direct REST API access works reliably
3. **Save to /tmp first** - When using Python to parse, save curl
   output to a file to avoid shell escaping issues
4. **Use python3 for parsing** - More reliable than jq for complex
   JSON responses

## GitHub API Documentation

Full REST API documentation:
https://docs.github.com/en/rest

Common endpoints:
- Pulls: https://docs.github.com/en/rest/pulls
- Issues: https://docs.github.com/en/rest/issues
- Repos: https://docs.github.com/en/rest/repos
