#!/usr/bin/env bash
# Convert a Markdown file to Confluence storage format (XHTML + ac:* macros).
#
# Usage: confluence-md-to-storage.sh <input.md> <output.xhtml>
# Example: confluence-md-to-storage.sh tmp/note.md tmp/note.storage.xhtml
#
# Pipeline:
#   1. pandoc gfm -> html5 with --syntax-highlighting=none (no <span class>
#      noise; emits clean <pre class="LANG"><code>...</code></pre> blocks).
#   2. Python pass rewrites each <pre><code> block into a Confluence
#      structured-macro code block so syntax highlighting works in-app.
#
# Everything else pandoc emits (tables, headings, lists, links, inline
# <code>, blockquotes, <strong>) is already valid Confluence storage format.
#
# Requires: pandoc, python3.

set -eo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <input.md> <output.xhtml>" >&2
    exit 2
fi

input="$1"
output="$2"

if [[ ! -f "$input" ]]; then
    echo "Error: input file not found: $input" >&2
    exit 1
fi

command -v pandoc >/dev/null 2>&1 || { echo "Error: pandoc not installed (brew install pandoc)" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 not installed" >&2; exit 1; }

tmp_html="$(mktemp -t confluence-md.XXXXXX.html)"
trap 'rm -f "$tmp_html"' EXIT

pandoc -f gfm -t html --syntax-highlighting=none --wrap=none "$input" -o "$tmp_html"

python3 - "$tmp_html" "$output" <<'PYEOF'
"""Wrap pandoc <pre class=LANG><code>...</code></pre> in Confluence code macros."""
from __future__ import annotations
import html
import re
import sys
import uuid
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

CODE_BLOCK_RE = re.compile(
    r'<pre(?:\s+class="([^"]+)")?><code>(.*?)</code></pre>',
    re.DOTALL,
)


def code_macro(match: re.Match) -> str:
    lang = (match.group(1) or "").strip() or "text"
    body = html.unescape(match.group(2))
    macro_id = str(uuid.uuid4())
    return (
        f'<ac:structured-macro ac:name="code" ac:schema-version="1" '
        f'ac:macro-id="{macro_id}">'
        f'<ac:parameter ac:name="language">{lang}</ac:parameter>'
        f'<ac:plain-text-body><![CDATA[{body}]]></ac:plain-text-body>'
        f'</ac:structured-macro>'
    )


raw = src.read_text()
converted = CODE_BLOCK_RE.sub(code_macro, raw)
dst.write_text(converted)
PYEOF

echo "wrote $output ($(wc -c < "$output" | tr -d ' ') bytes)"
