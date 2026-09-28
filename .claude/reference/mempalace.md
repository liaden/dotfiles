# mempalace lookups

mempalace holds past sessions and decisions, 1 wing per repo. Use it to find what was
decided before and why.

Read-only commands only. A systemd timer keeps the palace fresh, so never run `mine`,
`sync`, or any command that writes.

```bash
mempalace search "query" --wing <repo dir name> --results 10
mempalace search "query" --wing lain --since 2026-09-01 --results 10
mempalace wake-up --wing <repo dir name>
mempalace status
```

- Always pass `--results`. The `lain` wing holds 1.7 million drawers.
- Always pass `--wing` unless the question spans repos.
- Use `--since` or `--before` with an ISO date to narrow by time.
- A result is a lead. Check it against the code before relying on it.
