# Create Discovery Article

When the user asks to create a Discovery Article, follow this process to capture research and discoveries in a format that can easily be transformed into JIRA tickets or Confluence pages.

## Purpose

Discovery Articles document research, investigation, or exploration of technical topics. They serve as:
- Temporary research documentation (stored in /tmp/ for auto-cleanup)
- Pre-cursors to JIRA tickets or Confluence pages
- Knowledge capture that may or may not be acted upon

## Article Structure

Use this structure, which maps cleanly to JIRA/Confluence:

```
# [Topic Title]

## Summary

[1-2 sentence overview of what was researched and why]

## Background

[Context explaining why this research was needed, what problem it addresses, or what question it answers]

## Findings

[Main research discoveries, organized as needed with subheadings]

### [Subtopic 1]

[Details, explanations, examples]

### [Subtopic 2]

[Details, explanations, examples]

## Code Examples

[If applicable, include code snippets demonstrating concepts]

## Conclusions

[Summary of key takeaways, what was learned]

## Next Steps

[Optional: Potential follow-up actions, further research needed, or implementation tasks]

## References

- [Source 1](url)
- [Source 2](url)
```

## Formatting Rules

To ensure Atlassian compatibility:

1. **Text wrapping - CRITICAL**: Do NOT wrap text at any line length - use full-width lines
   - ✅ **CORRECT**: Paragraphs flow on a single line regardless of length
   - ✅ **CORRECT**: Bullet point descriptions flow on a single line
   - ✅ **CORRECT**: Numbered list items flow on a single line
   - ❌ **WRONG**: Wrapping paragraphs at 72 or 80 characters (that's for commit messages/PRs only)
   - ❌ **WRONG**: Breaking bullet point text across multiple lines
   - **Why**: Discovery articles are NOT commit messages or PR descriptions - they should flow naturally for reading in editors and Confluence

2. **Headers**: Use # syntax (supported in both Markdown and Atlassian)

3. **Code blocks**: Use ``` with language identifier

4. **Lists**: Use * or - for bullet lists, numbers for ordered lists
   - Each list item's text should flow on a single line, not wrapped
   - Example:
     ```
     ✅ CORRECT:
     - This is a bullet point with a long description that flows naturally on one line without wrapping even if it's quite lengthy

     ❌ WRONG:
     - This is a bullet point with a long description that has been
       wrapped at 72 characters which makes it harder to read
     ```

5. **Bold/Italic**: Use **bold** and *italic* (Atlassian compatible)

6. **Links**: Use [text](url) format

7. **Tables**: Use standard Markdown tables
   - Confluence will convert these to HTML tables automatically
   - First row becomes header row
   - Separator row (with dashes) is required in Markdown, will be removed in Confluence
   - Example:
     ```
     | Column 1 | Column 2 | Column 3 |
     |----------|----------|----------|
     | Data 1   | Data 2   | Data 3   |
     ```

8. **Mermaid Diagrams**: Use for flowcharts, sequence diagrams, and other visualizations
   - Wrap diagrams in ` ```mermaid` code blocks
   - When uploading to Confluence, these will be converted to PNG images automatically
   - Supported diagram types: graph, sequenceDiagram, flowchart, etc.
   - Example:
     ```
     ```mermaid
     graph TD
         A[Start] --> B[Process]
         B --> C[End]
     ```
     ```
   - **Important**: Mermaid diagrams must be converted to PNG images before Confluence upload (see "Transformation to Atlassian" section)

9. **Avoid**:
   - HTML tags (use Markdown equivalents)
   - Complex nested formatting
   - Non-standard Markdown extensions
   - Line wrapping at any fixed width (72, 80, etc.)

## File Naming and Location

- **Location**: Save all Discovery Articles to `/tmp/`
- **Naming convention**: `discovery-[topic-slug].md`
  - Use lowercase with hyphens
  - Keep concise but descriptive
  - Example: `discovery-avroturf-comments-in-schema.md`
  - Example: `discovery-kafka-schema-registry-migration.md`

## Workflow

1. **Conduct research**: Use available tools (WebSearch, WebFetch, Read code, etc.) to gather information
2. **Document findings**: Write the Discovery Article using the structure above
3. **Save to /tmp/**: This allows automatic cleanup if not followed up
4. **Inform user**: Provide the file path and explain:
   - The article is in /tmp/ and will be auto-deleted
   - If valuable, they can create a Confluence page or JIRA ticket from it
   - The format is already Atlassian-compatible for easy transformation

## Example Interaction

User: "Create a Discovery Article on how to embed comments from AvroTurf DSL into the resulting Apache Avro schema file"

Claude response:
1. Conduct research on AvroTurf DSL comment embedding
2. Create /tmp/discovery-avroturf-comments-in-schema.md with findings
3. Inform user: "I've created a Discovery Article at /tmp/discovery-avroturf-comments-in-schema.md. Since it's in /tmp/, it will be automatically cleaned up. If this research is valuable, you can easily transform it into a Confluence page or JIRA ticket - the formatting is already Atlassian-compatible."

## When to Use Discovery Articles

Create Discovery Articles when:
- Investigating a technical approach or solution
- Researching how a library/framework works
- Exploring architectural options
- Documenting findings from debugging or investigation
- Capturing knowledge that may inform future decisions

## Transformation to Atlassian

When ready to move a Discovery Article to JIRA or Confluence:

**For JIRA tickets:**
- Summary section becomes ticket title
- Background/Findings become description
- Next Steps become acceptance criteria or subtasks

**For Confluence pages:**

### Accessing Confluence via API
- Use the guidance in `/retrieve-jira-ticket` skill for proper Confluence API access
- Confluence pages are accessed via the Wiki API: `${JIRA_BASE_URL}/wiki/api/v2/pages/{pageId}`
- Requires `JIRA_USERNAME` and `JIRA_API_TOKEN` environment variables
- Use `?body-format=storage` parameter to get/set page content in Confluence Storage Format

### Converting Markdown to Confluence Storage Format

**Critical Rule: Do NOT convert empty lines to `<p>&nbsp;</p>` tags**

Confluence automatically handles spacing between block elements. When converting markdown to Confluence Storage Format:

1. **Empty lines**: Skip entirely (no output)
   ```python
   # ✅ CORRECT
   elif not line.strip():
       pass  # Skip empty lines

   # ❌ WRONG - Creates excessive vertical whitespace
   elif not line.strip():
       html_parts.append('<p>&nbsp;</p>')
   ```

2. **Block element conversions**:
   - Headers: `# Title` → `<h1>Title</h1>`
   - Paragraphs: `text` → `<p>text</p>`
   - Code blocks: ` ```lang` → `<ac:structured-macro ac:name="code">...</ac:structured-macro>`
   - Lists: `- item` → `<ul><li>item</li></ul>`
   - Links: `[text](url)` → `<a href="url">text</a>`
   - Bold: `**text**` → `<strong>text</strong>`
   - Inline code: `` `code` `` → `<code>code</code>`
   - Tables: Markdown table → HTML `<table><thead><tr><th>...</th></tr></thead><tbody>...</tbody></table>`
   - Mermaid diagrams: ` ```mermaid` → Convert to PNG, upload as attachment, replace with `<ac:image><ri:attachment ri:filename="..." /></ac:image>`

3. **Update process**:
   ```bash
   # Get current version
   curl -s -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
     "${JIRA_BASE_URL}/wiki/api/v2/pages/{pageId}" | jq -r '.version.number'

   # Update with new version number (current + 1)
   curl -X PUT \
     -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{"id": "pageId", "version": {"number": NEW_VERSION}, "body": {"representation": "storage", "value": "HTML_CONTENT"}}' \
     "${JIRA_BASE_URL}/wiki/api/v2/pages/{pageId}"
   ```

4. **Why this matters**: Block elements (headers, paragraphs, code blocks) have natural CSS spacing in Confluence. Adding explicit `<p>&nbsp;</p>` tags creates double spacing and excessive whitespace.

### Converting Markdown Tables to Confluence

**Process:**
1. Detect table rows (lines starting with `|`)
2. First row becomes `<thead>` with `<th>` cells
3. Skip separator row (contains dashes like `|---|---|`)
4. Remaining rows become `<tbody>` with `<td>` cells
5. Preserve inline formatting (bold, code, links) within cells

**Example:**
```python
# Markdown:
| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |

# Converts to:
<table>
  <thead><tr><th>Header 1</th><th>Header 2</th></tr></thead>
  <tbody><tr><td>Cell 1</td><td>Cell 2</td></tr></tbody>
</table>
```

### Converting Mermaid Diagrams to Confluence Images

**Why conversion is needed:** Confluence does not natively support Mermaid diagram rendering. Diagrams must be converted to PNG images and uploaded as attachments.

**Step-by-step process:**

1. **Install mermaid-cli** (one-time setup):
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. **Extract Mermaid diagrams from markdown:**
   ```python
   import re

   pattern = r'```mermaid\n(.*?)```'
   matches = re.findall(pattern, content, re.DOTALL)

   for i, diagram in enumerate(matches):
       with open(f'{article-slug}-diagram-{i}.mmd', 'w') as f:
           f.write(diagram.strip())
   ```

3. **Convert to PNG with transparent background:**
   ```bash
   mmdc -i article-diagram-0.mmd -o article-diagram-0.png -b transparent
   ```

4. **Upload as Confluence attachment** (use v1 API, not v2):
   ```bash
   curl -X POST \
     -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
     -H "X-Atlassian-Token: nocheck" \
     -F "file=@article-diagram-0.png" \
     "${JIRA_BASE_URL}/wiki/rest/api/content/{PAGE_ID}/child/attachment"
   ```

5. **Replace Mermaid code block with image reference** in markdown-to-confluence converter:
   ```python
   # When encountering ```mermaid block during conversion:
   if code_block_lang == 'mermaid':
       # Replace with image macro instead of code macro
       html_parts.append(
           f'<p><ac:image><ri:attachment ri:filename="{image_filename}" /></ac:image></p>'
       )
       image_index += 1
   ```

**Naming convention:**
- Format: `{article-slug}-diagram-{index}.png`
- Example: `03-automated-deployment-diagram-0.png`
- Example: `discovery-kafka-migration-diagram-2.png`

**Important notes:**
- Must upload images BEFORE updating page content with image references
- Use transparent background for better visual integration
- Image filename in `<ri:attachment>` must exactly match uploaded filename
- v1 API endpoint (`/wiki/rest/api/content/{PAGE_ID}/child/attachment`) is required for uploads
- v2 API attachments endpoint returns METHOD_NOT_ALLOWED error

## Important Notes

- **CRITICAL**: Do NOT wrap text in Discovery Articles at any line length (unlike commit message bodies which are wrapped to 80 columns)
  - This applies to ALL text: paragraphs, bullet points, numbered lists, descriptions
  - Let text flow naturally on single lines regardless of length
  - Discovery articles are meant to be read in editors and Confluence, not constrained to terminal width
- Keep formatting simple and Atlassian-compatible
- Focus on clarity and actionability
- Include enough context for someone else to understand the research
- Cite sources with links in References section
