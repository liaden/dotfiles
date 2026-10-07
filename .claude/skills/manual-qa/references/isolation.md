# Isolation

The round must not touch the operator's real state, and must prove it.

## Redirect state

Build a sandbox directory per round, named by a tag, and reuse it on the same tag. It is
evidence. Every process under test runs with:

```bash
export XDG_CONFIG_HOME="$QA/xdg/config"
export XDG_STATE_HOME="$QA/xdg/state"
export XDG_CACHE_HOME="$QA/xdg/cache"
export XDG_RUNTIME_DIR="$QA/xdg/runtime"   # chmod 700
export TMPDIR="$QA/tmp"
```

Add the app's own home or state variable if it has one. A redirected config home hides
the operator's git identity, so seed a throwaway one in the sandbox. Never copy the real
one.

Apps that keep state elsewhere get the equivalent: a throwaway database name, a fresh
emulator or a dedicated test device, a compose project name per round.

## Prove it before act 1

For every process under test:

```bash
tr '\0' '\n' < /proc/<pid>/environ | command grep -cE '^(XDG_[A-Z]+_(HOME|DIR)|TMPDIR)='
```

The count must equal the number of variables you set. Write this once as a helper in
the sandbox and run the helper. Re-typed greps have matched 1 variable and passed 4
wrong processes. Under an agent shell `grep` may be a function, so use `command grep`.
An empty result means re-check, never abort.

## Verify the negative at close-out

Each negative needs a positive control beside it. A mistyped timestamp or path returns
0 unconditionally.

```bash
find ~/.local/state/<app> -newermt '<round start>'          # must print nothing
find ~/.local/state/<app> -newermt '<a year ago>' | wc -l   # must be > 0
git -C "$REPO" status --porcelain      # must match the baseline from before act 1
ls -d "$REPO"/.<app> 2>/dev/null       # must print nothing
```

The last line catches state written into the checkout. It is usually gitignored, so
`git status` cannot see it.

Run the git check under the same environment as the baseline. A redirected
`XDG_CONFIG_HOME` hides the global gitignore, so every globally ignored file reports as
untracked.

## Processes

Kill by pid what the round started, then check the ports it used:

```bash
ss -ltnp | command grep -E ':(<port>|<port>)\b'
```

A terminal multiplexer's kill-server reaches neither a daemonised server nor a
listener started from a shell that did not own it.
