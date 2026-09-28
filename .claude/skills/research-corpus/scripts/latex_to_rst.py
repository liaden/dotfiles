#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = ["pylatexenc"]
# ///
"""Convert arXiv LaTeX source tarballs to token-efficient RST (or Typst).

Part of the `research-corpus` skill. Unlike the repo-local original this lives in
the skill directory, so all output paths resolve against the *current working
directory* (the repo you are building a corpus for), not the script location.

Usage (run from the target repo root):
    latex_to_rst.py                       # convert every tarball in ./references/papers/src
    latex_to_rst.py 2410.09958            # convert one
    latex_to_rst.py 2410.09958 --force    # re-convert
    latex_to_rst.py --format typst        # emit .typ into ./references/papers/typst
    latex_to_rst.py --papers-dir path/to/papers   # override the papers/ base dir

Layout (under --papers-dir, default ./references/papers):
    src/<id>.tar.gz   input tarballs
    rst/<id>.rst      RST output   (default)
    typst/<id>.typ    Typst output (--format typst)

Dependencies: pylatexenc (auto-installed by `uv run`).
"""

import argparse
import re
import sys
import tarfile
import tempfile
from pathlib import Path

try:
    from pylatexenc.latex2text import (
        LatexNodes2Text,
        MacroTextSpec,
        EnvironmentTextSpec,
        get_default_latex_context_db,
    )
except ImportError:
    sys.exit("pylatexenc not found — run: pip install pylatexenc")

SECTION_CHARS = ["=", "-", "~", "^", '"', "'"]


# ---------------------------------------------------------------------------
# RST helpers
# ---------------------------------------------------------------------------

def rst_title(text: str, level: int) -> str:
    char = SECTION_CHARS[min(level, len(SECTION_CHARS) - 1)]
    line = char * max(len(text), 4)
    if level == 0:
        return f"{line}\n{text}\n{line}"
    return f"{text}\n{line}"


def rst_math_block(expr: str) -> str:
    indented = "\n".join("   " + l for l in expr.strip().splitlines())
    return f"\n\n.. math::\n\n{indented}\n\n"


def _arg_text(node, l2tobj, idx=0):
    """Extract text from argument slot idx of a macro node."""
    try:
        argnlist = node.nodeargd.argnlist
        arg = argnlist[idx]
        if arg is None:
            return ""
        if hasattr(arg, "nodelist"):
            return l2tobj.nodelist_to_text(arg.nodelist)
        return l2tobj.node_to_text(arg)
    except (AttributeError, IndexError, TypeError):
        return ""


def _mandatory_arg_text(node, l2tobj):
    """Text of the mandatory {..} argument.

    Sectioning commands parse as argspec ``*[{`` (star, optional short title,
    mandatory title), so the title lives in the last slot, not slot 0. Reading
    slot 0 silently dropped every section/caption title.
    """
    try:
        args = node.nodeargd.argnlist
    except AttributeError:
        return ""
    brace = [a for a in args if a is not None and getattr(a, "delimiters", None) == ("{", "}")]
    if brace:
        return l2tobj.nodelist_to_text(brace[-1].nodelist)
    for a in reversed(args):
        if a is not None:
            return l2tobj.nodelist_to_text(a.nodelist) if hasattr(a, "nodelist") else l2tobj.node_to_text(a)
    return ""


def _reformat_list(text: str, numbered: bool = False) -> str:
    items = re.split(r"(?m)^\s*•\s*|\n\s*\\item\s*|^\\item\s*", text)
    result = []
    for i, item in enumerate(items):
        item = item.strip()
        if not item:
            continue
        prefix = f"{i}. " if numbered else "- "
        result.append(prefix + item.replace("\n", "\n  "))
    return "\n".join(result)


# ---------------------------------------------------------------------------
# Custom macro/environment specs  (pylatexenc v2: second arg is l2tobj=)
# ---------------------------------------------------------------------------

