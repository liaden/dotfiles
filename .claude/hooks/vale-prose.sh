#!/usr/bin/env bash
# PreToolUse hook: lint the prose in Jira, Confluence and Notion write calls with vale
# before they post, because a posted comment can't be unsent.
set -euo pipefail

config="$HOME/.vale.ini"
skip_once="$HOME/.claude/vale-skip-once"

command -v vale >/dev/null || exit 0
[[ -f "$config" ]] || exit 0
# A fresh machine has the tracked config but not the downloaded packages.
[[ -d "$HOME/.claude/vale/styles/Google" ]] || vale --config "$config" sync >/dev/null 2>&1 || true

if [[ -f "$skip_once" ]]; then
  rm -f "$skip_once"
  exit 0
fi

input=$(cat)
tool=$(jq -r .tool_name <<<"$input")

# ADF payloads are JSON documents, not prose; vale would lint the braces.
text=$(jq -r <<<"$input" '
  [ .tool_input
    | .. | objects | to_entries[]
    | select(.key | IN("commentBody","description","content","new_str","markdown","body"))
    | .value | strings
    | select(test("^\\s*[{\\[]") | not)
  ] | join("\n\n")')

[[ -n "${text// /}" ]] || exit 0

alerts=$(printf '%s\n' "$text" |
  vale --config "$config" --ext=.md --output=line --minAlertLevel=warning 2>&1 |
  sed -E 's/^[^:]*:([0-9]+):[0-9]+:/line \1: /') || true

[[ -z "$alerts" ]] && exit 0

reason="vale found errors or warnings in the text for $tool. Fix them and call the tool again. If an alert is on purpose (a quote, a name), ask the user; with their OK, run 'touch ~/.claude/vale-skip-once' to let the next call through.
$alerts"

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
