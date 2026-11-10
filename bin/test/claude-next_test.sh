#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/claude-next"
# shellcheck source=SCRIPTDIR/../claude-next
source "$script"
set +e

failures=0
check() { # name expected actual
  if [[ "$2" == "$3" ]]; then
    echo "ok   $1"
  else
    echo "FAIL $1"; echo "     expected: $2"; echo "     actual:   $3"
    failures=$((failures + 1))
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
mkdir -p "$repo/planning"
printf '# Plan\n\nstatus: draft\n' > "$repo/planning/cache-plan.md"
printf '# Plan\n\nstatus: in-progress\n' > "$repo/planning/wip-plan.md"
printf '# Plan\n\nstatus: done\n' > "$repo/planning/old-plan.md"
printf '# Report\n' > "$repo/planning/cache-research-2026-11.md"
printf '# Report\n' > "$repo/planning/boot-profiling-2026-11.md"
printf '# Notes\n' > "$repo/CLAUDE.md"

check "research report leads to create-plan" \
  "/create-plan planning/cache-research-2026-11.md" \
  "$(next_command "$repo" "$repo/planning/cache-research-2026-11.md")"
check "profiling report leads to create-plan" \
  "/create-plan planning/boot-profiling-2026-11.md" \
  "$(next_command "$repo" "$repo/planning/boot-profiling-2026-11.md")"
check "draft plan leads to execute-plan" \
  "/execute-plan planning/cache-plan.md" \
  "$(next_command "$repo" "$repo/planning/cache-plan.md")"
check "in-progress plan leads to execute-plan" \
  "/execute-plan planning/wip-plan.md" \
  "$(next_command "$repo" "$repo/planning/wip-plan.md")"
check "done plan leads to critique" \
  "/critique planning/old-plan.md" \
  "$(next_command "$repo" "$repo/planning/old-plan.md")"
check "other markdown has no next step" \
  "" \
  "$(next_command "$repo" "$repo/CLAUDE.md")"
check "file outside the repo keeps its absolute path" \
  "/execute-plan $repo/planning/cache-plan.md" \
  "$(next_command "$tmp/elsewhere" "$repo/planning/cache-plan.md")"

transcript="$tmp/session.jsonl"
assistant() { jq -cn --arg t "$1" '{type:"assistant",message:{content:[{type:"thinking"},{type:"text",text:$t}]}}'; }
{
  assistant "Report saved to planning/cache-research-2026-11.md."
  jq -cn '{type:"user",message:{content:"look at planning/boot-profiling-2026-11.md"}}'
  assistant "Plan written. Run \`/execute-plan planning/cache-plan.md\`, per the repo CLAUDE.md."
  assistant "I also read planning/missing-plan.md and CLAUDE.md."
} > "$transcript"

check "last existing artifact the assistant named wins" \
  "$repo/planning/cache-plan.md" \
  "$(find_artifact "$repo" "$transcript")"

assistant "See $repo/planning/old-plan.md" > "$tmp/absolute.jsonl"
check "absolute paths in the transcript resolve" \
  "$repo/planning/old-plan.md" \
  "$(find_artifact "$tmp" "$tmp/absolute.jsonl")"

touch -d '2 minutes ago' "$repo"/planning/*.md
touch "$repo/planning/boot-profiling-2026-11.md"
assistant "Nothing to see here." > "$tmp/empty.jsonl"
check "falls back to the newest artifact in planning/" \
  "$repo/planning/boot-profiling-2026-11.md" \
  "$(find_artifact "$repo" "$tmp/empty.jsonl")"
check "falls back when there is no transcript" \
  "$repo/planning/boot-profiling-2026-11.md" \
  "$(find_artifact "$repo" "")"
check "nothing found prints nothing" \
  "" \
  "$(find_artifact "$tmp" "$tmp/empty.jsonl")"

# A fake herdr records every call, and swaps the session id once /clear is sent.
bin="$tmp/bin"
mkdir -p "$bin" "$tmp/home/.claude/projects/-repo"
cp "$transcript" "$tmp/home/.claude/projects/-repo/sid-1.jsonl"
cat > "$bin/herdr" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$tmp/calls"
sid=sid-1; [[ -f "$tmp/cleared" ]] && sid=sid-2
case "\$1 \$2" in
  "pane current") echo '{"result":{"pane":{"pane_id":"w1:p1","foreground_cwd":"$repo"}}}' ;;
  "agent get") echo "{\"result\":{\"agent\":{\"agent\":\"claude\",\"agent_status\":\"\${FAKE_STATUS:-idle}\",\"agent_session\":{\"value\":\"\$sid\"}}}}" ;;
  "agent prompt") [[ "\$4" == /clear ]] && touch "$tmp/cleared"; echo '{}' ;;
esac
EOF
chmod +x "$bin/herdr"

run_main() { # stdin-keys args...
  rm -f "$tmp/calls" "$tmp/cleared"
  printf '%b' "$1" | HOME="$tmp/home" PATH="$bin:$PATH" bash "$script" "${@:2}" 2>&1
}

out="$(run_main '\n')"
check "enter sends /clear, then the next command" \
  "$(printf '%s\n' 'agent prompt w1:p1 /clear' 'agent prompt w1:p1 /execute-plan planning/cache-plan.md')" \
  "$(grep '^agent prompt' "$tmp/calls")"
check "popup shows the command before running it" \
  "1" "$(grep -c '/execute-plan planning/cache-plan.md' <<<"$out")"

run_main 'q' >/dev/null
check "any other key cancels" "" "$(grep '^agent prompt' "$tmp/calls")"

out="$(FAKE_STATUS=working run_main '\n')"
check "refuses while Claude is working" "" "$(grep '^agent prompt' "$tmp/calls")"
check "says why it refused" "1" "$(grep -c 'working' <<<"$out")"

cat > "$bin/nvim" <<EOF
#!/usr/bin/env bash
echo "nvim \$*" >> "$tmp/calls"
EOF
chmod +x "$bin/nvim"
run_main '' open >/dev/null
check "open edits the artifact in nvim" "nvim $repo/planning/cache-plan.md" "$(grep '^nvim' "$tmp/calls")"

echo
if (( failures )); then echo "$failures failed"; exit 1; fi
echo "all passed"