def _section_handler(level):
    def handler(node, l2tobj=None):
        title = _mandatory_arg_text(node, l2tobj).strip()
        return f"\n\n{rst_title(title, level)}\n\n"
    return handler


def _math_env_handler(node, l2tobj=None):
    content = l2tobj.nodelist_to_text(node.nodelist) if l2tobj else ""
    return rst_math_block(content)


def _cite_handler(node, l2tobj=None):
    # Grab the last brace group (the citation keys), robust to natbib optional
    # args like \citep[see][p.3]{key} where arg slot 0 is the optional [see].
    try:
        raw = node.latex_verbatim()
    except Exception:
        raw = ""
    m = re.search(r"\{([^{}]*)\}\s*$", raw)
    if not m:
        return ""
    keys = [k.strip() for k in m.group(1).split(",") if k.strip()]
    return " ".join(f"[{k}]_" for k in keys)


def _caption_handler(node, l2tobj=None):
    text = _mandatory_arg_text(node, l2tobj).strip()
    return f"\n\n*Caption:* {text}\n\n" if text else "\n"


def _ref_handler(node, l2tobj=None):
    key = _arg_text(node, l2tobj, 0).strip()
    return f":ref:`{key}`"


def _figure_env_handler(node, l2tobj=None):
    raw = l2tobj.nodelist_to_text(node.nodelist) if l2tobj else ""
    m = re.search(r"\\caption\{([^}]*)\}", raw)
    caption = m.group(1).strip() if m else ""
    return f"\n\n.. figure::\n\n   {caption}\n\n" if caption else "\n"


# ---------------------------------------------------------------------------
# Table support — preserve tabular data as pipe-delimited rows.
# Dropping tables loses the numeric core of most papers (formant values,
# accuracy scores, feature rankings), so we render them instead.
# ---------------------------------------------------------------------------

# Leading column spec like {lcc}, {l|c|r}, {lp{2cm}c} — colspec chars only, so a
# real first cell such as {\bf Header} is not mistaken for a spec and stripped.
_COLSPEC_RE = re.compile(r"^\s*\{[lcrpmbXyghs|@!()0-9.\s*<>{}]*\}")
_RULE_RE = re.compile(
    r"\\(?:hline|toprule|midrule|bottomrule|cmidrule|cline|specialrule|addlinespace)\b"
    r"(?:\{[^}]*\}|\([^)]*\)|\[[^]]*\])*"
)
_MULTICOL_RE = re.compile(r"\\multicolumn\s*\{[^}]*\}\s*\{[^}]*\}\s*\{")
_MULTIROW_RE = re.compile(r"\\multirow\s*\{[^}]*\}\s*\{[^}]*\}\s*\{")


def _balanced_from(s: str, open_idx: int):
    """Given s[open_idx] == '{', return (inner_text, index_after_matching_close)."""
    depth = 0
    for i in range(open_idx, len(s)):
        if s[i] == "{":
            depth += 1
        elif s[i] == "}":
            depth -= 1
            if depth == 0:
                return s[open_idx + 1 : i], i + 1
    return s[open_idx + 1 :], len(s)


def _strip_span_macros(cell: str) -> str:
    """Reduce \\multicolumn{n}{spec}{X} and \\multirow{n}{w}{X} to their content X."""
    for rx in (_MULTICOL_RE, _MULTIROW_RE):
        while True:
            m = rx.search(cell)
            if not m:
                break
            content, end = _balanced_from(cell, m.end() - 1)
            cell = cell[: m.start()] + content + cell[end:]
    return cell


def _tabular_env_handler(node, l2tobj=None):
    if l2tobj is None:
        return ""
    try:
        body = "".join(n.latex_verbatim() for n in node.nodelist)
    except Exception:
        return ""
    body = _COLSPEC_RE.sub("", body, count=1)
    body = _RULE_RE.sub("", body)
    rows_out = []
    for raw_row in re.split(r"(?<!\\)\\\\", body):
        raw_row = raw_row.strip()
        if not raw_row:
            continue
        cells = re.split(r"(?<!\\)&", raw_row)
        texts = []
        for cell in cells:
            cell = _strip_span_macros(cell)
            try:
                txt = l2tobj.latex_to_text(cell)
            except Exception:
                txt = cell
            texts.append(" ".join(txt.split()))
        if any(texts):
            rows_out.append("| " + " | ".join(texts) + " |")
    if not rows_out:
        return ""
    return "\n\n" + "\n".join(rows_out) + "\n\n"


