# {DOMAIN} — Source Survey

> **Researched:** {DATE}
> **Scope:** see `SCOPE.md` for the questions this corpus must answer.

Map of where the knowledge for this domain actually lives, and how to acquire
each channel. Fill this in *before* bulk-downloading — source topology varies
wildly by domain (a scientific field is ~90% arXiv/journals; a graphics or
materials domain may be 20% arXiv and 80% conference PDFs + code + vendor docs).

## Summary

| Source | Channel | Accessible | Unique data | Adapter |
|--------|---------|-----------|-------------|---------|
| {e.g. arXiv} | LaTeX src | ✅ | full text, equations, tables | `arxiv_download.sh` |
| {e.g. SIGGRAPH / ACM DL} | PDF | ⚠ paywall/manual | canonical techniques | `pdf_to_rst.py` |
| {e.g. vendor datasheets} | PDF | ✅ | structured spec fields | `pdf_to_rst.py` |
| {e.g. reference repo} | git | ✅ | working implementation | submodule → `references/repos/` |
| {e.g. community/expert prose} | web/manual | ✅ | practitioner knowledge not in papers | WebFetch → hand-written `.md` |

## Per-source detail

### {Source name}
- **URL / access pattern:** {how to reach it}
- **Accessibility:** {open API / browser UA / paywalled / manual download}
- **Unique data:** {what this source has that others don't}
- **Adapter & command:** {which script; exact invocation}
- **Suitability / priority:** {primary / complementary / manual-only}

<!-- repeat per source -->

## Recommended acquisition order

1. {broadest + easiest-to-automate source first}
2. {structured complementary source}
3. {deep/manual sources last}

## Coverage gaps

- {questions from SCOPE.md that no source above answers well — flag for expert/community capture}
