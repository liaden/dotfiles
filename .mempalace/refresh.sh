#!/usr/bin/env bash
# MemPalace freshness refresh — re-mine repos + Claude chats incrementally.
# `mine` skips already-filed/unchanged files, so this is cheap to run often.
# Invoked by the systemd user timer mempalace-refresh.timer.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
log(){ echo "[$(date '+%F %T')] $*"; }

# Run a `mempalace mine` invocation, log its matching summary lines on
# success, or the exit code and full stderr/stdout on failure. Without this,
# a lock-contention failure (MineAlreadyRunning, exit 1) prints to stderr but
# doesn't match the summary-line grep, so it vanished from the log entirely —
# indistinguishable from a quiet success.
run_mine() {
  local pattern="$1"; shift
  local out status
  out=$(mempalace "$@" 2>&1)
  status=$?
  if [ "$status" -ne 0 ]; then
    log "  ERROR (exit $status): $out"
  else
    printf '%s\n' "$out" | grep -iE "$pattern" | sed 's/^/    /'
  fi
  return 0
}

# --- projects: repo code/docs + rst/tex/bib force-included past the extension
# gate. force-include bypasses gitignore, so drop candidates git already ignores
# (build trees, submodules) and prune the giant build dirs during the walk. ---
mine_projects() {
  local repo="$1" wing="$2"
  local dir="$HOME/dev/$repo"
  [ -d "$dir" ] || { log "skip projects:$repo (missing)"; return; }
  local -a inc=()
  local rel
  while IFS= read -r -d '' f; do
    rel="${f#./}"
    git -C "$dir" check-ignore -q "$rel" || inc+=(--include-ignored "$rel")
  done < <(
    cd "$dir" && find . \( -path './.git' -o -path './references/repos' \
      -o -path './.tflite-build' -o -path './target' -o -path './node_modules' \) -prune -o \
      -type f \( -iname '*.rst' -o -iname '*.tex' -o -iname '*.bib' \) -print0 2>/dev/null
  )
  log "projects:$repo (wing=$wing, ${#inc[@]} force-include args)"
  run_mine "Files processed|already filed|Drawers filed" \
    mine "$dir" --mode projects --wing "$wing" --agent joel "${inc[@]}"
}

mine_extract() {
  local wing="$1" dir="$2"
  [ -d "$dir" ] || { log "skip extract:$wing (missing $dir)"; return; }
  log "extract:$wing <- $dir"
  run_mine "Files extracted|skipped|Total drawers" \
    mine "$dir" --mode extract --wing "$wing" --agent joel
}

log "=== refresh start ==="

# Ordered cheapest-first, with lain LAST. The palace takes a single global lock, so
# these run strictly in sequence and any failure aborts the rest of the cycle. lain
# walks ~59k files (vs 1.1k tracked) and was OOM-killed mid-mine on 2026-07-29 at a
# 4.9 GB peak — which silently starved every project after it, leaving the palace
# stale from 2026-07-22. Running it last means a lain failure costs only lain.
mine_projects junk-drawer   junk-drawer
mine_projects pigmentarium  pigmentarium
mine_projects belle-curves  belle-curves
mine_projects pitchcraft    pitchcraft
mine_extract  pitchcraft   "$HOME/dev/pitchcraft/references/papers/pdf"
mine_extract  pigmentarium "$HOME/dev/pigmentarium/raw"

# --- Claude Code chat transcripts (their own wing, auto-routed into rooms) ---
if [ -d "$HOME/.claude/projects" ]; then
  log "convos:claude-chats <- ~/.claude/projects"
  run_mine "Files processed|already filed|Drawers filed" \
    mine "$HOME/.claude/projects" --mode convos --wing claude-chats --agent joel
fi

# lain last — see note above.
mine_projects lain          lain

log "=== refresh done ==="