def _table_float_handler(node, l2tobj=None):
    """Keep the caption and recurse so the inner tabular is rendered."""
    if l2tobj is None:
        return ""
    return "\n\n" + l2tobj.nodelist_to_text(node.nodelist) + "\n\n"


CUSTOM_MACROS = [
    # Sectioning
    MacroTextSpec("title",         simplify_repl=lambda n, l2tobj=None: f"\n\n{rst_title(_mandatory_arg_text(n, l2tobj).strip(), 0)}\n\n"),
    MacroTextSpec("section",       simplify_repl=_section_handler(1)),
    MacroTextSpec("subsection",    simplify_repl=_section_handler(2)),
    MacroTextSpec("subsubsection", simplify_repl=_section_handler(3)),
    MacroTextSpec("paragraph",     simplify_repl=_section_handler(4)),
    # Inline formatting
    MacroTextSpec("textbf",    simplify_repl=lambda n, l2tobj=None: f"**{_arg_text(n, l2tobj, 0).strip()}**"),
    MacroTextSpec("textit",    simplify_repl=lambda n, l2tobj=None: f"*{_arg_text(n, l2tobj, 0).strip()}*"),
    MacroTextSpec("emph",      simplify_repl=lambda n, l2tobj=None: f"*{_arg_text(n, l2tobj, 0).strip()}*"),
    MacroTextSpec("texttt",    simplify_repl=lambda n, l2tobj=None: f"``{_arg_text(n, l2tobj, 0).strip()}``"),
    MacroTextSpec("underline", simplify_repl=lambda n, l2tobj=None: _arg_text(n, l2tobj, 0)),
    # Citations
    MacroTextSpec("cite",     simplify_repl=_cite_handler),
    MacroTextSpec("citep",    simplify_repl=_cite_handler),
    MacroTextSpec("citet",    simplify_repl=_cite_handler),
    MacroTextSpec("citealp",  simplify_repl=_cite_handler),
    MacroTextSpec("citealt",  simplify_repl=_cite_handler),
    # Cross-refs
    MacroTextSpec("label",  simplify_repl=""),
    MacroTextSpec("ref",    simplify_repl=_ref_handler),
    MacroTextSpec("eqref",  simplify_repl=_ref_handler),
    # Captions (fire when we recurse into table/figure floats)
    MacroTextSpec("caption", simplify_repl=_caption_handler),
    # Links
    MacroTextSpec("url",  simplify_repl=lambda n, l2tobj=None: _arg_text(n, l2tobj, 0)),
    MacroTextSpec("href", simplify_repl=lambda n, l2tobj=None: f"`{_arg_text(n, l2tobj, 1).strip()} <{_arg_text(n, l2tobj, 0).strip()}>`_"),
    MacroTextSpec("footnote", simplify_repl=lambda n, l2tobj=None: f" [{_arg_text(n, l2tobj, 0).strip()}]"),
    # Layout — suppress
    MacroTextSpec("noindent",   simplify_repl=""),
    MacroTextSpec("newline",    simplify_repl="\n"),
    MacroTextSpec("vspace",     simplify_repl=""),
    MacroTextSpec("hspace",     simplify_repl=""),
    MacroTextSpec("vskip",      simplify_repl=""),
    MacroTextSpec("medskip",    simplify_repl="\n"),
    MacroTextSpec("bigskip",    simplify_repl="\n\n"),
    MacroTextSpec("includegraphics", simplify_repl=""),
    MacroTextSpec("bibliographystyle", simplify_repl=""),
    MacroTextSpec("bibliography",      simplify_repl=""),
    MacroTextSpec("maketitle",  simplify_repl=""),
    MacroTextSpec("tableofcontents", simplify_repl=""),
]

