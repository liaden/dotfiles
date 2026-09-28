---
name: research-corpus
description: Build a references/ corpus for a domain. Surveys where the knowledge lives, downloads arXiv and PDF sources, converts them to RST or Typst, and writes an INDEX tying each source to a project decision. Use when asked to import, gather, or convert research sources.
argument-hint: <domain or problem space>
---

# research-corpus

Build a curated `references/` corpus in the current repo for a domain you do not yet
know well, as in `pitchcraft/references/` and `pigmentarium/`. The output is text an
LLM or PaperQA2 can read, plus a synthesis that ties each source to a design decision.

To compare options and recommend 1, use `/research`. This skill gathers sources.

Where knowledge lives differs by domain. Survey the sources before downloading
anything, and use the right adapter for each channel.

Search mempalace for earlier source decisions (`~/.claude/reference/mempalace.md`).

## Corpus layout

```
references/
  SCOPE.md              # questions the corpus must answer (step 1)
  sources.md            # channels, access, adapters (step 2)
  INDEX.md              # each source tied to a decision (step 5)
  <topic>.md            # synthesis by theme (step 5)
  papers/
    src/<id>.tar.gz     # arXiv LaTeX tarballs
    rst/<id>.rst        # converted text, the default
    typst/<id>.typ      # converted text with --format typst
    pdf/<name>.pdf      # PDF-only sources
  repos/<name>/         # reference implementations as git submodules
```

If the repo already has a `references/` or `docs/` layout, match it. pigmentarium uses
`raw/<vendor>/` and `docs/*-sources.md`.

## Workflow

### 1. Scope

Turn the prompt into concrete questions and a list of topics. Write
`references/SCOPE.md`. It keeps the downloads targeted.

### 2. Survey the sources

Write `references/sources.md`, starting from `templates/sources.md`. List the source
channels for this domain. For each: access, what only it has, adapter, and priority.
Use WebSearch. For fields that are hard to map, Undermind, Elicit, and PaperQA2 help
find the canon by hand. Name the SCOPE questions that no source answers. Those go on
the list to capture from experts and the community.

### 3. Acquire

Run from the repo root. `<skill>` is this skill's directory. The scripts are `uv run`
scripts with inline dependencies, so they need no venv.

| Channel | Command |
|---|---|
| arXiv LaTeX source | `<skill>/scripts/arxiv_download.sh 2410.09958 2207.14606` |
| PDF: datasheet, paper, standard, report | `<skill>/scripts/pdf_to_rst.py raw/**/*.pdf` |
| Web writeup or expert prose | WebFetch, clean, then write a `.md` synthesis by hand |
| Code or reference implementation | `git submodule add <url> references/repos/<name>` |

Rate-limit outside fetches. The arXiv script sleeps 3 seconds between requests. It
calls `latex_to_rst.py`, which writes to `references/papers/` (override with
`--papers-dir`). `pdf_to_rst.py` takes `--out-dir`.

### 4. Convert

The adapters write RST by default. Add `--format typst` for a corpus that also renders
to PDF.

- RST is the proven default. It keeps tables, math, and citations, and its output is
  byte-identical to the pitchcraft corpus.
- Typst is best effort: headings, emphasis, and raw math, code, and table blocks.
  Asterisks inside inline math get wrapped as italic. Use RST when math matters.
- Scanned PDFs need OCR first. `pdf_to_rst.py` warns when the output is suspiciously
  short.

### 5. Synthesize

Write `references/INDEX.md`, starting from `templates/INDEX.md`, and
`references/<topic>.md`. Read `~/.claude/reference/writing-style.md` first.

Most of the value is here. For each source, write what it gives the project. Every
entry ends with the decision, feature, or code it informs. Group papers by topic. Add
a section for expert and community knowledge that no paper holds: terminology traps,
failure cases of existing tools, and practitioner conventions.

### 6. Ground (optional)

For questions over the corpus, point PaperQA2 or a small RAG at
`references/papers/rst/`.
