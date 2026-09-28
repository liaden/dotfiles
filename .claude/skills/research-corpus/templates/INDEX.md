# References Index

Quick-reference index of every resource in this folder. Each entry summarizes
what the reference contains and **why it is useful for {PROJECT/GOAL}**.

> An index entry is not a summary of the paper — it is a summary of *what this
> paper gives the project*. Always end each entry with what decision, feature,
> or code it informs.

---

## Synthesis documents

### [{topic}.md]({topic}.md)
{One line: how many sources, on what.}

**What's inside:**
- **{key finding}** ({source id}) — {the fact + the number/result that matters}
- ...

**Useful for:** {which design decision / feature / algorithm choice this drives.}

---

## Reference implementations (`repos/`)

### [{repo-name}](repos/{repo-name}/) — {author}
**{Stack in one phrase}.** {What it does; which pattern to borrow.}

---

## Papers (`papers/`)

Grouped by topic. IDs link to converted text in `papers/rst/` (or `papers/typst/`);
PDF-only items link to `papers/pdf/`.

### {Topic group}

| Source | Summary |
|---|---|
| [{id}](papers/rst/{id}.rst) | **{title}:** {result + the one thing it's the reference for}. |

---

## Expert / community knowledge (not in the literature)

> The defensible layer. Capture what practitioners know that no paper states —
> terminology conventions, common pitfalls, failure cases of existing tools.
> Cite the source (forum thread, interview, community doc) even when informal.

- **{claim}** — {source}; {why it matters for the project, esp. what NOT to do}.