CUSTOM_ENVS = [
    # Math
    EnvironmentTextSpec("equation",   simplify_repl=_math_env_handler),
    EnvironmentTextSpec("equation*",  simplify_repl=_math_env_handler),
    EnvironmentTextSpec("align",      simplify_repl=_math_env_handler),
    EnvironmentTextSpec("align*",     simplify_repl=_math_env_handler),
    EnvironmentTextSpec("gather",     simplify_repl=_math_env_handler),
    EnvironmentTextSpec("gather*",    simplify_repl=_math_env_handler),
    EnvironmentTextSpec("multline",   simplify_repl=_math_env_handler),
    EnvironmentTextSpec("multline*",  simplify_repl=_math_env_handler),
    # Abstract
    EnvironmentTextSpec("abstract", simplify_repl=lambda n, l2tobj=None: (
        f"\n\n.. rubric:: Abstract\n\n{l2tobj.nodelist_to_text(n.nodelist).strip()}\n\n"
        if l2tobj else ""
    )),
    # Figures — keep caption only
    EnvironmentTextSpec("figure",  simplify_repl=_figure_env_handler),
    EnvironmentTextSpec("figure*", simplify_repl=_figure_env_handler),
    # Tables — render as pipe-delimited rows (the numeric core of most papers)
    EnvironmentTextSpec("table",     simplify_repl=_table_float_handler),
    EnvironmentTextSpec("table*",    simplify_repl=_table_float_handler),
    EnvironmentTextSpec("tabular",   simplify_repl=_tabular_env_handler),
    EnvironmentTextSpec("tabular*",  simplify_repl=_tabular_env_handler),
    EnvironmentTextSpec("tabularx",  simplify_repl=_tabular_env_handler),
    EnvironmentTextSpec("tabulary",  simplify_repl=_tabular_env_handler),
    EnvironmentTextSpec("tabu",      simplify_repl=_tabular_env_handler),
    EnvironmentTextSpec("longtable", simplify_repl=_tabular_env_handler),
    EnvironmentTextSpec("array",     simplify_repl=_tabular_env_handler),
    # Lists
    EnvironmentTextSpec("itemize",   simplify_repl=lambda n, l2tobj=None: "\n" + _reformat_list(l2tobj.nodelist_to_text(n.nodelist) if l2tobj else "") + "\n"),
    EnvironmentTextSpec("enumerate", simplify_repl=lambda n, l2tobj=None: "\n" + _reformat_list(l2tobj.nodelist_to_text(n.nodelist) if l2tobj else "", numbered=True) + "\n"),
    # Verbatim
    EnvironmentTextSpec("verbatim", simplify_repl=lambda n, l2tobj=None: (
        "\n\n.. code-block::\n\n   " + (l2tobj.nodelist_to_text(n.nodelist) if l2tobj else "").replace("\n", "\n   ") + "\n\n"
    )),
    EnvironmentTextSpec("quote", simplify_repl=lambda n, l2tobj=None: (
        "\n\n   " + (l2tobj.nodelist_to_text(n.nodelist) if l2tobj else "").strip().replace("\n", "\n   ") + "\n\n"
    )),
]


def make_converter() -> LatexNodes2Text:
    db = get_default_latex_context_db()
    db.add_context_category("research-corpus", macros=CUSTOM_MACROS, environments=CUSTOM_ENVS, prepend=True)
    return LatexNodes2Text(latex_context=db, math_mode="verbatim", strict_latex_spaces=False)


# ---------------------------------------------------------------------------
# Source flattening
# ---------------------------------------------------------------------------

