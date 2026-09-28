#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = ["pymupdf4llm"]
# ///
"""Convert PDF sources (datasheets, journal/SIGGRAPH papers, reports) to
token-efficient RST (or Typst).

Part of the `research-corpus` skill. This is the adapter for the non-arXiv
source topology: manufacturer datasheets, paywalled-but-downloaded papers,
standards docs — anything that arrives as a PDF rather than LaTeX source.

Extraction is via pymupdf4llm (text-based PDFs → structured Markdown), then a
light Markdown→RST/Typst transform so output matches the rest of the corpus.
Scanned/image PDFs need OCR first and are out of scope for v1 (a near-empty
result is the tell — the script warns when output looks too short).

Usage (run from the target repo root):
    pdf_to_rst.py path/to/datasheet.pdf            # → ./references/papers/rst/datasheet.rst
    pdf_to_rst.py raw/holbein/*.pdf                # batch
    pdf_to_rst.py file.pdf --format typst          # → ./references/papers/typst/file.typ
    pdf_to_rst.py file.pdf --out-dir docs/refs     # override output dir

Dependencies: pymupdf4llm (auto-installed by `uv run`).
"""

import argparse
import re
import sys
from pathlib import Path

try:
    import pymupdf4llm
except ImportError:
    sys.exit("pymupdf4llm not found — run: pip install pymupdf4llm")


# ---------------------------------------------------------------------------
# Markdown → RST
# ---------------------------------------------------------------------------

_SECTION_CHARS = ["=", "-", "~", "^", '"', "'"]


def _md_to_rst(md: str) -> str:
    lines = md.splitlines()
    out: list[str] = []
    in_fence = False
    fence_lang = ""
    fence_buf: list[str] = []

    for line in lines:
        fence = re.match(r"^```(\w*)\s*$", line)
        if fence and not in_fence:
            in_fence = True
            fence_lang = fence.group(1)
            fence_buf = []
            continue
        if line.strip() == "```" and in_fence:
            out.append("")
            out.append(".. code-block::" + (f" {fence_lang}" if fence_lang else ""))
            out.append("")
            out.extend("   " + b for b in fence_buf)
            out.append("")
            in_fence = False
            continue
        if in_fence:
            fence_buf.append(line)
            continue

        line = line.replace("<br>", " ")
        # ATX heading → underlined RST title.
        h = re.match(r"^(#{1,6})\s+(.*?)\s*#*\s*$", line)
        if h:
            level = len(h.group(1)) - 1
            title = h.group(2).strip()
            char = _SECTION_CHARS[min(level, len(_SECTION_CHARS) - 1)]
            out.append("")
            out.append(title)
            out.append(char * max(len(title), 4))
            out.append("")
            continue

        # Links [text](url) → `text <url>`_  (bold/italic/code already compatible).
        line = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"`\1 <\2>`_", line)
        # Markdown inline code `x` → RST ``x`` (avoid touching already-double).
        line = re.sub(r"(?<!`)`([^`]+)`(?!`)", r"``\1``", line)
        out.append(line)

    text = "\n".join(out)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


# ---------------------------------------------------------------------------
# Markdown → Typst  (best-effort structural transform)
# ---------------------------------------------------------------------------

def _emph_to_typst(text: str) -> str:
    """Markdown/RST emphasis → Typst: **bold** → *bold*, *italic*/_italic_ → _italic_.

    Uses sentinels so the bold→*..* rewrite isn't re-matched by the italic rule
    (Typst bold is single-star, which collides with Markdown single-star italic).
    """
    text = text.replace("\x00", "").replace("\x01", "")
    text = re.sub(r"\*\*([^*\n]+?)\*\*", "\x00\\1\x01", text)  # bold → sentinel
    text = re.sub(r"(?<![\*\w])\*(?!\*)([^*\n]+?)\*(?!\*)", r"_\1_", text)  # *italic* → _italic_
    return text.replace("\x00", "*").replace("\x01", "*")  # sentinel → Typst bold


def _md_to_typst(md: str) -> str:
    lines = md.splitlines()
    out: list[str] = []
    in_fence = False

    for line in lines:
        if re.match(r"^```", line):
            out.append(line)  # Typst raw fences use the same ``` syntax
            in_fence = not in_fence
            continue
        if in_fence:
            out.append(line)
            continue

        line = line.replace("<br>", " ")
        h = re.match(r"^(#{1,6})\s+(.*?)\s*#*\s*$", line)
        if h:
            out.append("=" * len(h.group(1)) + " " + h.group(2).strip())
            continue

        line = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'#link("\2")[\1]', line)
        line = _emph_to_typst(line)
        out.append(line)

    text = "\n".join(out)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


# ---------------------------------------------------------------------------
# Conversion
# ---------------------------------------------------------------------------

def convert_pdf(pdf: Path, out_dir: Path, fmt: str, force: bool) -> str:
    ext = "typ" if fmt == "typst" else "rst"
    out_file = out_dir / f"{pdf.stem}.{ext}"

    if out_file.exists() and not force:
        print(f"  SKIP  {pdf.name} — already converted (use --force to redo)")
        return "skip"

    try:
        md = pymupdf4llm.to_markdown(str(pdf))
    except Exception as e:
        print(f"  ERROR {pdf.name} — extraction failed: {e}")
        return "error"

    output = _md_to_typst(md) if fmt == "typst" else _md_to_rst(md)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file.write_text(output)

    try:
        rel = out_file.relative_to(Path.cwd())
    except ValueError:
        rel = out_file
    warn = "  ⚠ very short — likely a scanned/image PDF needing OCR" if len(output) < 200 else ""
    print(f"  OK    {pdf.name} → {rel}{warn}")
    return "ok"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("pdfs", nargs="+", help="PDF file(s) to convert")
    parser.add_argument("--format", choices=["rst", "typst"], default="rst", help="Output format (default: rst)")
    parser.add_argument("--out-dir", default=None, help="Output dir (default: ./references/papers/<rst|typst>)")
    parser.add_argument("--force", action="store_true", help="Re-convert existing output")
    args = parser.parse_args()

    sub = "typst" if args.format == "typst" else "rst"
    out_dir = Path(args.out_dir) if args.out_dir else Path.cwd() / "references" / "papers" / sub

    counts = {"ok": 0, "skip": 0, "error": 0}
    for p in args.pdfs:
        path = Path(p)
        if not path.exists():
            print(f"  ERROR {p} — file not found")
            counts["error"] += 1
            continue
        counts[convert_pdf(path, out_dir, args.format, args.force)] += 1

    print(f"\n{counts['ok']} converted, {counts['skip']} skipped, {counts['error']} failed")


if __name__ == "__main__":
    main()
