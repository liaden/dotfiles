#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/claude-session-hook"

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
state="$tmp/home/.local/state/claude-sessions"
mkdir -p "$repo" "$tmp/bin" "$state"
git -C "$repo" init -q -b feature/PLATFORM-1234-retry-payments

for tool in herdr notify-send; do
  cat > "$tmp/bin/$tool" <<EOF
#!/usr/bin/env bash
printf '%s\n' "$tool \$*" >> "$tmp/calls"
EOF
  chmod +x "$tmp/bin/$tool"
done

hook() { # event json [env...]
  rm -f "$tmp/calls"; touch "$tmp/calls"
  printf '%s' "$2" | env -u TMUX -u HERDR_PANE_ID HOME="$tmp/home" PATH="$tmp/bin:$PATH" \
    "${@:3}" bash "$script" "$1"
}
input() { # session-id [prompt]
  jq -cn --arg sid "$1" --arg cwd "$repo" --arg prompt "${2:-}" \
    '{session_id: $sid, cwd: $cwd, prompt: $prompt}'
}

hook SessionStart "$(input s1)"
check "label takes a Jira key longer than 5 letters" \
  "PLATFORM-1234" "$(jq -r .label "$state/s1.json")"

hook SessionStart "$(input s1)" HERDR_PANE_ID=w1:p1
check "session start clears the herdr task and finish time" \
  "herdr pane report-metadata w1:p1 --source claude-session-hook --clear-token task --clear-token finished" \
  "$(cat "$tmp/calls")"

hook UserPromptSubmit "$(input s1 $'fix the retry spec\nmore detail')" HERDR_PANE_ID=w1:p1
check "prompt reports the task to herdr" \
  "herdr pane report-metadata w1:p1 --source claude-session-hook --token task=fix the retry spec --clear-token finished" \
  "$(cat "$tmp/calls")"

hook Stop "$(input s1)" HERDR_PANE_ID=w1:p1
check "stop reports the finish time to herdr" \
  "1" "$(grep -cE '^herdr pane report-metadata w1:p1 --source claude-session-hook --token finished=done [0-9]{2}:[0-9]{2}$' "$tmp/calls")"

hook UserPromptSubmit "$(input s1 'fix it')"
check "outside herdr nothing is sent to herdr" "" "$(cat "$tmp/calls")"

jq -n --arg pid "$$" '{status: "working", task: "/execute-plan planning/a.md", label: "OPS-7", pid: ($pid | tonumber)}' > "$state/other.json"

hook UserPromptSubmit "$(input s2 '/execute-plan planning/b.md')" HERDR_PANE_ID=w1:p2
check "a 2nd execute-plan warns in herdr, naming the other run" \
  "1" "$(grep -c '^herdr notification show .*OPS-7' "$tmp/calls")"

hook UserPromptSubmit "$(input s2 '/execute-plan planning/b.md')"
check "outside herdr the warning goes to notify-send" \
  "1" "$(grep -c '^notify-send .*OPS-7' "$tmp/calls")"

hook UserPromptSubmit "$(input s2 'investigate the 500s')"
check "other prompts do not warn" "" "$(grep -E '^(notify-send|herdr notification)' "$tmp/calls" || true)"

jq '.status = "idle"' "$state/other.json" > "$state/other.tmp" && mv "$state/other.tmp" "$state/other.json"
hook UserPromptSubmit "$(input s2 '/execute-plan planning/b.md')"
check "an idle execute-plan session does not count" "" "$(grep -E '^notify-send' "$tmp/calls" || true)"

jq '.status = "working" | .pid = 999999' "$state/other.json" > "$state/other.tmp" && mv "$state/other.tmp" "$state/other.json"
hook UserPromptSubmit "$(input s2 '/execute-plan planning/b.md')"
check "a dead session does not count" "" "$(grep -E '^notify-send' "$tmp/calls" || true)"

echo
if (( failures )); then echo "$failures failed"; exit 1; fi
echo "all passed"