def find_root_tex(root: Path) -> Path | None:
    """Return the .tex file containing \\begin{document}, excluding junk subdirs."""
    skip_dirs = {"extra_files", "IEEEtran", "supplementary"}
    candidates = []
    for tex in root.rglob("*.tex"):
        parts = tex.relative_to(root).parts
        if any(p in skip_dirs for p in parts):
            continue
        try:
            text = tex.read_text(errors="replace")
        except OSError:
            continue
        if r"\begin{document}" in text:
            candidates.append(tex)
    if not candidates:
        return None
    return min(candidates, key=lambda p: len(p.parts))


def flatten_tex(path: Path, visited: set | None = None) -> str:
    """Recursively inline \\input{} and \\include{} commands."""
    if visited is None:
        visited = set()
    if path in visited:
        return ""
    visited.add(path)

    try:
        text = path.read_text(errors="replace")
    except OSError:
        return ""

    def replacer(m):
        arg = m.group(1).strip()
        if not arg.endswith(".tex"):
            arg += ".tex"
        child = path.parent / arg
        return flatten_tex(child, visited) if child.exists() else ""

    return re.sub(r"\\(?:input|include)\{([^}]+)\}", replacer, text)


def strip_preamble(tex: str) -> str:
    m = re.search(r"\\begin\{document\}", tex)
    if m:
        tex = tex[m.end():]
    tex = re.sub(r"\\end\{document\}.*", "", tex, flags=re.DOTALL)
    return tex


# ---------------------------------------------------------------------------
# Post-processing
# ---------------------------------------------------------------------------

# Common TeX tokens → Unicode, so inline math reads naturally instead of as raw
# LaTeX (e.g. "$\Delta$F" → "ΔF", "$20\%$" → "20%").
_TEX_SYMBOLS = {
    r"\Delta": "Δ", r"\delta": "δ", r"\alpha": "α", r"\beta": "β",
    r"\gamma": "γ", r"\Gamma": "Γ", r"\sigma": "σ", r"\Sigma": "Σ",
    r"\mu": "μ", r"\lambda": "λ", r"\Lambda": "Λ", r"\pi": "π",
    r"\phi": "φ", r"\theta": "θ", r"\tau": "τ", r"\rho": "ρ",
    r"\epsilon": "ε", r"\omega": "ω", r"\Omega": "Ω",
    r"\times": "×", r"\cdot": "·", r"\pm": "±", r"\mp": "∓",
    r"\leq": "≤", r"\geq": "≥", r"\neq": "≠", r"\approx": "≈",
    r"\ll": "≪", r"\gg": "≫", r"\rightarrow": "→", r"\leftarrow": "←",
    r"\ldots": "…", r"\dots": "…", r"\infty": "∞",
    r"\dagger": "†", r"\ddagger": "‡", r"\%": "%", r"\&": "&",
    r"\_": "_", r"\#": "#", r"\diamond": "◇", r"\circ": "∘",
    r"\star": "⋆", r"\bullet": "•", r"\prime": "′", r"\sim": "~",
    r"\in": "∈", r"\sum": "Σ", r"\propto": "∝",
}
_REF_ROLE_RE = re.compile(r":ref:`([^`]+)`")
_INLINE_MATH_RE = re.compile(r"\$([^$]+)\$")
_SUP = str.maketrans("0123456789+-=()n", "⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿ")
_SUP_OK = set("0123456789+-=()n")


def _clean_inline_math(m: re.Match) -> str:
    s = m.group(1)
    s = s.replace(r"\{", "{").replace(r"\}", "}").replace(r"\,", " ").replace(r"\;", " ")
    # superscripts → Unicode where simple, else ^(...)
    s = re.sub(
        r"\^\{([^{}]*)\}",
        lambda g: g.group(1).translate(_SUP) if g.group(1) and set(g.group(1)) <= _SUP_OK else "^(" + g.group(1) + ")",
        s,
    )
    s = re.sub(r"\^([0-9])", lambda g: g.group(1).translate(_SUP), s)
    # subscripts → drop braces, keep as _name
    s = re.sub(r"_\{([^{}]*)\}", r"_\1", s)
    # residual lone braces have no meaning in plain text
    s = s.replace("{", "").replace("}", "")
    return s


