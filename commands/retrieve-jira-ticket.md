# Jira Ticket Access

Uses `jira` CLI (jira-cli via Homebrew) for reads, curl for writes
and operations the CLI doesn't support.

## Reading Tickets (jira CLI)

### View a ticket

```bash
jira issue view PROJ-1234 --plain
```

### View with comments

```bash
jira issue view PROJ-1234 --comments 5 --plain
```

### Raw JSON (custom fields, ADF structure)

```bash
jira issue view PROJ-1234 --raw
```

Parse specific fields from raw output:

```bash
jira issue view PROJ-1234 --raw | jq '{
  key,
  summary: .fields.summary,
  status: .fields.status.name,
  description: .fields.description
}'
```

## Writing (curl)

The jira CLI uses interactive prompts and markdown-to-ADF conversion
that doesn't give full control over custom fields or ADF structure.
Use curl for writes that need precision.

### Required Environment Variables

```bash
export JIRA_AUTH="${JIRA_USERNAME}:${JIRA_API_TOKEN}"
```

### Create a ticket

```bash
curl -sS -X POST -u "${JIRA_AUTH}" \
  -H "Content-Type: application/json" \
  "${JIRA_BASE_URL}/rest/api/3/issue" \
  -d '{
    "fields": {
      "project": {"key": "PROJECT"},
      "summary": "fix(component): short title",
      "issuetype": {"name": "Task"},
      "description": {
        "type": "doc",
        "version": 1,
        "content": [
          {
            "type": "paragraph",
            "content": [{"type": "text", "text": "Ticket details"}]
          }
        ]
      }
    }
  }' | jq '{id, key, self}'
```

### Update ticket description

```bash
TICKET_KEY="PROJECT-1234"
curl -sS -X PUT -u "${JIRA_AUTH}" \
  -H "Content-Type: application/json" \
  "${JIRA_BASE_URL}/rest/api/3/issue/${TICKET_KEY}" \
  -d '{
    "fields": {
      "description": {
        "type": "doc",
        "version": 1,
        "content": [
          {
            "type": "paragraph",
            "content": [{"type": "text", "text": "Updated details"}]
          }
        ]
      }
    }
  }'
```

### Add a comment (with ADF formatting)

```bash
TICKET_KEY="PROJECT-1234"
curl -sS -X POST -u "${JIRA_AUTH}" \
  -H "Content-Type: application/json" \
  "${JIRA_BASE_URL}/rest/api/3/issue/${TICKET_KEY}/comment" \
  -d '{
    "body": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "paragraph",
          "content": [{"type": "text", "text": "Comment text"}]
        }
      ]
    }
  }' | jq '{id, created}'
```

### Add a simple comment (jira CLI)

For plain text or simple markdown comments, the CLI is fine:

```bash
jira issue comment add PROJ-1234 "Simple comment text"

# Multi-line
jira issue comment add PROJ-1234 $'Line one\n\nLine two'

# From a file
jira issue comment add PROJ-1234 --template /path/to/comment.md
```

### Attach a file

```bash
TICKET_KEY="PROJECT-1234"
FILE_PATH="/path/to/file.md"
curl -sS -X POST -u "${JIRA_AUTH}" \
  -H "X-Atlassian-Token: no-check" \
  -F "file=@${FILE_PATH}" \
  "${JIRA_BASE_URL}/rest/api/3/issue/${TICKET_KEY}/attachments" | jq '.[] | {id, filename, size}'
```

### Delete an attachment

```bash
ATTACHMENT_ID="10001"
curl -sS -X DELETE -u "${JIRA_AUTH}" \
  "${JIRA_BASE_URL}/rest/api/3/attachment/${ATTACHMENT_ID}"
```

## Search (curl)

The old `GET /rest/api/3/search?jql=...` API has been removed.
Use the `POST /rest/api/3/search/jql` endpoint.

### List children of an epic

```bash
EPIC_KEY="PROJECT-1000"
curl -sS -X POST -u "${JIRA_AUTH}" \
  -H "Content-Type: application/json" \
  "${JIRA_BASE_URL}/rest/api/3/search/jql" \
  -d "{\"jql\":\"parent=${EPIC_KEY}\",\"fields\":[\"summary\",\"status\"]}" | \
  jq '.issues[] | {key, summary: .fields.summary, status: .fields.status.name}'
```

### JQL search (general)

```bash
JQL="project = SEP AND status = 'In Progress'"
curl -sS -X POST -u "${JIRA_AUTH}" \
  -H "Content-Type: application/json" \
  "${JIRA_BASE_URL}/rest/api/3/search/jql" \
  -d "{\"jql\":\"${JQL}\",\"fields\":[\"summary\",\"status\"]}" | \
  jq '.issues[] | {key, summary: .fields.summary, status: .fields.status.name}'
```

## When to Use Which

| Operation | Tool | Why |
|---|---|---|
| View ticket | `jira issue view --plain` | One command, auth handled |
| View comments | `jira issue view --comments N` | Clean rendering |
| Raw JSON / custom fields | `jira issue view --raw` | Same data as curl, less boilerplate |
| Simple comment | `jira issue comment add` | Handles markdown conversion |
| ADF-formatted writes | curl | Full control over ADF structure |
| Custom field updates | curl | CLI doesn't expose all fields |
| Attachments | curl | CLI doesn't support attachments |
| JQL search | curl | CLI search is board-scoped |
