# Git protocol

`$BASE` is the branch the plan lands on, recorded in the Execution log. It is often
`main`, but a resumed plan usually sits on a topic branch.

## Rules for both commit modes

- Linear history on `$BASE`. Every commit is green.
- Land cards in dependency order. A commit's staged files must not reference
  uncommitted work, because hooks that stash unstaged changes test the staged tree
  alone.
- Never put 2 cards' files in 1 commit.
- Commit a card whole: code, specs, and new files together. A split leaves the card's
  untracked files on disk under a hook that stashes, and the first commit goes red.
- Never write a tracked file in the main checkout while a hook runs. The hook rolls it
  back. Write to scratch and copy between landings. Never cut a worktree during a hook
  either.
- If a hook fails, the files stay staged. Run `git reset` before the next `git add`.
- Rebase and fast-forward merge run no hooks. Run the full suite after either.
- Message hooks run after the hooks that run the suite. Run the repo's message lint on
  the message file and gate on its exit before `git commit`, every time. A message
  failure after a green suite costs a full rerun, and `--no-verify` is denied in auto
  mode. 9 landings have paid this for a subject over the limit.
- Keep every hook's output in a log named by card and attempt. A passing hook prints
  nothing, so the suite's example count comes from the log or the runner's own log.
  The hook output holds 2 passes; read the first, not `tail`.
- Record `git status --porcelain` before and after each commit attempt. A hook that
  reports modified files does not name them. Snapshot submodule state too.
- Retry a landing only when `$BASE` moved under it. Never on a red hook.
- Commit messages follow `~/.claude/reference/coding.md`. That covers commits that
  update the plan document too.

## The landing script

Landing runs from 1 script file, under `bash` with `set -euo pipefail`, that reads the
card's paths from a file line by line. It, in order:

1. Checks each path is a file, and that the list is not empty.
2. Lints the message file and stops on a failure.
3. Waits for a quiet box under the gate (SKILL.md, Quiet box), then copies or patches
   the card's files into the main checkout.
4. Runs the commit's lint checks on the staged files, whole-file, so a pre-existing
   offense in a touched file surfaces before the suite runs. Treat empty lint output as
   a failure when the tool prints on success.
5. Greps the staged files for conflict markers.
6. Diffs the staged list against the card's Files plus wiring. The hand-back is
   excluded by exact name (`.handback-T<id>.md`), never by substring.
7. Commits, then appends the log line itself.

On any failure it restores every staged path to HEAD 1 path at a time (a whole-list
`git checkout --` aborts when 1 path is untracked), removes new files, runs
`git reset`, and exits. A red hook must leave the main checkout clean, or the next
`git apply -3` fails against the leftovers.

## Worktrees

Never use `isolation: worktree`. It forks from `origin/main`, so the agent opens a tree
without the cards that have already landed, and nothing tells it so.

Name worktrees and branches by plan slug and card: `tmp/worktrees/<slug>-T<id>` and
`card/<slug>-T<id>`. Card ids repeat across plans, and a stale `card/T<id>` from an
earlier run refuses the cut.

Cut each worktree by hand, from HEAD, just before the spawn:

```bash
git check-ignore -v tmp/                                      # must print a rule
git worktree add tmp/worktrees/<slug>-T<id> -b card/<slug>-T<id> HEAD
git -C tmp/worktrees/<slug>-T<id> log -1 --format=%h          # must equal HEAD
```

Then copy in every gitignored build output from the Execution log's list (compiled
extensions, release binaries, the runtime log a parallel runner groups by), with
`mkdir -p` on the target directory first. Never point a worktree that rebuilds at the
main checkout's build cache: its build overwrites main's artifacts under a hook. Point
only lookups at main, and copy binaries.

- Put worktrees in a directory the repo already ignores. If `tmp/` is not ignored, use
  one that is.
- HEAD moves each time a card lands. Cut from the current HEAD, never from a ref
  resolved earlier.
- Spawn the agent without `isolation`. The first line of its brief names the absolute
  worktree path as the only directory it may touch.
- Worktrees share the stash stack and, by default, `TMPDIR`. Agents never stash. Give
  each worktree its own `TMPDIR` if tests write there.

If an agent reports that a file the plan cites is missing, or that line numbers are
wrong throughout, suspect a stale base before plan drift. To correct it:

```bash
git -C <worktree> status --porcelain        # must be empty, else stop
git -C <worktree> merge --ff-only <head>
```

Then tell the agent with SendMessage that its base was wrong and it must re-read.

## Stacking on an unlanded parent

A child card may start on a parent that is approved or in review. Snapshot the
parent's worktree as a hookless commit and cut the child from it, so the child's own
diff stays clean:

```bash
P=tmp/worktrees/<slug>-T<parent>
tree=$(git -C "$P" add -A && git -C "$P" write-tree); git -C "$P" reset -q
base=$(git commit-tree "$tree" -p HEAD -m "stack on T<parent>")
git worktree add tmp/worktrees/<slug>-T<child> -b card/<slug>-T<child> "$base"
echo "$base" > tmp/worktrees/<slug>-T<child>/.stack-base
```

- Never snapshot while the parent's reviewer runs: the copy carries its mutants.
- The parent lands first. The child's patch is `git diff <stack base> -- <files>`,
  applied with `git apply -3`. If the parent's review changed its files, the 3-way
  apply shows where the child must refold.
- Never copy whole files from a stacked worktree into main. Patch from the stack base.

## orchestrator-commits (default)

Agents never write git. They hand back changed files and wiring diffs. The main
session applies the wiring to the shared files in the card's worktree before review.
After approval it copies the card's files into the main checkout, applies the same
wiring there, runs the full suite, and commits on `$BASE`. If a shared file changed on
`$BASE` since the review, check the wiring still applies as reviewed.

Before copying a file, check whether it changed on `$BASE` since the worktree was cut.
If it did, a whole-file copy reverts that change. Apply the card's diff as a patch
instead, from the card's own cut sha:

```bash
git diff <cut sha> card/<slug>-T<id> -- <file> | git apply -3
```

## branch-queue

Agents commit on their own branch. The main session merges 1 branch at a time.

```bash
# the agent's last act
git rebase "$BASE" && <full suite>

# the main session
if git merge-base --is-ancestor "$BASE" card/<slug>-T<id>; then
  <full suite in the card's worktree>
  git merge --ff-only card/<slug>-T<id>
else
  # $BASE moved. SendMessage the agent: rebase and verify again
fi
```

Merge branches that touch the same shared file 1 after another. Integration fixes land
with the later branch.

## Cleanup

Remove each card's worktree and branch when the card has landed and no agent will be
continued in it, and no hook is running.

```bash
cp tmp/worktrees/<slug>-T<id>/.handback-*.md <scratch dir>/   # a later card may need it
git worktree remove --force tmp/worktrees/<slug>-T<id>
git branch -d card/<slug>-T<id>
git worktree prune
git worktree list                                             # the worktree is gone
```

- Use `-d`, never `-D`. If `-d` refuses, something did not land.
  Find out what.
- Probe scripts are untracked and die with the worktree. Hand-backs are copied first.
- Under disk pressure, delete build output (`target/`, `node_modules/`) from worktrees
  with no running agent.

A landing killed mid-hook can leave the hook's stash of the user's unstaged edits
unrestored under `~/.cache/pre-commit/patch*`. After any killed landing, diff the
working tree against the run's start status and restore the patch at once.

At close-out, `git worktree list` and `git branch --list` must match the start of the
run.