def unescape_math(text: str) -> str:
    for tok, sym in _TEX_SYMBOLS.items():
        text = text.replace(tok, sym)
    # Clean and unwrap inline math spans so subscripts/superscripts stay readable.
    text = _INLINE_MATH_RE.sub(_clean_inline_math, text)
    return text


def deroll_refs(text: str) -> str:
    # Turn dangling :ref:`tab:foo` (target was dropped) into readable inline text:
    # strip a leading "prefix:" (sec:/tab:/fig:/eq:/…) and underscores.
    def repl(m: re.Match) -> str:
        label = re.sub(r"^[A-Za-z]+:", "", m.group(1))
        return label.replace("_", " ").strip()

    return _REF_ROLE_RE.sub(repl, text)


def _collapse_prose_spaces(line: str) -> str:
    # Collapse double-spaces left by dropped macros, but only on non-indented prose
    # lines — indented lines are structural (math blocks, code, list continuations).
    if line[:1].isspace():
        return line.rstrip()
    return re.sub(r"  +", " ", line).rstrip()


def clean_rst(text: str) -> str:
    text = unescape_math(text)
    text = deroll_refs(text)
    text = "\n".join(_collapse_prose_spaces(l) for l in text.splitlines())
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


# ---------------------------------------------------------------------------
# RST → Typst  (best-effort structural transform)
#
# Typst math is not LaTeX, so math/code/table blocks are emitted as raw fenced
# blocks — readable, LLM-friendly, and valid enough to render to PDF. Prose,
# headings and emphasis are mapped to native Typst.
# ---------------------------------------------------------------------------

def rst_to_typst(rst: str) -> str:
    lines = rst.splitlines()
    out: list[str] = []
    i = 0
    n = len(lines)
    underline_re = re.compile(r"^([=\-~^\"'])\1{3,}\s*$")

    def emit_raw(block: list[str], lang: str = "") -> None:
        out.append("```" + lang)
        out.extend(block)
        out.append("```")
        out.append("")

    while i < n:
        line = lines[i]

        # Section: over+under line (level 0) — a rule, the title, another rule.
        if underline_re.match(line) and i + 2 < n and lines[i + 1].strip() and underline_re.match(lines[i + 2]):
            out.append(f"= {lines[i + 1].strip()}")
            out.append("")
            i += 3
            continue

        # Section: title followed by an underline rule.
        if line.strip() and i + 1 < n and underline_re.match(lines[i + 1]) and len(lines[i + 1].strip()) >= len(line.strip()) - 1:
            char = lines[i + 1].strip()[0]
            level = SECTION_CHARS.index(char) + 1 if char in SECTION_CHARS else 2
            out.append("=" * level + " " + line.strip())
            out.append("")
            i += 2
            continue

        # Math directive → raw latex block.
        if line.strip() == ".. math::":
            i += 1
            while i < n and not lines[i].strip():
                i += 1
            block = []
            while i < n and (lines[i].startswith("   ") or not lines[i].strip()):
                if not lines[i].strip() and (i + 1 >= n or not lines[i + 1].startswith("   ")):
                    break
                block.append(lines[i][3:] if lines[i].startswith("   ") else "")
                i += 1
            emit_raw([b for b in block], "latex")
            continue

        # Code directive → raw block.
        if line.strip().startswith(".. code-block::"):
            i += 1
            while i < n and not lines[i].strip():
                i += 1
            block = []
            while i < n and (lines[i].startswith("   ") or not lines[i].strip()):
                if not lines[i].strip() and (i + 1 >= n or not lines[i + 1].startswith("   ")):
                    break
                block.append(lines[i][3:] if lines[i].startswith("   ") else "")
                i += 1
            emit_raw(block)
            continue

        # Rubric (abstract) → bold heading.
        m = re.match(r"^\.\. rubric:: (.+)$", line.strip())
        if m:
            out.append(f"== {m.group(1)}")
            out.append("")
            i += 1
            continue

        out.append(line)
        i += 1

    text = "\n".join(out)
    # RST link `text <url>`_ → Typst #link  (before ``code`` collapse touches backticks).
    text = re.sub(r"`([^`<]+) <([^>]+)>`_", r'#link("\2")[\1]', text)
    # RST ``code`` → Typst raw `code`.
    text = re.sub(r"``([^`]+)``", r"`\1`", text)
    # Emphasis: **bold** → *bold*, *italic* → _italic_ (sentinels avoid re-matching).
    text = text.replace("\x00", "").replace("\x01", "")
    text = re.sub(r"\*\*([^*\n]+?)\*\*", "\x00\\1\x01", text)
    text = re.sub(r"(?<![\*\w])\*(?!\*)([^*\n]+?)\*(?!\*)", r"_\1_", text)
    text = text.replace("\x00", "*").replace("\x01", "*")
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip() + "\n"


