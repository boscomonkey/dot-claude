#!/usr/bin/env bash
# Render Mermaid diagrams embedded in a Confluence storage XHTML file to PNGs and
# rewrite the file so each Mermaid block becomes an <ac:image> referencing an
# attachment. Prints the generated PNG paths (one per line, stdout) so the caller
# can attach them to the page (e.g. via confluence-attach.sh).
#
# Input is storage XHTML as produced by confluence-md-to-storage.sh, in which a
# ```mermaid fence has become a code macro (ac:name="code", language=mermaid).
# This is the Option-B Mermaid path: Confluence has no native Mermaid renderer,
# so we pre-render locally and embed the image (no external service / data egress).
#
# Usage: confluence-render-mermaid.sh <STORAGE_XHTML> <IMG_OUT_DIR>
#   Rewrites <STORAGE_XHTML> in place; writes mermaid-<n>.png into <IMG_OUT_DIR>.
#   No-op (prints nothing) if the file contains no Mermaid blocks.
#
# Requires: mmdc (npm install -g @mermaid-js/mermaid-cli), python3.

set -eo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $(basename "$0") <STORAGE_XHTML> <IMG_OUT_DIR>" >&2
    exit 2
fi

storage="$1"
out_dir="$2"

[[ -f "$storage" ]] || { echo "Error: storage file not found: $storage" >&2; exit 1; }
mkdir -p "$out_dir"
command -v mmdc >/dev/null 2>&1 || { echo "Error: mmdc not installed (npm install -g @mermaid-js/mermaid-cli)" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 not installed" >&2; exit 1; }

python3 - "$storage" "$out_dir" <<'PYEOF'
import re, subprocess, sys
from pathlib import Path

storage = Path(sys.argv[1])
out_dir = Path(sys.argv[2])

# Match a Confluence code macro (any attrs) whose language is mermaid, capturing
# the CDATA body. md-to-storage stores the source un-escaped inside CDATA.
MACRO_RE = re.compile(
    r'<ac:structured-macro\b[^>]*\bac:name="code"[^>]*>'
    r'<ac:parameter ac:name="language">([^<]*)</ac:parameter>'
    r'<ac:plain-text-body><!\[CDATA\[(.*?)\]\]></ac:plain-text-body>'
    r'</ac:structured-macro>',
    re.DOTALL,
)

text = storage.read_text()
state = {"n": 0}
generated = []

def repl(m):
    if m.group(1).strip() != "mermaid":
        return m.group(0)
    state["n"] += 1
    n = state["n"]
    src = m.group(2)
    (out_dir / f"mermaid-{n}.mmd").write_text(src)
    png = out_dir / f"mermaid-{n}.png"
    subprocess.run(["mmdc", "-i", str(out_dir / f"mermaid-{n}.mmd"), "-o", str(png), "-b", "white"],
                   check=True, stdout=sys.stderr, stderr=sys.stderr)
    generated.append(png)
    return (f'<ac:image ac:align="center"><ri:attachment ri:filename="mermaid-{n}.png" />'
            f'</ac:image>')

new = MACRO_RE.sub(repl, text)
if state["n"]:
    storage.write_text(new)
    for p in generated:
        print(p)
    print(f"rendered {state['n']} mermaid diagram(s)", file=sys.stderr)
PYEOF
