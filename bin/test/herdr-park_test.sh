#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/herdr-park"

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
mkdir -p "$repo" "$tmp/bin"
git -C "$repo" init -q -b PROJ-42-login-fix

cat > "$tmp/bin/herdr" <<EOF
#!/usr/bin/env bash
printf '%s\n' "herdr \$*" >> "$tmp/calls"
case "\$1 \$2" in
  "pane current") echo '{"result":{"pane":{"pane_id":"w1:p1","workspace_id":"w1","foreground_cwd":"$repo"}}}' ;;
  "workspace get") echo '{"result":{"workspace":{"workspace_id":"w1","label":"PROJ-42"}}}' ;;
  "workspace create") echo '{"result":{"workspace":{"workspace_id":"w2"},"root_pane":{"pane_id":"w2:p1"}}}' ;;
  *) echo '{}' ;;
esac
EOF
cat > "$tmp/bin/feed" <<EOF
#!/usr/bin/env bash
printf '%s\n' "feed \$*" >> "$tmp/calls"
EOF
chmod +x "$tmp/bin/herdr" "$tmp/bin/feed"

run() { # stdin args...
  rm -f "$tmp/calls"; touch "$tmp/calls"
  printf '%b' "$1" | PATH="$tmp/bin:$PATH" bash "$script" "${@:2}" 2>&1
}

out="$(run 'waiting on review from Sam, next: address comments\n')"
check "park sets the parked token on the focused workspace" \
  "herdr workspace report-metadata w1 --source herdr-park --token parked=waiting on review from Sam, next: address comments" \
  "$(grep '^herdr workspace report-metadata' "$tmp/calls")"
check "park logs the note to the feed with the workspace and branch" \
  "feed add herdr parked: PROJ-42 waiting on review from Sam, next: address comments --meta {\"event\":\"parked\",\"workspace\":\"PROJ-42\",\"cwd\":\"$repo\",\"branch\":\"PROJ-42-login-fix\"}" \
  "$(grep '^feed add' "$tmp/calls")"
check "park prompt names the workspace" "1" "$(grep -c 'PROJ-42' <<<"$out")"

run '\n' >/dev/null
check "empty note unparks" \
  "herdr workspace report-metadata w1 --source herdr-park --clear-token parked" \
  "$(grep '^herdr workspace report-metadata' "$tmp/calls")"
check "unpark is logged" \
  "feed add herdr unparked: PROJ-42  --meta {\"event\":\"unparked\",\"workspace\":\"PROJ-42\",\"cwd\":\"$repo\",\"branch\":\"PROJ-42-login-fix\"}" \
  "$(grep '^feed add' "$tmp/calls")"

run 'payments 500s\nnext: finish the retry spec\n' incident >/dev/null
check "incident parks the current workspace with the note" \
  "herdr workspace report-metadata w1 --source herdr-park --token parked=next: finish the retry spec" \
  "$(grep '^herdr workspace report-metadata' "$tmp/calls")"
check "incident opens a focused workspace named for it" \
  "herdr workspace create --cwd $repo --label payments 500s --focus" \
  "$(grep '^herdr workspace create' "$tmp/calls")"
check "incident starts Claude in the new workspace" \
  "herdr pane run w2:p1 claude" \
  "$(grep '^herdr pane run' "$tmp/calls")"
check "incident is logged after the park" \
  "feed add herdr incident: payments 500s  --meta {\"event\":\"incident\",\"workspace\":\"payments 500s\",\"cwd\":\"$repo\",\"branch\":\"PROJ-42-login-fix\"}" \
  "$(grep '^feed add herdr incident' "$tmp/calls")"

run 'payments 500s\n\n' incident >/dev/null
check "incident with no note still parks, naming the incident" \
  "herdr workspace report-metadata w1 --source herdr-park --token parked=interrupted by incident: payments 500s" \
  "$(grep '^herdr workspace report-metadata' "$tmp/calls")"

run '\n' incident >/dev/null
check "incident with no name cancels" "" "$(cat "$tmp/calls" | grep -v '^herdr \(pane current\|workspace get\)' || true)"

echo
if (( failures )); then echo "$failures failed"; exit 1; fi
echo "all passed"