# ---------------------------------------------------------------------------
# Per-paper conversion
# ---------------------------------------------------------------------------

def convert_paper(arxiv_id: str, dirs: dict, fmt: str, force: bool = False) -> str:
    """Returns 'ok', 'skip', or 'error'."""
    tarball = dirs["src"] / f"{arxiv_id}.tar.gz"
    ext = "typ" if fmt == "typst" else "rst"
    out_file = dirs[fmt] / f"{arxiv_id}.{ext}"

    if not tarball.exists():
        print(f"  SKIP  {arxiv_id} — no tarball found")
        return "skip"

    if out_file.exists() and not force:
        print(f"  SKIP  {arxiv_id} — already converted (use --force to redo)")
        return "skip"

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        try:
            with tarfile.open(tarball) as tf:
                tf.extractall(tmp_path)
        except tarfile.TarError as e:
            print(f"  ERROR {arxiv_id} — bad tarball: {e}")
            return "error"

        root_tex = find_root_tex(tmp_path)
        if root_tex is None:
            print(f"  ERROR {arxiv_id} — no \\begin{{document}} found")
            return "error"

        flat = flatten_tex(root_tex)
        body = strip_preamble(flat)

        try:
            converter = make_converter()
            rst = converter.latex_to_text(body)
        except Exception as e:
            print(f"  ERROR {arxiv_id} — conversion failed: {e}")
            return "error"

    rst = clean_rst(rst)
    output = rst_to_typst(rst) if fmt == "typst" else rst
    out_file.parent.mkdir(parents=True, exist_ok=True)
    out_file.write_text(output)
    try:
        rel = out_file.relative_to(Path.cwd())
    except ValueError:
        rel = out_file
    print(f"  OK    {arxiv_id} → {rel}")
    return "ok"


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def resolve_dirs(papers_dir: str | None) -> dict:
    base = Path(papers_dir) if papers_dir else Path.cwd() / "references" / "papers"
    return {"src": base / "src", "rst": base / "rst", "typst": base / "typst"}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("ids", nargs="*", help="arXiv IDs to convert (default: all tarballs in src/)")
    parser.add_argument("--force", action="store_true", help="Re-convert already-converted papers")
    parser.add_argument("--format", choices=["rst", "typst"], default="rst", help="Output format (default: rst)")
    parser.add_argument("--papers-dir", default=None, help="Base papers dir (default: ./references/papers)")
    args = parser.parse_args()

    dirs = resolve_dirs(args.papers_dir)

    if args.ids:
        targets = args.ids
    else:
        targets = sorted(p.stem.replace(".tar", "") for p in dirs["src"].glob("*.tar.gz"))

    if not targets:
        sys.exit(f"No tarballs found in {dirs['src']}")

    counts = {"ok": 0, "skip": 0, "error": 0}
    for arxiv_id in targets:
        counts[convert_paper(arxiv_id, dirs, args.format, force=args.force)] += 1

    print(f"\n{counts['ok']} converted, {counts['skip']} skipped, {counts['error']} failed")


if __name__ == "__main__":
    main()
