---
name: confluence-publish-md
description: Publish a local Markdown file as a new Confluence page under a given folder or page parent (preserving formatting), and inspect the resulting page's storage content. Use when the user asks to "publish to Confluence", "create a Confluence page from this doc", "upload this markdown to Confluence", "verify the page rendered correctly", or "show me the storage format of page X".
---

# Publishing and inspecting Confluence pages

Use the allowlisted wrapper scripts in `~/.claude/scripts/`. They handle the
pandoc → storage-format → API-call pipeline so future invocations need no
permission prompts.

## When to use

- User asks to publish, upload, or create a Confluence page from a local
  Markdown file.
- User provides a folder or page URL/ID as the destination parent.

## The scripts

All three scripts accept env vars `JIRA_USERNAME`, `JIRA_API_TOKEN`, and
optional `JIRA_BASE_URL` (defaults to `${JIRA_BASE_URL}`).
Confluence uses the same API token as JIRA.

### One-shot publish (most common)

```bash
~/.claude/scripts/confluence-publish-md.sh <PARENT_ID> "<TITLE>" <INPUT_MD>
```

Composes the two scripts below. Prints the new page's `{id, title, webui}`
on success.

### Convert markdown to Confluence storage format

```bash
~/.claude/scripts/confluence-md-to-storage.sh <INPUT_MD> <OUTPUT_XHTML>
```

Produces a Confluence-storage-format file that can be POSTed (for create)
or PUT (for update). Useful when you want to inspect/edit the storage XHTML
before uploading.

### Create a new page from a storage file

```bash
~/.claude/scripts/confluence-create-page.sh <PARENT_ID> "<TITLE>" <STORAGE_XHTML>
```

Auto-resolves `spaceId` from the parent (folder or page). Prints
`{id, title, status, spaceId, parentId, parentType, webui}` on success.

### Inspect a page's stored content

```bash
~/.claude/scripts/confluence-inspect-page.sh <PAGE_ID> [--dump <FILE>]
```

Fetches the page in storage format and prints structural stats as JSON:
title, status, version, parent, space, webui, body byte count, counts of
structured macros (code / info / warning / note / expand), tables, headings
(h1-h4), bullet/ordered lists, links, blockquotes. Use it after a publish
or update to confirm the rendered output matches expectations, or to
diagnose layout problems. With `--dump <FILE>`, also writes the raw storage
XHTML to `<FILE>` for inspection.

## How parent IDs are extracted from URLs

Confluence URLs the user pastes have the parent ID embedded. Extract it
without asking:

| URL shape | Parent ID |
|---|---|
| `.../wiki/spaces/SE/folder/2485420082?...` | `2485420082` |
| `.../wiki/spaces/SE/pages/2479718467/Some-Title?...` | `2479718467` |

Strip `?atlOrigin=...` and any trailing query string before grabbing the
numeric segment.

## Pipeline details (so you understand what is happening)

1. `pandoc -f gfm -t html --syntax-highlighting=none --wrap=none` converts
   the markdown to HTML5 with clean `<pre class="LANG"><code>...</code></pre>`
   blocks (no `<span class>` syntax-highlight noise).
1. A Python pass rewrites those `<pre><code>` blocks into Confluence
   `<ac:structured-macro ac:name="code">` blocks with the language parameter
   and a `CDATA` body. This gives proper syntax highlighting in-app.
1. Everything else pandoc emits (`<table>`, `<thead>`, `<tbody>`, `<h1>`-`<h6>`,
   `<ul>`/`<ol>`/`<li>`, `<a href>`, `<code>`, `<blockquote>`, `<strong>`,
   `<em>`) is already valid Confluence storage format and passes through
   unchanged.
1. The create script auto-discovers the parent's `spaceId` by trying
   `GET /wiki/api/v2/folders/{id}` first, then falling back to
   `GET /wiki/api/v2/pages/{id}`. Either parent type works.
1. `POST /wiki/api/v2/pages` with `body.representation: "storage"` creates
   the page. HTTP 200 means success.

## Limitations to call out

- **Mermaid diagrams** are not auto-converted. If the markdown contains
  ```` ```mermaid ```` blocks they will land in Confluence as a code block
  with language "mermaid" and will not render. Convert separately if needed
  (see the `create-discovery-article` skill for the mermaid-to-PNG flow).
- **Front-matter** (e.g., a top YAML/TOML block delimited by `---`) is not
  stripped by pandoc's gfm reader. If the document uses front-matter, strip
  it before publishing or pandoc will render it as part of the body.
- **Updating** an existing page is not yet wrapped. For updates, use the
  legacy `PUT /wiki/api/v2/pages/{id}` with the next version number, or
  add a `confluence-update-page.sh` wrapper in the same style.
- **Attachments** (images, files) are not handled. Upload separately via
  `POST /wiki/rest/api/content/{pageId}/child/attachment` if needed.

## Don't

- Don't paste raw `curl` POSTs against `/wiki/api/v2/pages` in the shell -
  the JSON-encoded storage value is fiddly and the user has asked for the
  wrappers to avoid permission prompts. Use the scripts.
- Don't try to convert markdown by hand. Pandoc + the python pass cover the
  Markdown features Confluence needs.
- Don't skip the `--syntax-highlighting=none` flag - pandoc's default emits
  `<span>`-based highlighting that Confluence renders as visual noise.
