# Research report template

````markdown
# <Topic>: research

| | |
|---|---|
| Date | <YYYY-MM-DD> |
| Git SHA | <short sha> |
| Branch | <branch, and "worktree at <default branch>" if used> |
| Prior research | <files included, files excluded, or "none found"> |

## Executive summary

<Under 100 words. The recommendation first, then the main reason and the main risk.>

## Context

<The question, the goals, the constraints, and who is affected. What the code does
today, with paths.>

## Options

### 1. <Option name>

<What it is. What it costs. What it changes, with paths. Evidence for each claim.>

```mermaid
flowchart LR
  A --> B
```

### 2. Use an existing library: <name>

### 3. Do nothing

## Comparison

| | Option 1 | Option 2 | Do nothing |
|---|---|---|---|
| <criterion> | | | |

## Spike findings

| Question | Result | Evidence |
|---|---|---|

## Recommendation

<1 option, the reasons, and what would change the recommendation. State how sure you
are.>

## Discarded options

<Each with 1 line saying why.>

## Open questions

<What the research could not answer, and who or what could.>

## Sources

<Files with paths, URLs with the date read, mempalace results by query.>
````
