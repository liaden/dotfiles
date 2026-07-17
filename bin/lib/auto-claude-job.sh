#!/usr/bin/env bash
# auto-claude-job.sh — shared harness for the overnight auto-claude jobs
# (rebase-pr, chore-pr, critique-pr) and the nightly-coordinator that sequences
# them. Sourced, not executed. Owns the two things that MUST stay identical
# across every job: the headless permission posture, and the caffeinate/awake
# coordination. Per-job worktree + claude-stage logic stays in each job (their
# shapes differ enough that extracting them would add indirection without
# removing real duplication).
#
# Source it after `set -euo pipefail`, e.g.:
#   . "$(dirname "$0")/lib/auto-claude-job.sh"
#
# Design note: this file is intentionally dependency-free (no config.sh, no
# claude, no gh) so it can be sourced at the very top of a job — before the
# caffeinate re-exec — without side effects.

# ── ac_caffeinate_guard NAME "$@" ────────────────────────────────────────────
# Re-exec the calling script under `caffeinate -i` so idle sleep can't interrupt
# a multi-minute run. Idempotent via a per-name guard var. Honors an inherited
# AUTO_CLAUDE_CAFFEINATED=1 (set by the nightly-coordinator) so a job invoked as
# a coordinator STAGE does NOT spawn its own nested caffeinate — one caffeinate
# wraps the whole night. Call it before doing any real work.
#   NAME: a short job name (e.g. rebase-pr); used to derive the guard var.
ac_caffeinate_guard() {
  local name="$1"; shift
  # Already inside a coordinator's caffeinate → nothing to do.
  [ -n "${AUTO_CLAUDE_CAFFEINATED:-}" ] && return 0
  # Derive an uppercased, underscore-safe guard var: rebase-pr → REBASE_PR_CAFFEINATED
  local var; var="$(printf '%s' "$name" | tr '[:lower:]-' '[:upper:]_')_CAFFEINATED"
  # Already re-exec'd once (guard var set) → nothing to do.
  [ -n "${!var:-}" ] && return 0
  command -v caffeinate >/dev/null 2>&1 || return 0
  export "$var=1" AUTO_CLAUDE_CAFFEINATED=1
  exec caffeinate -i "$0" "$@"
}

# ── ac_perm_flags [extra-comma-tools] ────────────────────────────────────────
# Populate the global `base_flags` array with the ONE headless-safe permission
# posture, shared by every job so it can never drift across files again:
#   --permission-mode dontAsk  — executes only allow-listed tools, never prompts
#     (verified claude 2.1.212: `auto` DENIES Edit/Write with no TTY). The
#     ~/.claude/settings.json deny-list still composes (git push --force* etc.
#     stay refused), so force-pushes remain a bash-tail-only operation.
#   --allowedTools  — ONE comma-joined string (separate args are NOT parsed as an
#     allow-list). A base set every job needs, plus any per-job extras.
# Never bypassPermissions / --dangerously-skip-permissions: work policy.
#   $1 (optional): extra tools to append, comma-joined, no leading comma
#                  (e.g. "Bash(gh:*),Bash(npm:*)").
ac_perm_flags() {
  local extra="${1:-}"
  local tools="Read,Edit,Write,Bash(git:*),Bash(bun:*),Bash(bun-ptr:*),Bash(mkdir:*),Bash(date:*),Bash(ls:*),Bash(cat:*),Bash(grep:*),Bash(rg:*)"
  [ -n "$extra" ] && tools="$tools,$extra"
  base_flags=(--permission-mode dontAsk --allowedTools "$tools")
}
